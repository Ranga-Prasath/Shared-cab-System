import { Injectable } from '@nestjs/common';
import { OsrmClient } from './osrm.client.js';

export interface DirectionsResult {
  distanceMeters: number;
  durationSeconds: number;
  polyline: string;
}

@Injectable()
export class RoutingService {
  constructor(private readonly osrmClient: OsrmClient) {}

  /**
   * Returns road-snapped route data from OSRM for a two-point trip.
   */
  async directions(start: [number, number], end: [number, number]): Promise<DirectionsResult> {
    const route = await this.osrmClient.route(start, end);
    return {
      distanceMeters: route.distance,
      durationSeconds: route.duration,
      polyline: route.geometry
    };
  }

  /**
   * Returns road-snapped route data for a multi-stop path.
   */
  async directionsWithWaypoints(points: [number, number][]): Promise<DirectionsResult> {
    const route = await this.osrmClient.routeWithWaypoints(points);
    return {
      distanceMeters: route.distance,
      durationSeconds: route.duration,
      polyline: route.geometry
    };
  }
}