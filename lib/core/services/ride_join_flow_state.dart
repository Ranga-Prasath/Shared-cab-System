import 'package:shared_cab/models/ride_request_model.dart';

enum RideJoinFlowStateType {
  keepWaiting,
  startTrip,
  waitForAnotherRider,
  requestInactive,
  requestDeclined,
}

class RideJoinFlowState {
  const RideJoinFlowState({
    required this.type,
    this.message,
  });

  final RideJoinFlowStateType type;
  final String? message;
}

class RideJoinFlowStateResolver {
  const RideJoinFlowStateResolver._();

  static RideJoinFlowState resolve({
    required RideRequest updatedRide,
    required String requesterId,
    required String fallbackDeclineMessage,
  }) {
    final request = updatedRide.joinRequestFor(requesterId);
    final amJoined = updatedRide.coRiderIds.contains(requesterId);

    if (amJoined &&
        updatedRide.readyToProceed &&
        updatedRide.status == RideStatus.matched) {
      return const RideJoinFlowState(type: RideJoinFlowStateType.startTrip);
    }

    if (amJoined &&
        updatedRide.waitForAnotherRider &&
        !updatedRide.readyToProceed) {
      return const RideJoinFlowState(
        type: RideJoinFlowStateType.waitForAnotherRider,
      );
    }

    if (request == null && !amJoined) {
      return const RideJoinFlowState(
        type: RideJoinFlowStateType.requestInactive,
        message: 'Request is no longer active.',
      );
    }

    if (request?.status == RideJoinRequestStatus.declined ||
        request?.status == RideJoinRequestStatus.expired ||
        request?.status == RideJoinRequestStatus.cancelled) {
      return RideJoinFlowState(
        type: RideJoinFlowStateType.requestDeclined,
        message: request?.statusReason?.isNotEmpty == true
            ? request!.statusReason!
            : fallbackDeclineMessage,
      );
    }

    return const RideJoinFlowState(type: RideJoinFlowStateType.keepWaiting);
  }
}

