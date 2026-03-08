import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { getEnv } from '../../config/env.validation.js';

interface OsrmRoute {
  distance: number;
  duration: number;
  geometry: string;
}

interface OsrmResponse {
  code: string;
  routes: OsrmRoute[];
}

@Injectable()
export class OsrmClient {
  private readonly baseUrl = getEnv().OSRM_BASE_URL;

  async route(start: [number, number], end: [number, number]): Promise<OsrmRoute> {
    return this.routeWithWaypoints([start, end]);
  }

  async routeWithWaypoints(points: [number, number][]): Promise<OsrmRoute> {
    if (points.length < 2) {
      throw new ServiceUnavailableException('Route computation needs at least two points.');
    }

    const coordinatePath = points.map(([lon, lat]) => `${lon},${lat}`).join(';');
    const url = `${this.baseUrl}/route/v1/driving/${coordinatePath}?overview=full&geometries=polyline`;

    let response: Response;
    try {
      response = await fetch(url, { signal: AbortSignal.timeout(10_000) });
    } catch {
      throw new ServiceUnavailableException('Routing request timed out. Please retry shortly.');
    }

    if (response.status === 429) {
      throw new ServiceUnavailableException('Routing service is rate-limited right now. Please retry in a moment.');
    }

    if (!response.ok) {
      throw new ServiceUnavailableException('Routing service is temporarily unavailable.');
    }

    const data = (await response.json()) as OsrmResponse;
    const route = data.routes?.[0];

    if (!route || data.code !== 'Ok') {
      throw new ServiceUnavailableException('Could not compute a road-snapped route for this trip.');
    }

    return route;
  }
}