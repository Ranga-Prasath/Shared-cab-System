import { describe, expect, it } from 'vitest';
import { decodePolyline, encodePolyline, haversineDistanceMeters } from './utils';

describe('Polyline utilities', () => {
  it('encodes and decodes points consistently', () => {
    const points: [number, number][] = [
      [77.5946, 12.9716],
      [77.3, 12.8],
      [76.6558, 12.3052]
    ];

    const encoded = encodePolyline(points);
    const decoded = decodePolyline(encoded);

    expect(decoded).toHaveLength(3);
    expect(decoded[0][0]).toBeCloseTo(points[0][0], 4);
    expect(decoded[2][1]).toBeCloseTo(points[2][1], 4);
  });

  it('calculates haversine distance in meters', () => {
    const d = haversineDistanceMeters([77.5946, 12.9716], [76.6558, 12.3052]);
    expect(d).toBeGreaterThan(100000);
  });
});