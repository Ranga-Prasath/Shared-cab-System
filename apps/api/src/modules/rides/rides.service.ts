import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { DatabaseService } from '../../common/services/database.service.js';
import { MatchingService, type MatchCandidate } from '../matching/matching.service.js';
import { RoutingService } from '../routing/routing.service.js';
import { CreateRideDto } from './dto/create-ride.dto.js';
import { UpdateRideDto } from './dto/update-ride.dto.js';
import { RidesGateway } from './rides.gateway.js';

interface RideRow {
  id: string;
  passenger_id: string;
  driver_id: string | null;
  status: 'REQUESTED' | 'MATCHED' | 'EN_ROUTE' | 'COMPLETED' | 'CANCELLED';
  pickup_address: string;
  dropoff_address: string;
  route_polyline: string;
  estimated_fare: string;
  actual_fare: string | null;
  scheduled_at: string | null;
  started_at: string | null;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
  pickup_lon: number;
  pickup_lat: number;
  dropoff_lon: number;
  dropoff_lat: number;
}

interface RoleRow {
  role: 'passenger' | 'driver' | 'admin';
}

@Injectable()
export class RidesService {
  private readonly transitions: Record<string, string[]> = {
    REQUESTED: ['MATCHED', 'CANCELLED'],
    MATCHED: ['EN_ROUTE', 'CANCELLED'],
    EN_ROUTE: ['COMPLETED', 'CANCELLED'],
    COMPLETED: [],
    CANCELLED: []
  };

  constructor(
    private readonly db: DatabaseService,
    private readonly routingService: RoutingService,
    private readonly matchingService: MatchingService,
    private readonly gateway: RidesGateway
  ) { }

  /**
   * Creates a ride and computes its initial route and fare estimate.
   */
  async createRide(userId: string, dto: CreateRideDto): Promise<Record<string, unknown>> {
    const route = await this.routingService.directions(dto.pickupLocation, dto.dropoffLocation);
    const estimatedFare = Number((50 + route.distanceMeters * 0.015).toFixed(2));

    const result = await this.db.query<RideRow>(
      `insert into public.rides (
        passenger_id, status, pickup_location, dropoff_location, pickup_address, dropoff_address,
        route_polyline, estimated_fare, scheduled_at
      )
      values (
        $1, 'REQUESTED', ST_SetSRID(ST_MakePoint($2, $3), 4326)::geography,
        ST_SetSRID(ST_MakePoint($4, $5), 4326)::geography, $6, $7, $8, $9, $10
      )
      returning id, passenger_id, driver_id, status, pickup_address, dropoff_address, route_polyline,
        estimated_fare::text, actual_fare::text, scheduled_at::text, started_at::text, completed_at::text,
        created_at::text, updated_at::text,
        ST_X(pickup_location::geometry) as pickup_lon, ST_Y(pickup_location::geometry) as pickup_lat,
        ST_X(dropoff_location::geometry) as dropoff_lon, ST_Y(dropoff_location::geometry) as dropoff_lat`,
      [
        userId,
        dto.pickupLocation[0],
        dto.pickupLocation[1],
        dto.dropoffLocation[0],
        dto.dropoffLocation[1],
        dto.pickupAddress,
        dto.dropoffAddress,
        route.polyline,
        estimatedFare,
        dto.scheduledAt
      ]
    );

    const ride = this.mapRide(result.rows[0]);
    this.gateway.emitRideCreated(ride);
    return ride;
  }

  /**
   * Lists rides where user is passenger or driver.
   */
  async listRides(userId: string): Promise<Record<string, unknown>[]> {
    const roleResult = await this.db.query<RoleRow>('select role from public.profiles where id = $1 limit 1', [userId]);
    const isAdmin = roleResult.rows[0]?.role === 'admin';

    const result = await this.db.query<RideRow>(
      `select id, passenger_id, driver_id, status, pickup_address, dropoff_address, route_polyline,
         estimated_fare::text, actual_fare::text, scheduled_at::text, started_at::text, completed_at::text,
         created_at::text, updated_at::text,
         ST_X(pickup_location::geometry) as pickup_lon, ST_Y(pickup_location::geometry) as pickup_lat,
         ST_X(dropoff_location::geometry) as dropoff_lon, ST_Y(dropoff_location::geometry) as dropoff_lat
       from public.rides
       where ($2::boolean = true) or passenger_id = $1 or driver_id = $1
       order by created_at desc`,
      [userId, isAdmin]
    );

    return result.rows.map((row) => this.mapRide(row));
  }

