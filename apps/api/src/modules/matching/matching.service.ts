import { Injectable } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { DatabaseService } from '../../common/services/database.service.js';
import { RoutingService } from '../routing/routing.service.js';
import { HighwayOverlapStrategy } from './strategies/highway-overlap.strategy.js';

export interface MatchCandidate {
  rideId: string;
  matchedRideId: string;
  overlapPercentage: number;
  detourMeters: number;
  status: 'proposed' | 'accepted' | 'rejected';
}

interface CandidateRow {
  id: string;
  pickup_lon: number;
  pickup_lat: number;
  dropoff_lon: number;
  dropoff_lat: number;
}

interface RideRouteRow extends CandidateRow {
  status: 'REQUESTED' | 'MATCHED' | 'EN_ROUTE' | 'COMPLETED' | 'CANCELLED';
}

interface DetourResult {
  detourMeters: number;
  originalDistanceMeters: number;
}

@Injectable()
export class MatchingService {
  private readonly strategy = new HighwayOverlapStrategy();

  constructor(
    private readonly db: DatabaseService,
    private readonly routingService: RoutingService
  ) { }

  /**
   * Finds driver rides suitable for a fresh passenger route.
   */
  async findAvailableForRoute(
    pickup: [number, number],
    dropoff: [number, number],
    minOverlap = this.strategy.minOverlap
  ): Promise<MatchCandidate[]> {
    const candidates = await this.findDriverCandidates();
    return this.evaluateCandidates(randomUUID(), pickup, dropoff, candidates, minOverlap);
  }

  /**
   * Finds driver rides suitable for a specific ride by id.
   */
  async matchRideById(rideId: string, minOverlap = this.strategy.minOverlap): Promise<MatchCandidate[]> {
    const rideResult = await this.db.query<RideRouteRow>(
      `select id,
              status,
              ST_X(pickup_location::geometry) as pickup_lon,
              ST_Y(pickup_location::geometry) as pickup_lat,
              ST_X(dropoff_location::geometry) as dropoff_lon,
              ST_Y(dropoff_location::geometry) as dropoff_lat
       from public.rides
       where id = $1
       limit 1`,
      [rideId]
    );

    const requestedRide = rideResult.rows[0];
    if (!requestedRide) {
      return [];
    }

    const candidates = await this.findDriverCandidates(rideId);
    return this.evaluateCandidates(
      rideId,
      [requestedRide.pickup_lon, requestedRide.pickup_lat],
      [requestedRide.dropoff_lon, requestedRide.dropoff_lat],
      candidates,
      minOverlap
    );
  }

  /**
   * Computes additional distance for detouring driver C->D via passenger A->B.
   */
  async calculateDetour(
    passengerPickup: [number, number],
    passengerDropoff: [number, number],
    driverPickup: [number, number],
    driverDropoff: [number, number]
  ): Promise<DetourResult> {
    const original = await this.routingService.directions(driverPickup, driverDropoff);
    const detoured = await this.routingService.directionsWithWaypoints([
      driverPickup,
      passengerPickup,
      passengerDropoff,
      driverDropoff
    ]);

    return {
      detourMeters: Math.max(0, detoured.distanceMeters - original.distanceMeters),
      originalDistanceMeters: original.distanceMeters
    };
  }

  private async findDriverCandidates(excludeRideId?: string): Promise<CandidateRow[]> {
    const values = excludeRideId ? [excludeRideId] : [];
    const whereClause = excludeRideId ? 'and r.id <> $1' : '';

    const result = await this.db.query<CandidateRow>(
      `select r.id,
              coalesce(ST_X(dl.location::geometry), ST_X(r.pickup_location::geometry)) as pickup_lon,
              coalesce(ST_Y(dl.location::geometry), ST_Y(r.pickup_location::geometry)) as pickup_lat,
              ST_X(r.dropoff_location::geometry) as dropoff_lon,
              ST_Y(r.dropoff_location::geometry) as dropoff_lat
       from public.rides r
       left join public.driver_locations dl on r.driver_id = dl.driver_id
       where r.driver_id is not null
         and r.status in ('MATCHED', 'EN_ROUTE')
         ${whereClause}`,
      values
    );

    return result.rows;
  }

  private async evaluateCandidates(
    rideId: string,
    pickup: [number, number],
    dropoff: [number, number],
    candidates: CandidateRow[],
    minOverlap: number
  ): Promise<MatchCandidate[]> {
    const evaluations = await Promise.all(
      candidates.map(async (candidate): Promise<MatchCandidate | null> => {
        try {
          const detour = await this.calculateDetour(
            pickup,
            dropoff,
            [candidate.pickup_lon, candidate.pickup_lat],
            [candidate.dropoff_lon, candidate.dropoff_lat]
          );

          if (detour.originalDistanceMeters <= 0) {
            return null;
          }

          const maxDetour = detour.originalDistanceMeters * 0.2;
          if (detour.detourMeters > maxDetour) {
            return null;
          }

          const overlapScore = Math.max(0, 1 - detour.detourMeters / maxDetour);
          if (overlapScore < minOverlap) {
            return null;
          }

          return {
            rideId,
            matchedRideId: candidate.id,
            overlapPercentage: Number(overlapScore.toFixed(3)),
            detourMeters: Math.round(detour.detourMeters),
            status: 'proposed'
          };
        } catch {
          return null;
        }
      })
    );

    return evaluations.filter((item): item is MatchCandidate => item !== null);
  }
}