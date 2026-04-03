import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_cab/core/matching/matching_pipeline.dart';
import 'package:shared_cab/core/services/ride_join_flow_coordinator.dart';
import 'package:shared_cab/core/services/ride_service.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/core/utils/ride_formatters.dart';
import 'package:shared_cab/core/utils/ride_trip_utils.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/scored_match_model.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/providers/gps_provider.dart';

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
  String? _locationError;
  final RideJoinFlowCoordinator _joinFlowCoordinator =
      const RideJoinFlowCoordinator();

  @override
  void initState() {
    super.initState();
    _loadMyLocation();
  }

  Future<void> _loadMyLocation() async {
    final position = await GpsService.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _myLat = position?.latitude;
      _myLng = position?.longitude;
      _loadingLocation = false;
      _locationError = position == null
          ? 'Location access is required to discover rides near you.'
          : null;
    });
  }

  Future<void> _shareRide(RideRequest ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request to share ride?'),
        content: Text(
          'You will send a request to ${ride.userName.isNotEmpty ? ride.userName : "this rider"} '
          'to share the ride from ${ride.pickup.address} to ${ride.dropoff.address}.\n\n'
          'They will need to accept before you can ride together.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _joinFlowCoordinator.start(
        context: context,
        ref: ref,
        hostRide: ride,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNight = ref.watch(effectiveNightModeProvider);
    final sameGenderOnly = ref.watch(sameGenderOnlyProvider);
    final currentUser = ref.watch(effectiveCurrentUserProvider);
    final currentRide = ref.watch(currentRideRequestProvider);
    final ridePreferences = ref.watch(ridePreferencesProvider);
    final hasMatchContext = currentRide != null || (_myLat != null && _myLng != null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rides'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed('home'),
        ),
      ),
      body: _loadingLocation
          ? _buildLoadingLocation()
          : !hasMatchContext
          ? _buildLocationRequired(context)
          : StreamBuilder<List<RideRequest>>(
              stream: RideService.availableRidesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoading();
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final nearbyRides = MatchingPipeline.evaluate(
                  candidates: snapshot.data ?? const [],
                  context: MatchContext(
                    currentUserId: currentUser.id,
                    currentUserGender: currentUser.gender,
                    riderPreferences: ridePreferences,
                    isNightMode: isNight,
                    sameGenderOnly: sameGenderOnly,
                    now: DateTime.now(),
                    referenceRide: currentRide,
                    desiredDepartureTime: currentRide?.departureTime,
                    currentLocation: _myLat == null || _myLng == null
                        ? null
                        : LatLng(_myLat!, _myLng!),
                  ),
                );

                if (nearbyRides.isEmpty) {
                  return _buildEmpty(context);
                }

                return _buildRideList(
                  context,
                  nearbyRides,
                  isNight,
                  currentUser.id,
                );
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
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
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

  Widget _buildLoadingLocation() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Getting your location...'),
        ],
      ),
    );
  }

  Widget _buildLocationRequired(BuildContext context) {
    final message =
        _locationError ??
        'Add a ride or enable location so matching has a real route to evaluate.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_searching_rounded,
              size: 64,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              'Location required',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _loadingLocation = true;
                    _locationError = null;
                  });
                  _loadMyLocation();
                },
                icon: const Icon(Icons.my_location_rounded),
                label: const Text('Retry Location'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.goNamed('createRide'),
                icon: const Icon(Icons.add_road),
                label: const Text('Create Ride Instead'),
              ),
            ),
          ],
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'No rides available nearby',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No other riders have posted rides along your route yet. '
              'Create your own ride and others will find you.',
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
    BuildContext context,
    List<ScoredMatch> rides,
    bool isNight,
    String currentUserId,
  ) {
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
                  const Icon(
                    Icons.people_alt_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
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

        final match = rides[index - 1];
        return _RideCard(
              match: match,
              isNight: isNight,
              isShareDisabled: match.ride.userId == currentUserId,
              onShareRide: () => _shareRide(match.ride),
            )
            .animate()
            .fadeIn(delay: (150 * index).ms)
            .slideY(begin: 0.15, end: 0, delay: (150 * index).ms);
      },
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({
    required this.match,
    required this.isNight,
    required this.isShareDisabled,
    required this.onShareRide,
  });

  final ScoredMatch match;
  final bool isNight;
  final bool isShareDisabled;
  final VoidCallback onShareRide;

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
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
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
                        'Posted ${RideFormatters.timeAgo(ride.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    RideFormatters.departureLabel(ride.departureTime),
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
                      const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.info,
                        size: 16,
                      ),
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
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.danger,
                        size: 16,
                      ),
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
            if (matchSummary.isNotEmpty) ...[
              Text(
                matchSummary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
            ],
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
                Row(
                  children: [
                    Text(
                      '${distanceKm.toStringAsFixed(1)} km',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isShareDisabled ? null : onShareRide,
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: const Text('Share Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isNight
                      ? AppColors.nightAccent
                      : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
