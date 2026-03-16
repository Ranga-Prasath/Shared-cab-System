import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/matching/matching_pipeline.dart';
import 'package:shared_cab/core/services/ride_join_flow_coordinator.dart';
import 'package:shared_cab/core/services/ride_service.dart';
import 'package:shared_cab/core/session/ride_session_controller.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/core/utils/ride_formatters.dart';
import 'package:shared_cab/core/utils/ride_trip_utils.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/scored_match_model.dart';
import 'package:shared_cab/providers/app_providers.dart';

class MatchListScreen extends ConsumerStatefulWidget {
  const MatchListScreen({super.key, required this.rideId});

  final String rideId;

  @override
  ConsumerState<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends ConsumerState<MatchListScreen> {
  bool _initialLoading = true;
  StreamSubscription<RideRequest?>? _myRideSub;
  bool _alreadyNavigated = false;
  bool _hasIncomingRequest = false;
  RideJoinRequest? _incomingRequest;
  late final Stream<List<RideRequest>> _ridesStream;
  final RideJoinFlowCoordinator _joinFlowCoordinator =
      const RideJoinFlowCoordinator();

  @override
  void initState() {
    super.initState();
    _ridesStream = RideService.availableRidesStream();
    _initialLoading = false;

    _listenForMyRideUpdates();
  }

  void _listenForMyRideUpdates() {
    final myRide = ref.read(currentRideRequestProvider);
    if (myRide == null) return;

    _myRideSub = RideService.rideStream(myRide.id).listen((updatedRide) {
      if (updatedRide == null || _alreadyNavigated || !mounted) return;

      final incomingRequest = updatedRide.activeJoinRequest;
      if (incomingRequest != null) {
        setState(() {
          _hasIncomingRequest = true;
          _incomingRequest = incomingRequest;
        });
        return;
      }

      if (_hasIncomingRequest) {
        setState(() {
          _hasIncomingRequest = false;
          _incomingRequest = null;
        });
      }

      if (updatedRide.readyToProceed &&
          updatedRide.status == RideStatus.matched &&
          updatedRide.coRiderIds.isNotEmpty) {
        _alreadyNavigated = true;
        _navigateToTrip(updatedRide);
      }
    });
  }

  Future<void> _acceptRequest() async {
    final myRide = ref.read(currentRideRequestProvider);
    final incomingRequest = _incomingRequest;
    if (myRide == null || incomingRequest == null) return;

    final waitForAnotherRider = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('After accepting this rider'),
        content: const Text(
          'Choose whether to wait for one more rider or start the trip now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Wait for Another Rider'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Proceed Ride'),
          ),
        ],
      ),
    );

    if (waitForAnotherRider == null) return;

    final accepted = await RideService.acceptRequest(
      myRide.id,
      requesterId: incomingRequest.requesterId,
      waitForAnotherRider: waitForAnotherRider,
    );
    if (!mounted) return;

    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That request is no longer pending.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _hasIncomingRequest = false;
      _incomingRequest = null;
    });

    if (waitForAnotherRider) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accepted. Waiting for another rider request...'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  Future<void> _declineRequest() async {
    final myRide = ref.read(currentRideRequestProvider);
    final incomingRequest = _incomingRequest;
    if (myRide == null || incomingRequest == null) return;

    final declined = await RideService.declineRequest(
      myRide.id,
      requesterId: incomingRequest.requesterId,
    );
    if (!mounted) return;

    if (!declined) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That request is no longer pending.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _hasIncomingRequest = false;
      _incomingRequest = null;
    });
  }

  void _navigateToTrip(RideRequest ride) {
    final trip = RideSessionController.startSharedTrip(
      RideSessionStore.widget(ref),
      ride: ride,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ride shared! Heading to trip...'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
    context.goNamed('tripStatus', pathParameters: {'tripId': trip.id});
  }

  void _startDirectRide() {
    final currentRideRequest =
        ref.read(currentRideRequestProvider) ?? _buildDemoRideForQa();
    if (currentRideRequest == null) return;

    final directRide = RideTripUtils.prepareRideForPublication(
      currentRideRequest,
      directRide: true,
    );
    ref.read(currentRideRequestProvider.notifier).state = directRide;

    if (widget.rideId != 'test') {
      unawaited(
        RideService.updateRideStatus(
          directRide.id,
          RideStatus.active,
        ).catchError((_) {
          return;
        }),
      );
    }

    final trip = RideSessionController.startDirectTrip(
      RideSessionStore.widget(ref),
      ride: directRide,
      riderId: ref.read(effectiveCurrentUserProvider).id,
    );
    if (kDebugMode && widget.rideId == 'test') {
      context.go('/trip/${trip.id}?qa=1');
      return;
    }
    context.goNamed('tripStatus', pathParameters: {'tripId': trip.id});
  }

  RideRequest? _buildDemoRideForQa() {
    if (!kDebugMode || widget.rideId != 'test') return null;

    final currentUser = ref.read(effectiveCurrentUserProvider);
    return RideRequest(
      id: 'qa_demo_ride',
      userId: currentUser.id,
      userName: currentUser.name,
      userGender: currentUser.gender,
      pickup: const LocationPoint(
        latitude: 11.0150,
        longitude: 78.9550,
        address: 'Codex Test Origin',
      ),
      dropoff: const LocationPoint(
        latitude: 10.8450,
        longitude: 79.2050,
        address: 'Codex Test Terminal',
      ),
      departureTime: DateTime.now().add(const Duration(minutes: 1)),
      createdAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _myRideSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = ref.watch(effectiveNightModeProvider);
    final sameGenderOnly = ref.watch(sameGenderOnlyProvider);
    final currentUser = ref.watch(effectiveCurrentUserProvider);
    final myRide = ref.watch(currentRideRequestProvider);
    final ridePreferences = ref.watch(ridePreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Co-Riders Found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed('createRide'),
        ),
      ),
      body: Column(
        children: [
          if (_hasIncomingRequest && _incomingRequest != null)
            _IncomingRequestBanner(
              requesterName: _incomingRequest!.requesterName,
              requesterGender: _incomingRequest!.requesterGender,
              requesterPickup: _incomingRequest!.requesterPickup,
              requesterDropoff: _incomingRequest!.requesterDropoff,
              onAccept: _acceptRequest,
              onDecline: _declineRequest,
            ).animate().fadeIn().slideY(begin: -0.3, end: 0),
          Expanded(
            child: _initialLoading
                ? _buildSearching(context)
                : StreamBuilder<List<RideRequest>>(
                    stream: _ridesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildSearching(context);
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (myRide == null) {
                        return _buildResults(
                          context,
                          const <ScoredMatch>[],
                          isNight,
                        );
                      }

                      final matchingRides = MatchingPipeline.evaluate(
                        candidates: snapshot.data ?? const [],
                        context: MatchContext(
                          currentUserId: currentUser.id,
                          currentUserGender: currentUser.gender,
                          riderPreferences: ridePreferences,
                          isNightMode: isNight,
                          sameGenderOnly: sameGenderOnly,
                          now: DateTime.now(),
                          referenceRide: myRide,
                        ),
                      );

                      return _buildResults(context, matchingRides, isNight);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearching(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Finding co-riders on your route...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Searching riders heading your way',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildResults(
    BuildContext context,
    List<ScoredMatch> matches,
    bool isNight,
  ) {
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                    Icons.hourglass_top_rounded,
                    size: 64,
                    color: AppColors.primary,
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 1500.ms,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
              const SizedBox(height: 16),
              Text(
                'Waiting for co-riders...',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your ride is published and visible to others.\n'
                'This screen will update automatically when someone '
                'on the same route requests to join.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startDirectRide,
                  icon: const Icon(Icons.local_taxi_rounded),
                  label: const Text('Book Direct Ride Instead'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.goNamed('home'),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Go Home & Wait'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.savingsGradientStart,
                    AppColors.savingsGradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${matches.length} co-rider${matches.length > 1 ? 's' : ''} found!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Real-time updates as new riders join',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
          );
        }

        final match = matches[index - 1];
        return _RealMatchCard(
              match: match,
              isNight: isNight,
              onAccept: () => _joinFlowCoordinator.start(
                context: context,
                ref: ref,
                hostRide: match.ride,
              ),
            )
            .animate()
            .fadeIn(delay: (200 * index).ms)
            .slideY(begin: 0.2, end: 0, delay: (200 * index).ms);
      },
    );
  }
}

class _IncomingRequestBanner extends StatelessWidget {
  const _IncomingRequestBanner({
    required this.requesterName,
    required this.requesterGender,
    required this.requesterPickup,
    required this.requesterDropoff,
    required this.onAccept,
    required this.onDecline,
  });

  final String requesterName;
  final String requesterGender;
  final String requesterPickup;
  final String requesterDropoff;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Text(
                  RideFormatters.safeInitial(requesterName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ride Request',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$requesterName wants to share your ride',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                if (requesterGender.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          requesterGender.toLowerCase() == 'male'
                              ? Icons.male_rounded
                              : requesterGender.toLowerCase() == 'female'
                              ? Icons.female_rounded
                              : Icons.person_rounded,
                          size: 16,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Gender: $requesterGender',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (requesterPickup.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.info,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          requesterPickup,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (requesterPickup.isNotEmpty && requesterDropoff.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 2,
                        height: 12,
                        color: AppColors.divider,
                      ),
                    ),
                  ),
                if (requesterDropoff.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.danger,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          requesterDropoff,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDecline,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Accept Ride'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RealMatchCard extends StatelessWidget {
  const _RealMatchCard({
    required this.match,
    required this.isNight,
    required this.onAccept,
  });

  final ScoredMatch match;
  final bool isNight;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final ride = match.ride;
    final distanceKm = RideTripUtils.rideDistanceKm(ride);
    final projectedRiderCount =
        RideTripUtils.canonicalRiderIds(ride).length + 1;
    final fareEstimate = RideTripUtils.estimateTotalFare(distanceKm);
    final sharedFare = RideTripUtils.farePerRider(
      totalFare: fareEstimate,
      riderCount: projectedRiderCount,
    );
    final savingsPercent = ((1 - (1 / projectedRiderCount)) * 100).round();
    final matchSummary = match.reasons.take(2).join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${match.routeOverlapPercent.toStringAsFixed(0)}% overlap',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  RideFormatters.timeAgo(ride.createdAt),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isNight
                      ? AppColors.nightAccent
                      : AppColors.primary,
                  child: Text(
                    RideFormatters.safeInitial(ride.userName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.userName.isNotEmpty ? ride.userName : 'Rider',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${ride.pickup.address} -> ${ride.dropoff.address}',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (matchSummary.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                matchSummary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your shared fare',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '₹${sharedFare.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.savingsGradientStart,
                        AppColors.savingsGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Save $savingsPercent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: const Text('Share Ride'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
