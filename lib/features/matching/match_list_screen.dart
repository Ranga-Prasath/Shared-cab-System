// -- Shared Cab System --
// Match List Screen — real-time co-rider matching via Firestore
// Shows incoming join requests with Accept/Decline buttons

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/services/ride_service.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/core/utils/night_mode_utils.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/trip_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MatchListScreen extends ConsumerStatefulWidget {
  final String rideId;

  const MatchListScreen({super.key, required this.rideId});

  @override
  ConsumerState<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends ConsumerState<MatchListScreen> {
  bool _initialLoading = true;
  StreamSubscription? _myRideSub;
  bool _alreadyNavigated = false;

  // Incoming request state
  bool _hasIncomingRequest = false;
  String _requesterName = '';
  String _requesterId = '';
  String _requesterGender = '';
  String _requesterPickup = '';
  String _requesterDropoff = '';

  // Waiting for more riders state
  bool _isWaitingForMoreRiders = false;
  int _acceptedRiderCount = 0;

  // Store the stream so it's only created ONCE
  late final Stream<List<RideRequest>> _ridesStream;

  @override
  void initState() {
    super.initState();
    _ridesStream = RideService.availableRidesStream();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _initialLoading = false);
    });

    _listenForMyRideUpdates();
  }

  void _listenForMyRideUpdates() {
    final myRide = ref.read(currentRideRequestProvider);
    if (myRide == null) return;

    _myRideSub = RideService.rideStream(myRide.id).listen((updatedRide) {
      if (updatedRide == null || _alreadyNavigated || !mounted) return;

      // Someone REQUESTED to join (needs approval)
      if (updatedRide.status == RideStatus.requested &&
          updatedRide.requesterId != null) {
        setState(() {
          _hasIncomingRequest = true;
          _requesterName = updatedRide.requesterName ?? 'A rider';
          _requesterId = updatedRide.requesterId!;
          _requesterGender = updatedRide.requesterGender ?? '';
          _requesterPickup = updatedRide.requesterPickup ?? '';
          _requesterDropoff = updatedRide.requesterDropoff ?? '';
        });
        return;
      }

      // Request was declined — clear the request UI
      if (updatedRide.status == RideStatus.pending) {
        setState(() {
          _hasIncomingRequest = false;
          _requesterName = '';
          _requesterId = '';
          _requesterGender = '';
          _requesterPickup = '';
          _requesterDropoff = '';
          // Keep waiting state if already in it
        });
        return;
      }

      // Accepted and WAITING for more riders
      if (updatedRide.status == RideStatus.acceptedWaiting) {
        setState(() {
          _isWaitingForMoreRiders = true;
          _acceptedRiderCount = updatedRide.coRiderIds.length;
          _hasIncomingRequest = false;
          _requesterName = '';
          _requesterId = '';
        });
        return;
      }

      // Ride was matched — navigate to trip
      if (updatedRide.status == RideStatus.matched &&
          updatedRide.coRiderIds.isNotEmpty) {
        _alreadyNavigated = true;
        _navigateToTrip(updatedRide);
      }
    });
  }

  void _acceptRequest() async {
    final myRide = ref.read(currentRideRequestProvider);
    if (myRide == null) return;

    setState(() => _hasIncomingRequest = false);

    // Show choice: Wait for more riders or Proceed now
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Rider accepted! 🎉'),
        content: const Text(
          'Do you want to wait for more riders to join '
          'or start the ride now?',
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'wait'),
            icon: const Icon(Icons.hourglass_top_rounded, size: 18),
            label: const Text('Wait for more'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'proceed'),
            icon: const Icon(Icons.directions_car_rounded, size: 18),
            label: const Text('Proceed now'),
          ),
        ],
      ),
    );

    if (choice == 'wait') {
      await RideService.acceptRequest(myRide.id, waitForMore: true);
      // Stream listener will detect 'acceptedWaiting' and update UI
    } else {
      await RideService.acceptRequest(myRide.id, waitForMore: false);
      // Stream listener will detect 'matched' and navigate
    }
  }

  void _proceedNow() async {
    final myRide = ref.read(currentRideRequestProvider);
    if (myRide == null) return;
    await RideService.proceedRide(myRide.id);
    // Stream listener will detect 'matched' and navigate
  }

  void _declineRequest() async {
    final myRide = ref.read(currentRideRequestProvider);
    if (myRide == null) return;

    setState(() {
      _hasIncomingRequest = false;
      _requesterName = '';
      _requesterId = '';
    });
    await RideService.declineRequest(myRide.id);
  }

  void _navigateToTrip(RideRequest ride) {
    final currentUser = ref.read(effectiveCurrentUserProvider);
    final distanceKm = ride.pickup.distanceTo(ride.dropoff);
    final fareEstimate = (distanceKm * 22).clamp(120, 900).toDouble();

    final trip = Trip(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      matchId: 'shared_${ride.id}',
      riderIds: [currentUser.id, ...ride.coRiderIds],
      status: TripStatus.waitingForPickup,
      startTime: DateTime.now(),
      isNightTrip: ride.isNightRide,
      safeArrivalPin: '4829',
      farePerPerson: fareEstimate / 2,
      tripDistanceKm: distanceKm,
    );

    ref.read(panicModeProvider.notifier).state = false;
    ref.read(activeTripProvider.notifier).state = trip;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Ride shared! Heading to trip...'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      context.goNamed('tripStatus', pathParameters: {'tripId': trip.id});
    }
  }

  @override
  void dispose() {
    _myRideSub?.cancel();
    super.dispose();
  }

  bool _isAlongMyRoute(RideRequest otherRide) {
    final myRide = ref.read(currentRideRequestProvider);
    if (myRide == null) return true;

    final pickupDistKm = myRide.pickup.distanceTo(otherRide.pickup);
    final dropoffDistKm = myRide.dropoff.distanceTo(otherRide.dropoff);

    return pickupDistKm <= 5.0 && dropoffDistKm <= 5.0;
  }

  double _calculateOverlap(RideRequest otherRide) {
    final myRide = ref.read(currentRideRequestProvider);
    if (myRide == null) return 0;

    final totalPickupDist = myRide.pickup.distanceTo(otherRide.pickup);
    final totalDropDist = myRide.dropoff.distanceTo(otherRide.dropoff);
    final myRouteDist = myRide.pickup.distanceTo(myRide.dropoff);

    if (myRouteDist == 0) return 100;

    final avgDeviation = (totalPickupDist + totalDropDist) / 2;
    final overlapPercent = max(0, (1 - (avgDeviation / myRouteDist)) * 100);
    return overlapPercent.clamp(0, 100).toDouble();
  }

  void _sendRequest(RideRequest otherRide) async {
    final currentUser = ref.read(effectiveCurrentUserProvider);
    final myRide = ref.read(currentRideRequestProvider);
    final router = GoRouter.of(context);

    try {
      await RideService.requestToJoin(
        rideId: otherRide.id,
        requesterId: currentUser.id,
        requesterName: currentUser.name,
        requesterGender: currentUser.gender,
        requesterPickup: myRide?.pickup.address ?? '',
        requesterDropoff: myRide?.dropoff.address ?? '',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
      return;
    }

    if (!mounted) return;

    // Create a notifier for the dynamic status of the dialog
    final rideStatusNotifier = ValueNotifier<RideStatus>(RideStatus.requested);
    
    // Track whether dialog is still open
    bool dialogOpen = false;

    // Create stream subscription OUTSIDE the dialog builder
    late final StreamSubscription sub;
    sub = RideService.rideStream(otherRide.id).listen((updatedRide) {
      if (updatedRide == null || !mounted) return;
      
      rideStatusNotifier.value = updatedRide.status;

      if (updatedRide.status == RideStatus.matched) {
        sub.cancel();
        _alreadyNavigated = true;

        final distanceKm = otherRide.pickup.distanceTo(otherRide.dropoff);
        final fareEstimate = (distanceKm * 22).clamp(120, 900).toDouble();

        final trip = Trip(
          id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
          matchId: 'shared_${otherRide.id}',
          riderIds: [currentUser.id, otherRide.userId],
          status: TripStatus.waitingForPickup,
          startTime: DateTime.now(),
          isNightTrip: myRide?.isNightRide ?? isNightDateTime(DateTime.now()),
          safeArrivalPin: '4829',
          farePerPerson: fareEstimate / 2,
          tripDistanceKm: distanceKm,
        );

        // Set trip provider FIRST
        ref.read(panicModeProvider.notifier).state = false;
        ref.read(activeTripProvider.notifier).state = trip;

        // Navigate — router.go replaces the entire navigation stack
        // (including any dialogs) so no need to pop dialog separately
        router.go('/trip/${trip.id}');
      }

      if (updatedRide.status == RideStatus.declined) {
        sub.cancel();
        // Close dialog if still open
        if (dialogOpen && mounted) {
          dialogOpen = false;
          Navigator.of(context).pop();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${otherRide.userName} declined your request.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    });

    // Show dialog (the stream is already listening above)
    dialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: ValueListenableBuilder<RideStatus>(
          valueListenable: rideStatusNotifier,
          builder: (context, status, child) {
            final isWaiting = status == RideStatus.acceptedWaiting;
            return AlertDialog(
              title: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(isWaiting ? 'Waiting for another rider' : 'Waiting for approval'),
                ],
              ),
              content: Text(
                isWaiting 
                    ? 'Your request was accepted! ${otherRide.userName.isNotEmpty ? otherRide.userName : "The rider"} is waiting for another rider to join the trip...'
                    : '${otherRide.userName.isNotEmpty ? otherRide.userName : "The rider"} is reviewing your request...\n\nYou will be notified when they accept or decline.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // If we cancel while acceptedWaiting, we need to leave the ride instead of just closing dialog
                    if (isWaiting) {
                      RideService.leaveRide(otherRide.id);
                    }
                    sub.cancel();
                    dialogOpen = false;
                    Navigator.of(ctx).pop();
                  },
                  child: Text(isWaiting ? 'Cancel Ride' : 'Cancel Request'),
                ),
              ],
            );
          },
        ),
      ),
    ).then((_) {
      dialogOpen = false;
      sub.cancel();
    });
  }

  void _startDirectRide() {
    final currentRideRequest = ref.read(currentRideRequestProvider);
    final currentUser = ref.read(effectiveCurrentUserProvider);
    if (currentRideRequest == null) return;

    final distanceKm = currentRideRequest.pickup.distanceTo(
      currentRideRequest.dropoff,
    );
    final fareEstimate = (distanceKm * 22).clamp(120, 900).toDouble();

    final trip = Trip(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      matchId: 'direct_${currentRideRequest.id}',
      riderIds: [currentUser.id],
      status: TripStatus.waitingForPickup,
      startTime: DateTime.now(),
      isNightTrip: currentRideRequest.isNightRide,
      safeArrivalPin: '4829',
      farePerPerson: fareEstimate,
      tripDistanceKm: distanceKm,
    );

    ref.read(panicModeProvider.notifier).state = false;
    ref.read(activeTripProvider.notifier).state = trip;
    context.goNamed('tripStatus', pathParameters: {'tripId': trip.id});
  }

  @override
  Widget build(BuildContext context) {
    final isNight = ref.watch(effectiveNightModeProvider);
    final currentUser = ref.watch(currentUserProvider);

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
          // ── Incoming request banner (Accept / Decline) ──
          if (_hasIncomingRequest)
            _IncomingRequestBanner(
              requesterName: _requesterName,
              requesterGender: _requesterGender,
              requesterPickup: _requesterPickup,
              requesterDropoff: _requesterDropoff,
              onAccept: _acceptRequest,
              onDecline: _declineRequest,
            ).animate().fadeIn().slideY(begin: -0.3, end: 0),

          // ── Waiting for more riders banner ──
          if (_isWaitingForMoreRiders && !_hasIncomingRequest)
            _WaitingForMoreBanner(
              acceptedCount: _acceptedRiderCount,
              onProceed: _proceedNow,
            ).animate().fadeIn().slideY(begin: -0.3, end: 0),

          // ── Main content ──
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

                      final allRides = snapshot.data ?? [];
                      final myId = currentUser?.id ?? '';

                      final matchingRides = allRides
                          .where((r) =>
                              r.userId != myId && _isAlongMyRoute(r))
                          .toList();

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
      BuildContext context, List<RideRequest> rides, bool isNight) {
    if (rides.isEmpty) {
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
              ).animate(onPlay: (c) => c.repeat()).shimmer(
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
                'on the same route requests to join!',
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
      itemCount: rides.length + 1,
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
                  const Icon(Icons.people_alt_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${rides.length} co-rider${rides.length > 1 ? 's' : ''} found!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Real-time • Updates as new riders join',
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

        final ride = rides[index - 1];
        final overlap = _calculateOverlap(ride);

        return _RealMatchCard(
              ride: ride,
              overlapPercent: overlap,
              isNight: isNight,
              onAccept: () => _sendRequest(ride),
            )
            .animate()
            .fadeIn(delay: (200 * index).ms)
            .slideY(begin: 0.2, end: 0, delay: (200 * index).ms);
      },
    );
  }
}

