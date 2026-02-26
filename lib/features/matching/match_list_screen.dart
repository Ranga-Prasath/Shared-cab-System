// -- Shared Cab System --
// Match List Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/core/utils/night_mode_utils.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/models/match_model.dart';
import 'package:shared_cab/models/trip_model.dart';
import 'package:shared_cab/data/mock/mock_data.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MatchListScreen extends ConsumerStatefulWidget {
  final String rideId;

  const MatchListScreen({super.key, required this.rideId});

  @override
  ConsumerState<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends ConsumerState<MatchListScreen> {
  bool _isSearching = true;
  List<MatchResult> _matches = [];

  @override
  void initState() {
    super.initState();
    _searchMatches();
  }

  Future<void> _searchMatches() async {
    // Simulate search delay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _matches = MockData.getMockMatches(widget.rideId);
      _isSearching = false;
    });

    if (_matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No co-riders found. Booking a direct ride and tracking pickup...',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        _startDirectRide();
      });
    }
  }

  void _acceptMatch(MatchResult match) {
    final currentRideRequest = ref.read(currentRideRequestProvider);
    final currentUser = ref.read(effectiveCurrentUserProvider);

    final trip = Trip(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      matchId: match.id,
      riderIds: [currentUser.id, ...match.riders.map((r) => r.userId)],
      status: TripStatus.waitingForPickup,
      startTime: DateTime.now(),
      isNightTrip:
          currentRideRequest?.isNightRide ?? isNightDateTime(DateTime.now()),
      safeArrivalPin: '4829',
      farePerPerson: match.estimatedFarePerPerson,
      tripDistanceKm: 14.2,
    );

    ref.read(panicModeProvider.notifier).state = false;
    ref.read(activeTripProvider.notifier).state = trip;
    context.goNamed('tripStatus', pathParameters: {'tripId': trip.id});
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches Found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed('createRide'),
        ),
      ),
      body: _isSearching
          ? _buildSearching(context)
          : _buildResults(context, isNight),
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
            'Finding best matches...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Applying 80/15 matching rule',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildResults(BuildContext context, bool isNight) {
    if (_matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'No co-rider matches found',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You can continue with a direct cab and track the driver to pickup.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startDirectRide,
                  icon: const Icon(Icons.local_taxi_rounded),
                  label: const Text('Book Direct Ride'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.goNamed('createRide'),
                  icon: const Icon(Icons.edit_location_alt_rounded),
                  label: const Text('Change Pickup / Time'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matches.length + 1,
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
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_matches.length} match${_matches.length > 1 ? 'es' : ''} found!',
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

        final match = _matches[index - 1];
        return _MatchCard(
              match: match,
              isNight: isNight,
              onAccept: () => _acceptMatch(match),
            )
            .animate()
            .fadeIn(delay: (200 * index).ms)
            .slideY(begin: 0.2, end: 0, delay: (200 * index).ms);
      },
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchResult match;
  final bool isNight;
  final VoidCallback onAccept;

  const _MatchCard({
    required this.match,
    required this.isNight,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: overlap % and riders count
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${match.riderCount} rider${match.riderCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Riders list
            ...match.riders.map(
              (rider) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isNight
                          ? AppColors.nightAccent
                          : AppColors.primary,
                      child: Text(
                        rider.name[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rider.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '${rider.pickupAddress} -> ${rider.dropoffAddress}',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.warning,
                          size: 16,
                        ),
                        Text(
                          ' ${rider.rating}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 20),

            // Fare split
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your fare',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'INR ${match.estimatedFarePerPerson.toStringAsFixed(0)}',
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
                    'Save ${match.savingsPercent.toStringAsFixed(0)}%',
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

            // Accept button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: const Text('Accept Match'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
