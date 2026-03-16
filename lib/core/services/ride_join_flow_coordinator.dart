import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/services/ride_service.dart';
import 'package:shared_cab/core/session/ride_session_controller.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/providers/app_providers.dart';

abstract class RideJoinFlowGateway {
  const RideJoinFlowGateway();

  Future<void> requestToJoin({
    required String rideId,
    required String requesterId,
    required String requesterName,
    required String requesterGender,
    required String requesterPickup,
    required String requesterDropoff,
    required double? requesterPickupLat,
    required double? requesterPickupLng,
  });

  Future<bool> cancelPendingRequest(
    String rideId, {
    required String requesterId,
  });

  Future<bool> cancelJoinedRide(String rideId);

  Stream<RideRequest?> rideStream(String rideId);
}

class LiveRideJoinFlowGateway extends RideJoinFlowGateway {
  const LiveRideJoinFlowGateway();

  @override
  Future<void> requestToJoin({
    required String rideId,
    required String requesterId,
    required String requesterName,
    required String requesterGender,
    required String requesterPickup,
    required String requesterDropoff,
    required double? requesterPickupLat,
    required double? requesterPickupLng,
  }) {
    return RideService.requestToJoin(
      rideId: rideId,
      requesterId: requesterId,
      requesterName: requesterName,
      requesterGender: requesterGender,
      requesterPickup: requesterPickup,
      requesterDropoff: requesterDropoff,
      requesterPickupLat: requesterPickupLat,
      requesterPickupLng: requesterPickupLng,
    );
  }

  @override
  Future<bool> cancelPendingRequest(
    String rideId, {
    required String requesterId,
  }) {
    return RideService.cancelPendingRequest(rideId, requesterId: requesterId);
  }

  @override
  Future<bool> cancelJoinedRide(String rideId) {
    return RideService.cancelJoinedRide(rideId);
  }

  @override
  Stream<RideRequest?> rideStream(String rideId) {
    return RideService.rideStream(rideId);
  }
}

class RideJoinFlowCoordinator {
  const RideJoinFlowCoordinator({
    this.gateway = const LiveRideJoinFlowGateway(),
  });

  final RideJoinFlowGateway gateway;

  Future<void> start({
    required BuildContext context,
    required WidgetRef ref,
    required RideRequest hostRide,
  }) async {
    final currentUser = ref.read(effectiveCurrentUserProvider);
    final myRide = ref.read(currentRideRequestProvider);

    await gateway.requestToJoin(
      rideId: hostRide.id,
      requesterId: currentUser.id,
      requesterName: currentUser.name,
      requesterGender: currentUser.gender,
      requesterPickup: myRide?.pickup.address ?? '',
      requesterDropoff: myRide?.dropoff.address ?? '',
      requesterPickupLat: myRide?.pickup.latitude,
      requesterPickupLng: myRide?.pickup.longitude,
    );

    if (!context.mounted) return;

    await _showPendingDecisionDialog(
      context: context,
      ref: ref,
      hostRide: hostRide,
      requesterId: currentUser.id,
    );
  }

  Future<void> _showPendingDecisionDialog({
    required BuildContext context,
    required WidgetRef ref,
    required RideRequest hostRide,
    required String requesterId,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    var dialogOpen = false;

    late final StreamSubscription<RideRequest?> subscription;
    subscription = gateway.rideStream(hostRide.id).listen((updatedRide) {
      if (!context.mounted || updatedRide == null) {
        return;
      }

      final request = updatedRide.joinRequestFor(requesterId);
      final amJoined = updatedRide.coRiderIds.contains(requesterId);

      if (amJoined &&
          updatedRide.readyToProceed &&
          updatedRide.status == RideStatus.matched) {
        subscription.cancel();
        if (dialogOpen && Navigator.of(context).canPop()) {
          dialogOpen = false;
          Navigator.of(context).pop();
        }
        _startSharedTrip(router, ref, updatedRide);
        return;
      }

      if (amJoined &&
          updatedRide.waitForAnotherRider &&
          !updatedRide.readyToProceed) {
        subscription.cancel();
        if (dialogOpen && Navigator.of(context).canPop()) {
          dialogOpen = false;
          Navigator.of(context).pop();
        }
        unawaited(
          _showWaitingForAnotherRiderDialog(
            context: context,
            ref: ref,
            rideId: hostRide.id,
            hostName: hostRide.userName,
            requesterId: requesterId,
          ),
        );
        return;
      }

      if (request?.status == RideJoinRequestStatus.declined) {
        subscription.cancel();
        if (dialogOpen && Navigator.of(context).canPop()) {
          dialogOpen = false;
          Navigator.of(context).pop();
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              request?.statusReason?.isNotEmpty == true
                  ? request!.statusReason!
                  : '${hostRide.userName} declined your request.',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    dialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12),
              Text('Waiting for approval'),
            ],
          ),
          content: Text(
            '${hostRide.userName.isNotEmpty ? hostRide.userName : "The rider"} '
            'is reviewing your request.\n\n'
            'You will be notified when they accept or decline.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final cancelled = await gateway.cancelPendingRequest(
                  hostRide.id,
                  requesterId: requesterId,
                );
                if (!dialogContext.mounted) return;
                if (!cancelled) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Request was already handled.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  return;
                }
                dialogOpen = false;
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel Request'),
            ),
          ],
        ),
      ),
    ).whenComplete(() async {
      dialogOpen = false;
      await subscription.cancel();
    });
  }

  Future<void> _showWaitingForAnotherRiderDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String rideId,
    required String hostName,
    required String requesterId,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    var dialogOpen = false;

    late final StreamSubscription<RideRequest?> subscription;
    subscription = gateway.rideStream(rideId).listen((updatedRide) {
      if (!context.mounted || updatedRide == null) {
        return;
      }

      final amJoined = updatedRide.coRiderIds.contains(requesterId);
      if (!amJoined) {
        subscription.cancel();
        if (dialogOpen && Navigator.of(context).canPop()) {
          dialogOpen = false;
          Navigator.of(context).pop();
        }
        messenger.showSnackBar(
          const SnackBar(
            content: Text('You left the shared ride.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      if (updatedRide.readyToProceed &&
          updatedRide.status == RideStatus.matched) {
        subscription.cancel();
        if (dialogOpen && Navigator.of(context).canPop()) {
          dialogOpen = false;
          Navigator.of(context).pop();
        }
        _startSharedTrip(router, ref, updatedRide);
      }
    });

    dialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Waiting for another rider'),
          content: Text(
            '${hostName.isNotEmpty ? hostName : "Host"} accepted you and is waiting for one more rider.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final cancelled = await gateway.cancelJoinedRide(rideId);
                if (!dialogContext.mounted) return;
                if (!cancelled) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Ride already moved forward.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  return;
                }
                dialogOpen = false;
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel Ride'),
            ),
          ],
        ),
      ),
    ).whenComplete(() async {
      dialogOpen = false;
      await subscription.cancel();
    });
  }

  void _startSharedTrip(GoRouter router, WidgetRef ref, RideRequest ride) {
    final trip = RideSessionController.startSharedTrip(
      RideSessionStore.widget(ref),
      ride: ride,
      startTime: DateTime.now(),
    );
    router.go('/trip/${trip.id}');
  }
}
