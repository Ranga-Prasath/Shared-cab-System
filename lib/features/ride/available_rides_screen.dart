// -- Shared Cab System --
// Available Rides Screen — shows real-time pending rides from other users

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/services/ride_service.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/trip_model.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/providers/gps_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AvailableRidesScreen extends ConsumerStatefulWidget {
  const AvailableRidesScreen({super.key});

  @override
  ConsumerState<AvailableRidesScreen> createState() =>
      _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends ConsumerState<AvailableRidesScreen> {
  double? _myLat;
  double? _myLng;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadMyLocation();
  }

  Future<void> _loadMyLocation() async {
    final pos = await GpsService.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _myLat = pos?.latitude;
      _myLng = pos?.longitude;
      _loadingLocation = false;
    });
  }

  /// Returns true if the point (myLat, myLng) is within `thresholdKm` of the
  /// line segment from pickup to dropoff.  This is a simplified "corridor"
  /// check — it computes the perpendicular distance from the point to the
  /// line defined by the two route endpoints.
  bool _isAlongRoute(RideRequest ride, {double thresholdKm = 5.0}) {
    if (_myLat == null || _myLng == null) return true; // show all if no GPS

    final px = _myLat!;
    final py = _myLng!;
    final ax = ride.pickup.latitude;
    final ay = ride.pickup.longitude;
    final bx = ride.dropoff.latitude;
    final by = ride.dropoff.longitude;

    // Distance from a point to a line segment (in degrees, then convert)
    final dx = bx - ax;
    final dy = by - ay;
    final lenSq = dx * dx + dy * dy;

    double closestLat, closestLng;
    if (lenSq == 0) {
      closestLat = ax;
      closestLng = ay;
    } else {
      var t = ((px - ax) * dx + (py - ay) * dy) / lenSq;
      t = t.clamp(0.0, 1.0);
      closestLat = ax + t * dx;
      closestLng = ay + t * dy;
    }

    final distDeg =
        sqrt(pow(px - closestLat, 2) + pow(py - closestLng, 2));
    final distKm = distDeg * 111; // rough km per degree

    return distKm <= thresholdKm;
  }

  void _shareRide(RideRequest ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request to share ride?'),
        content: Text(
          'You will send a request to ${ride.userName.isNotEmpty ? ride.userName : "this rider"} '
          'to share the ride from ${ride.pickup.address} to ${ride.dropoff.address}.\n\n'
          'They will need to accept your request before you can ride together.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final currentUser = ref.read(effectiveCurrentUserProvider);

    try {
      // Send request (not direct join)
      await RideService.requestToJoin(
        rideId: ride.id,
        requesterId: currentUser.id,
        requesterName: currentUser.name,
        requesterGender: currentUser.gender,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
      return;
    }

    if (!mounted) return;

    // Show "Waiting for approval" dialog and listen for response
    _showWaitingDialog(ride, currentUser.id);
  }

  void _showWaitingDialog(RideRequest ride, String myId) {
    final router = GoRouter.of(context);
    bool dialogOpen = false;

    // Create stream subscription OUTSIDE the dialog builder
    late final StreamSubscription sub;
    sub = RideService.rideStream(ride.id).listen((updatedRide) {
      if (updatedRide == null || !mounted) return;

      // ACCEPTED — navigate to trip!
      if (updatedRide.status == RideStatus.matched) {
        sub.cancel();

        final currentUser = ref.read(effectiveCurrentUserProvider);
        final distanceKm = ride.pickup.distanceTo(ride.dropoff);
        final fareEstimate = (distanceKm * 22).clamp(120, 900).toDouble();

        final trip = Trip(
          id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
          matchId: 'shared_${ride.id}',
          riderIds: [ride.userId, currentUser.id],
          status: TripStatus.waitingForPickup,
          startTime: DateTime.now(),
          isNightTrip: ride.isNightRide,
          safeArrivalPin: '4829',
          farePerPerson: fareEstimate / 2,
          tripDistanceKm: distanceKm,
        );

        // Set trip provider FIRST
        ref.read(panicModeProvider.notifier).state = false;
        ref.read(activeTripProvider.notifier).state = trip;

        // Navigate — router.go replaces the entire navigation stack
        router.go('/trip/${trip.id}');
      }

      // DECLINED — show message and dismiss
      if (updatedRide.status == RideStatus.declined) {
        sub.cancel();
        if (dialogOpen && mounted) {
          dialogOpen = false;
          Navigator.of(context).pop();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${ride.userName} declined your ride request.'),
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
            '${ride.userName.isNotEmpty ? ride.userName : "The rider"} '
            'is reviewing your request...\n\n'
            'You will be notified when they accept or decline.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                sub.cancel();
                dialogOpen = false;
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel Request'),
            ),
          ],
        ),
      ),
    ).then((_) {
      dialogOpen = false;
      sub.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNight = ref.watch(effectiveNightModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rides'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed('home'),
        ),
      ),
      body: _loadingLocation
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Getting your location...'),
                ],
              ),
            )
          : StreamBuilder<List<RideRequest>>(
              stream: RideService.availableRidesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoading();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final allRides = snapshot.data ?? [];
                // Filter to rides along user's route
                final nearbyRides = allRides
                    .where((r) => _isAlongRoute(r))
                    .toList();

                if (nearbyRides.isEmpty) {
                  return _buildEmpty(context);
                }

                return _buildRideList(context, nearbyRides, isNight);
              },
            ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child:
                CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Searching for rides near you...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No rides available nearby',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No other riders have posted rides along your route yet. '
              'Create your own ride and others will find you!',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.goNamed('createRide'),
              icon: const Icon(Icons.add_road),
              label: const Text('Create a Ride'),
            ),
          ],
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildRideList(
      BuildContext context, List<RideRequest> rides, bool isNight) {
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
                  Text(
                    '${rides.length} ride${rides.length > 1 ? 's' : ''} available nearby',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
          );
        }

        final ride = rides[index - 1];
        return _RideCard(
              ride: ride,
              isNight: isNight,
              onShareRide: () => _shareRide(ride),
              myLat: _myLat,
              myLng: _myLng,
            )
            .animate()
            .fadeIn(delay: (150 * index).ms)
            .slideY(begin: 0.15, end: 0, delay: (150 * index).ms);
      },
    );
  }
}

