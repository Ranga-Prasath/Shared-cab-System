import 'package:shared_cab/core/constants/app_constants.dart';

class RideQueuePolicy {
  const RideQueuePolicy({
    this.requestExpiryMinutes = AppConstants.joinRequestExpiryMinutes,
    this.maxPendingRequests = AppConstants.maxPendingJoinRequestsPerRide,
    this.flowVersion = AppConstants.requestFlowVersion,
  });

  final int requestExpiryMinutes;
  final int maxPendingRequests;
  final int flowVersion;
}