  /**
   * Retrieves a ride by id.
   */
  async getRideById(rideId: string): Promise<Record<string, unknown>> {
    const row = await this.getRideRow(rideId);
    return this.mapRide(row);
  }

  /**
   * Updates ride status according to allowed transitions.
   */
  async updateStatus(rideId: string, dto: UpdateRideDto): Promise<Record<string, unknown>> {
    const current = await this.getRideRow(rideId);
    const allowed = this.transitions[current.status] ?? [];

    if (!allowed.includes(dto.status)) {
      throw new BadRequestException('Invalid status transition.');
    }

    await this.db.query('update public.rides set status = $2, updated_at = now() where id = $1', [rideId, dto.status]);
    const updated = await this.getRideById(rideId);
    this.gateway.emitRideUpdated(updated);
    return updated;
  }

  /**
   * Accepts a ride as a driver.
   */
  async acceptRide(driverId: string, rideId: string): Promise<Record<string, unknown>> {
    const current = await this.getRideRow(rideId);
    if (current.status !== 'REQUESTED') {
      throw new BadRequestException('Ride is no longer available.');
    }

    await this.db.query(
      'update public.rides set status = $2, driver_id = $3, updated_at = now() where id = $1',
      [rideId, 'EN_ROUTE', driverId]
    );

    const updated = await this.getRideById(rideId);
    this.gateway.emitRideUpdated(updated);
    return updated;
  }

  /**
   * Triggers matching for a ride.
   */
  async triggerMatch(rideId: string, minOverlap = 0.4): Promise<MatchCandidate[]> {
    const matches = await this.matchingService.matchRideById(rideId, minOverlap);
    this.gateway.emitRideMatched({ rideId, matches });
    return matches;
  }

  /**
   * Returns latest route snapshot for one ride.
   */
  async getRideRoute(rideId: string): Promise<Record<string, unknown>> {
    const ride = await this.getRideRow(rideId);
    return {
      distanceMeters: null,
      durationSeconds: null,
      polyline: ride.route_polyline
    };
  }

  private async getRideRow(rideId: string): Promise<RideRow> {
    const result = await this.db.query<RideRow>(
      `select id, passenger_id, driver_id, status, pickup_address, dropoff_address, route_polyline,
         estimated_fare::text, actual_fare::text, scheduled_at::text, started_at::text, completed_at::text,
         created_at::text, updated_at::text,
         ST_X(pickup_location::geometry) as pickup_lon, ST_Y(pickup_location::geometry) as pickup_lat,
         ST_X(dropoff_location::geometry) as dropoff_lon, ST_Y(dropoff_location::geometry) as dropoff_lat
       from public.rides where id = $1 limit 1`,
      [rideId]
    );

    const row = result.rows[0];
    if (!row) {
      throw new NotFoundException('Ride not found.');
    }

    return row;
  }

  private mapRide(row: RideRow): Record<string, unknown> {
    return {
      id: row.id,
      passengerId: row.passenger_id,
      driverId: row.driver_id,
      status: row.status,
      pickupLocation: [row.pickup_lon, row.pickup_lat],
      dropoffLocation: [row.dropoff_lon, row.dropoff_lat],
      pickupAddress: row.pickup_address,
      dropoffAddress: row.dropoff_address,
      routePolyline: row.route_polyline,
      estimatedFare: Number(row.estimated_fare),
      actualFare: row.actual_fare ? Number(row.actual_fare) : null,
      scheduledAt: row.scheduled_at,
      startedAt: row.started_at,
      completedAt: row.completed_at,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }
}
