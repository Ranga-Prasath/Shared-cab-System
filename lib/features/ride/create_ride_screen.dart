// -- Shared Cab System --
// Create Ride Screen

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/core/utils/night_mode_utils.dart';
import 'package:shared_cab/data/mock/mock_data.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/trip_model.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/providers/gps_provider.dart';
import 'package:uuid/uuid.dart';

class CreateRideScreen extends ConsumerStatefulWidget {
  const CreateRideScreen({super.key});

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> {
  final MapController _mapController = MapController();

  LocationPoint? _pickup;
  LocationPoint? _dropoff;
  DateTime _departureTime = DateTime.now().add(const Duration(minutes: 15));

  bool _isCreating = false;
  bool _isLocatingPickup = false;
  bool _locationUnavailable = false;
  String? _pendingAction;

  final List<LocationPoint> _locations = MockData.availableLocations;

  @override
  void initState() {
    super.initState();
    _setPickupFromCurrentLocation();
  }

  Future<void> _setPickupFromCurrentLocation() async {
    setState(() {
      _isLocatingPickup = true;
      _locationUnavailable = false;
    });

    final position = await GpsService.getCurrentPosition();
    if (!mounted) return;

    if (position == null) {
      setState(() {
        _isLocatingPickup = false;
        _locationUnavailable = true;
      });
      return;
    }

    setState(() {
      _pickup = LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Current Location',
      );
      _isLocatingPickup = false;
      _locationUnavailable = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusRouteOrPickup();
    });
  }

  Future<void> _createRide({required bool startNow}) async {
    if (_pickup == null || _dropoff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set pickup and drop-off first')),
      );
      return;
    }

