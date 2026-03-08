import { describe, expect, it, vi } from 'vitest';
import { MatchingService } from '../src/modules/matching/matching.service.js';

describe('MatchingService', () => {
  it('returns candidates only when detour is below 20% threshold', async () => {
    const db = {
      query: vi
        .fn()
        .mockResolvedValueOnce({
          rows: [
            {
              id: 'ride-source',
              status: 'REQUESTED',
              pickup_lon: 77.59,
              pickup_lat: 12.97,
              dropoff_lon: 76.65,
              dropoff_lat: 12.3
            }
          ]
        })
        .mockResolvedValueOnce({
          rows: [
            {
              id: 'ride-driver-1',
              pickup_lon: 77.5,
              pickup_lat: 12.9,
              dropoff_lon: 76.7,
              dropoff_lat: 12.4
            },
            {
              id: 'ride-driver-2',
              pickup_lon: 77.45,
              pickup_lat: 12.85,
              dropoff_lon: 76.6,
              dropoff_lat: 12.35
            }
          ]
        })
    };

    const routingService = {
      directions: vi
        .fn()
        .mockResolvedValueOnce({ distanceMeters: 10000, durationSeconds: 1200, polyline: 'a' })
        .mockResolvedValueOnce({ distanceMeters: 10000, durationSeconds: 1300, polyline: 'b' }),
      directionsWithWaypoints: vi
        .fn()
        .mockResolvedValueOnce({ distanceMeters: 11500, durationSeconds: 1500, polyline: 'a2' })
        .mockResolvedValueOnce({ distanceMeters: 14000, durationSeconds: 1900, polyline: 'b2' })
    };

    const service = new MatchingService(db as never, routingService as never);
    const matches = await service.matchRideById('ride-source', 0.2);

    expect(matches).toEqual([
      {
        rideId: 'ride-source',
        matchedRideId: 'ride-driver-1',
        overlapPercentage: 0.25,
        detourMeters: 1500,
        status: 'proposed'
      }
    ]);
  });
});