class _RideCard extends StatelessWidget {
  final RideRequest ride;
  final bool isNight;
  final VoidCallback onShareRide;
  final double? myLat;
  final double? myLng;

  const _RideCard({
    required this.ride,
    required this.isNight,
    required this.onShareRide,
    this.myLat,
    this.myLng,
  });

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _departureLabel(DateTime time) {
    final diff = time.difference(DateTime.now());
    if (diff.isNegative) return 'Departing now';
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes} min';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = ride.pickup.distanceTo(ride.dropoff);
    final fareEstimate = (distanceKm * 22).clamp(120, 900).toDouble();
    final sharedFare = fareEstimate / 2;
    final savingsPercent = 50;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: poster name + time
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      isNight ? AppColors.nightAccent : AppColors.primary,
                  child: Text(
                    ride.userName.isNotEmpty ? ride.userName[0].toUpperCase() : '?',
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
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Posted ${_timeAgo(ride.createdAt)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _departureLabel(ride.departureTime),
                    style: const TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Route: pickup → dropoff
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location_rounded,
                          color: AppColors.info, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.pickup.address,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 2,
                        height: 16,
                        color: AppColors.divider,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.dropoff.address,
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

            const SizedBox(height: 12),

            // Fare info
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
                Row(
                  children: [
                    Text(
                      '${distanceKm.toStringAsFixed(1)} km',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Share Ride button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onShareRide,
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: const Text('Share Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isNight ? AppColors.nightAccent : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