    if (_pickup!.latitude == _dropoff!.latitude &&
        _pickup!.longitude == _dropoff!.longitude) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup and drop-off cannot be the same location'),
        ),
      );
      return;
    }

    final departureTime = startNow
        ? DateTime.now().add(const Duration(minutes: 1))
        : _departureTime;

    if (!startNow && !departureTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a future departure time')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
      _pendingAction = startNow ? 'start' : 'shared';
    });

    await Future.delayed(const Duration(milliseconds: 600));

    final ride = RideRequest(
      id: const Uuid().v4(),
      userId: ref.read(effectiveCurrentUserProvider).id,
      pickup: _pickup!,
      dropoff: _dropoff!,
      departureTime: departureTime,
      createdAt: DateTime.now(),
    );

    ref.read(currentRideRequestProvider.notifier).state = ride;

    if (startNow) {
      final distanceKm = ride.pickup.distanceTo(ride.dropoff);
      final fareEstimate = (distanceKm * 22).clamp(120, 900).toDouble();

      final trip = Trip(
        id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
        matchId: 'direct_${ride.id}',
        riderIds: [ref.read(effectiveCurrentUserProvider).id],
        status: TripStatus.waitingForPickup,
        startTime: DateTime.now(),
        isNightTrip: ride.isNightRide,
        safeArrivalPin: '4829',
        farePerPerson: fareEstimate,
        tripDistanceKm: distanceKm,
      );

      ref.read(panicModeProvider.notifier).state = false;
      ref.read(activeTripProvider.notifier).state = trip;

      if (!mounted) return;
      setState(() {
        _isCreating = false;
        _pendingAction = null;
      });
      context.goNamed('tripStatus', pathParameters: {'tripId': trip.id});
      return;
    }

    if (!mounted) return;
    setState(() {
      _isCreating = false;
      _pendingAction = null;
    });
    context.goNamed('matches', pathParameters: {'rideId': ride.id});
  }

  void _focusRouteOrPickup() {
    final pickup = _pickup;
    if (pickup == null) return;

    final pickupLatLng = LatLng(pickup.latitude, pickup.longitude);
    final dropoff = _dropoff;

    try {
      if (dropoff == null) {
        _mapController.move(pickupLatLng, 15.5);
        return;
      }

      final dropoffLatLng = LatLng(dropoff.latitude, dropoff.longitude);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([pickupLatLng, dropoffLatLng]),
          padding: const EdgeInsets.fromLTRB(48, 48, 48, 48),
        ),
      );
    } catch (_) {
      // Ignore camera calls before map is fully attached.
    }
  }

  void _setDropoffFromMap(LatLng location) {
    setState(() {
      _dropoff = LocationPoint(
        latitude: location.latitude,
        longitude: location.longitude,
        address:
            'Pinned drop-off (${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)})',
      );
    });
    _focusRouteOrPickup();
  }

  void _zoomMap(double delta) {
    try {
      final currentZoom = _mapController.camera.zoom;
      final currentCenter = _mapController.camera.center;
      final targetZoom = (currentZoom + delta).clamp(4.0, 19.0).toDouble();
      _mapController.move(currentCenter, targetZoom);
    } catch (_) {
      // Ignore zoom actions before map is attached.
    }
  }

  bool _sameLocation(LocationPoint a, LocationPoint b) {
    return (a.latitude - b.latitude).abs() < 0.000001 &&
        (a.longitude - b.longitude).abs() < 0.000001;
  }

  Widget _buildMapCard(bool isNight) {
    final pickup = _pickup;
    final dropoff = _dropoff;

    final center = pickup == null
        ? const LatLng(13.0827, 80.2707)
        : LatLng(pickup.latitude, pickup.longitude);

    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14.8,
              onMapReady: _focusRouteOrPickup,
              onTap: (_, point) => _setDropoffFromMap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sharedcab.app',
              ),
              if (pickup != null && dropoff != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [
                        LatLng(pickup.latitude, pickup.longitude),
                        LatLng(dropoff.latitude, dropoff.longitude),
                      ],
                      color: isNight
                          ? AppColors.nightAccent
                          : AppColors.primary,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (pickup != null)
                    Marker(
                      point: LatLng(pickup.latitude, pickup.longitude),
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  if (dropoff != null)
                    Marker(
                      point: LatLng(dropoff.latitude, dropoff.longitude),
                      width: 42,
                      height: 42,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.danger,
                        size: 36,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 14,
                    color: AppColors.info,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Tap map to set drop-off',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                _MapZoomButton(
                  icon: Icons.add_rounded,
                  onTap: () => _zoomMap(1),
                ),
                const SizedBox(height: 8),
                _MapZoomButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _zoomMap(-1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNight = ref.watch(effectiveNightModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Ride'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed('home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose Route',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(),
            const SizedBox(height: 8),
            _buildMapCard(isNight).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _pickup?.address ??
                          (_isLocatingPickup
                              ? 'Fetching current location...'
                              : 'Current location unavailable'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isLocatingPickup
                        ? null
                        : _setPickupFromCurrentLocation,
                    icon: _isLocatingPickup
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.gps_fixed_rounded, size: 16),
                    label: const Text('Use Current'),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms),

            if (_locationUnavailable) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Location permission is off. Enable GPS to auto-set pickup.',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            Text(
              'Drop-off Location',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            _buildLocationDropdown(
              value: _dropoff,
              hint: 'Select drop-off point',
              icon: Icons.location_on,
              color: AppColors.danger,
              onChanged: (loc) {
                setState(() => _dropoff = loc);
                _focusRouteOrPickup();
              },
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 24),

            Text(
              'Departure Time',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_departureTime),
                );
                if (time != null) {
                  setState(() {
                    _departureTime = DateTime(
                      _departureTime.year,
                      _departureTime.month,
                      _departureTime.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (isNightDateTime(_departureTime))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.nightMoon.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.nightlight_round,
                              color: AppColors.nightMoon,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Night',
                              style: TextStyle(
                                color: AppColors.nightMoon,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 16),

            if (_pickup != null && _dropoff != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.straighten_rounded,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Est. distance: ${_pickup!.distanceTo(_dropoff!).toStringAsFixed(1)} km',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isCreating ? null : () => _createRide(startNow: true),
              child: _isCreating && _pendingAction == 'start'
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_taxi_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Start Ride Now'),
                      ],
                    ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),

            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: _isCreating
                  ? null
                  : () => _createRide(startNow: false),
              child: _isCreating && _pendingAction == 'shared'
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Search Co-Riders'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDropdown({
    required LocationPoint? value,
    required String hint,
    required IconData icon,
    required Color color,
    required ValueChanged<LocationPoint?> onChanged,
  }) {
    final dropdownItems = [..._locations];
    if (value != null &&
        !dropdownItems.any((existing) => _sameLocation(existing, value))) {
      dropdownItems.insert(0, value);
    }

    return DropdownButtonFormField<LocationPoint>(
      key: ValueKey(
        '${value?.latitude}-${value?.longitude}-${value?.address ?? hint}',
      ),
      initialValue: value,
      hint: Text(hint),
      decoration: InputDecoration(prefixIcon: Icon(icon, color: color)),
      items: dropdownItems.map((loc) {
        return DropdownMenuItem(
          value: loc,
          child: Text(loc.address, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _MapZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}
