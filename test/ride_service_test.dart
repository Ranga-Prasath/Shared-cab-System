// SPEC: Ride Service Mutation Guards
// WHAT IT DOES:
//   Verifies that the ride service only permits host and requester mutations
//   for the correct actor and only auto-cancels pending rides during publish.
//
// DATA OBJECTS:
//   RideRequest - the canonical ride document used for host/requester checks
//
// OPERATIONS:
//   ensureHostMutationAllowed -> allows only the ride owner
//   ensureRequesterMutationAllowed -> allows only the requester
//   ridesToAutoCancelOnPublish -> returns pending rides except the one being published
//
// EDGE CASES HANDLED:
//   • unauthenticated mutations fail fast
//   • a non-host cannot use host-only mutations
//   • matched and active rides are not auto-cancelled during publish
//
// ASSUMPTIONS MADE:
//   • client-side validation is a necessary guardrail even when Firestore rules exist
//
// DONE WHEN:
//   host/requester identity mismatches throw and publish auto-cancel only targets
//   the intended pending rides.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_cab/core/services/ride_service.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';

RideRequest _buildRide({
  required String id,
  required RideStatus status,
  String userId = 'host-1',
}) {
  return RideRequest(
    id: id,
    userId: userId,
    userName: 'Host',
    userGender: 'female',
    pickup: const LocationPoint(
      latitude: 13.0000,
      longitude: 80.0000,
      address: 'Pickup',
    ),
    dropoff: const LocationPoint(
      latitude: 13.1000,
      longitude: 80.1000,
      address: 'Dropoff',
    ),
    departureTime: DateTime.fromMillisecondsSinceEpoch(1000),
    status: status,
    createdAt: DateTime.fromMillisecondsSinceEpoch(500),
  );
}

void main() {
  group('RideService mutation guards', () {
    test('allows the host to perform host-only ride mutations', () {
      expect(
        () => RideService.ensureHostMutationAllowed(
          ride: _buildRide(id: 'ride-1', status: RideStatus.pending),
          actingUserId: 'host-1',
        ),
        returnsNormally,
      );
    });

    test('rejects host-only mutations from a different actor', () {
      expect(
        () => RideService.ensureHostMutationAllowed(
          ride: _buildRide(id: 'ride-1', status: RideStatus.pending),
          actingUserId: 'rider-2',
        ),
        throwsStateError,
      );
    });

    test('rejects requester mutations for a different actor', () {
      expect(
        () => RideService.ensureRequesterMutationAllowed(
          requesterId: 'rider-2',
          actingUserId: 'rider-3',
        ),
        throwsStateError,
      );
    });

    test('auto-cancel during publish only targets previous pending rides', () {
      final ridesToCancel = RideService.ridesToAutoCancelOnPublish(
        existingRides: [
          _buildRide(id: 'ride-pending', status: RideStatus.pending),
          _buildRide(id: 'ride-requested', status: RideStatus.requested),
          _buildRide(id: 'ride-matched', status: RideStatus.matched),
          _buildRide(id: 'ride-active', status: RideStatus.active),
          _buildRide(id: 'ride-publishing', status: RideStatus.pending),
        ],
        publishingRideId: 'ride-publishing',
      );

      expect(
        ridesToCancel.map((ride) => ride.id).toList(),
        const ['ride-pending'],
      );
    });
  });
}
