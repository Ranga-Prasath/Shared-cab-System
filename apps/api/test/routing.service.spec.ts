import { describe, expect, it, vi } from 'vitest';
import { RoutingService } from '../src/modules/routing/routing.service.js';

describe('RoutingService', () => {
  it('maps OSRM route into API response format', async () => {
    const osrmClient = {
      route: vi.fn().mockResolvedValue({ distance: 10000, duration: 1200, geometry: 'abc123' })
    };

    const service = new RoutingService(osrmClient as never);
    const result = await service.directions([77.5946, 12.9716], [76.6558, 12.3052]);

    expect(result).toEqual({
      distanceMeters: 10000,
      durationSeconds: 1200,
      polyline: 'abc123'
    });
  });
});