// ── Incoming Request Banner (Accept / Decline) ──

class _IncomingRequestBanner extends StatelessWidget {
  final String requesterName;
  final String requesterGender;
  final String requesterPickup;
  final String requesterDropoff;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingRequestBanner({
    required this.requesterName,
    this.requesterGender = '',
    this.requesterPickup = '',
    this.requesterDropoff = '',
    required this.onAccept,
    required this.onDecline,
  });

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
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Text(
                  requesterName.isNotEmpty
                      ? requesterName[0].toUpperCase()
                      : '?',
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
                      '🔔 Ride Request!',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$requesterName wants to share your ride',
                      style: TextStyle(
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

          // Requester details: gender + route
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
                      const Icon(Icons.my_location_rounded,
                          color: AppColors.info, size: 16),
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
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.danger, size: 16),
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

          // Accept / Decline buttons
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

// ── Waiting for More Riders Banner ──

class _WaitingForMoreBanner extends StatelessWidget {
  final int acceptedCount;
  final VoidCallback onProceed;

  const _WaitingForMoreBanner({
    required this.acceptedCount,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⏳ Waiting for more riders...',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$acceptedCount rider${acceptedCount > 1 ? 's' : ''} accepted so far',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onProceed,
              icon: const Icon(Icons.directions_car_rounded, size: 18),
              label: const Text('Proceed Now — Start Ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Real Match Card ──

class _RealMatchCard extends StatelessWidget {
  final RideRequest ride;
  final double overlapPercent;
  final bool isNight;
  final VoidCallback onAccept;

  const _RealMatchCard({
    required this.ride,
    required this.overlapPercent,
    required this.isNight,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final distanceKm = ride.pickup.distanceTo(ride.dropoff);
    final fareEstimate = (distanceKm * 22).clamp(120, 900).toDouble();
    final sharedFare = fareEstimate / 2;

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${overlapPercent.toStringAsFixed(0)}% overlap',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _timeAgo(ride.createdAt),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      isNight ? AppColors.nightAccent : AppColors.primary,
                  child: Text(
                    ride.userName.isNotEmpty
                        ? ride.userName[0].toUpperCase()
                        : '?',
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
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${ride.pickup.address} → ${ride.dropoff.address}',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your shared fare',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      '₹${sharedFare.toStringAsFixed(0)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      AppColors.savingsGradientStart,
                      AppColors.savingsGradientEnd,
                    ]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Save 50%',
                    style: TextStyle(
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

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
