import 'package:flutter_test/flutter_test.dart';
import 'package:shared_cab/features/trip/utils/trip_map_math.dart';

void main() {
  group('TripMapMath route sync helpers', () {
    test('converts segment sync data into a route scalar', () {
      final scalar = TripMapMath.routeScalarFromSegment(
        segmentIndex: 4,
        segmentProgress: 0.25,
        pointCount: 12,
      );

      expect(scalar, 4.25);
    });

    test('builds a route frame from scalar progress', () {
      final frame = TripMapMath.routeFrameFromScalar(
        routeScalar: 4.25,
        pointCount: 12,
      );

      expect(frame.segmentIndex, 4);
      expect(frame.segmentProgress, closeTo(0.25, 0.0001));
      expect(frame.overallProgress, closeTo(4.25 / 11, 0.0001));
    });

    test('clamps the remote sync interpolation duration', () {
      final fast = TripMapMath.recommendedRemoteSyncDuration(
        previousUpdateAtMs: 1000,
        currentUpdateAtMs: 1100,
      );
      final slow = TripMapMath.recommendedRemoteSyncDuration(
        previousUpdateAtMs: 1000,
        currentUpdateAtMs: 4000,
      );

      expect(fast, const Duration(milliseconds: 400));
      expect(slow, const Duration(milliseconds: 1600));
    });

    test('falls back when sync timestamps are missing or invalid', () {
      final missing = TripMapMath.recommendedRemoteSyncDuration(
        previousUpdateAtMs: null,
        currentUpdateAtMs: 2000,
      );
      final invalid = TripMapMath.recommendedRemoteSyncDuration(
        previousUpdateAtMs: 3000,
        currentUpdateAtMs: 2000,
      );

      expect(missing, const Duration(milliseconds: 1450));
      expect(invalid, const Duration(milliseconds: 1450));
    });
  });
}
