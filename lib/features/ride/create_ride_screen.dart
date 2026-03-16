// -- Shared Cab System --
// Create Ride Screen

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_cab/core/services/auth_service.dart';
import 'package:shared_cab/core/services/geocoding_service.dart';
import 'package:shared_cab/core/services/ride_service.dart';
import 'package:shared_cab/core/session/ride_session_controller.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/core/utils/night_mode_utils.dart';
import 'package:shared_cab/core/utils/ride_trip_utils.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/user_model.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/providers/gps_provider.dart';
import 'package:uuid/uuid.dart';

import '../trip/utils/trip_route_builder.dart';

class CreateRideScreen extends ConsumerStatefulWidget {
  const CreateRideScreen({super.key});

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _pickupSearchController = TextEditingController();
  final TextEditingController _dropoffSearchController =
      TextEditingController();

  LocationPoint? _pickup;
  LocationPoint? _dropoff;
  DateTime _departureTime = DateTime.now().add(const Duration(minutes: 15));

  bool _isCreating = false;
  bool _isLocatingPickup = false;
  bool _locationUnavailable = false;
  String? _pendingAction;

  // Search state
  List<LocationPoint> _pickupSearchResults = [];
  bool _isSearchingPickup = false;
  List<LocationPoint> _searchResults = [];
  bool _isSearching = false;
  Timer? _pickupSearchDebounce;
  Timer? _searchDebounce;
  List<LatLng> _previewRoutePoints = const [];
  bool _isLoadingPreviewRoute = false;
  int _previewRouteRequestId = 0;

  @override
  void initState() {
    super.initState();
    _setPickupFromCurrentLocation();
  }

  @override
  void dispose() {
    _pickupSearchController.dispose();
    _dropoffSearchController.dispose();
    _pickupSearchDebounce?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
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

    // Use geocoding to get the real street address
    final address = await GeocodingService.reverseGeocode(
      position.latitude,
      position.longitude,
    );
    if (!mounted) return;

    setState(() {
      _pickup = LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
      _pickupSearchController.text = address;
      _isLocatingPickup = false;
      _locationUnavailable = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusRouteOrPickup();
    });
    unawaited(_refreshPreviewRoute());
  }

  void _onPickupSearchChanged(String query) {
    _pickupSearchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _pickupSearchResults = [];
        _isSearchingPickup = false;
      });
      return;
    }
    setState(() => _isSearchingPickup = true);
    _pickupSearchDebounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await GeocodingService.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _pickupSearchResults = results;
        _isSearchingPickup = false;
      });
    });
  }

  void _selectPickup(LocationPoint location) {
    setState(() {
      _pickup = location;
      _pickupSearchController.text = location.address;
      _pickupSearchResults = [];
    });
    _focusRouteOrPickup();
    unawaited(_refreshPreviewRoute());
  }

  void _onDropoffSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await GeocodingService.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  void _selectDropoff(LocationPoint location) {
    setState(() {
      _dropoff = location;
      _dropoffSearchController.text = location.address;
      _searchResults = [];
    });
    _focusRouteOrPickup();
    unawaited(_refreshPreviewRoute());
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

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final pickup = _pickup!;
      final dropoff = _dropoff!;
      final currentUser = await _resolveCurrentUserForRide();
      final riderPreferences = ref.read(ridePreferencesProvider);
      final previewOrFallbackRoute = await _resolveRouteForRide(
        pickup: pickup,
        dropoff: dropoff,
      );
      final storedRoutePath = TripRouteBuilder.compressRouteForStorage(
        previewOrFallbackRoute,
      );
      final distanceKm = TripRouteBuilder.estimatedDistanceKm(
        previewOrFallbackRoute,
      );

      final baseRide = RideRequest(
        id: const Uuid().v4(),
        userId: currentUser.id,
        userName: currentUser.name,
        userGender: currentUser.gender,
        pickup: pickup,
        dropoff: dropoff,
        departureTime: departureTime,
        createdAt: DateTime.now(),
        routePath: storedRoutePath
            .map(
              (point) => RideRoutePoint(
                latitude: point.latitude,
                longitude: point.longitude,
              ),
            )
            .toList(),
        preferenceSnapshot: riderPreferences,
      );
      final ride = RideTripUtils.prepareRideForPublication(
        baseRide,
        directRide: startNow,
      );

      ref.read(currentRideRequestProvider.notifier).state = ride;

      if (!startNow) {
        await _publishSharedRide(ride);
        if (!mounted) return;
        GoRouter.of(context).go('/matches/${ride.id}');
      } else {
        unawaited(
          RideService.publishRide(
            ride,
          ).timeout(const Duration(seconds: 3)).catchError((_) {
            // Direct rides can continue locally even if sync is slow.
          }),
        );
      }

      if (startNow) {
        final trip = RideSessionController.startDirectTrip(
          RideSessionStore.widget(ref),
          ride: ride,
          riderId: ref.read(effectiveCurrentUserProvider).id,
          distanceKm: distanceKm,
        );

        if (!mounted) return;
        context.goNamed('tripStatus', pathParameters: {'tripId': trip.id});
      }
    } catch (error, stackTrace) {
      debugPrint('[CreateRideScreen._createRide] $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open co-rider search. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _pendingAction = null;
        });
      }
    }
  }

  Future<User> _resolveCurrentUserForRide() async {
    final currentUser = ref.read(effectiveCurrentUserProvider);
    final currentUid = AuthService.currentUserId;
    if (currentUid == null || currentUid != currentUser.id) {
      return currentUser;
    }

    try {
      final canonicalUser = await AuthService.getUserProfile(currentUid);
      ref.read(currentUserOverrideProvider.notifier).state = canonicalUser;
      return canonicalUser;
    } catch (_) {
      return currentUser;
    }
  }

  Future<List<LatLng>> _resolveRouteForRide({
    required LocationPoint pickup,
    required LocationPoint dropoff,
  }) async {
    if (_previewRoutePoints.length > 1 && !_isLoadingPreviewRoute) {
      return _previewRoutePoints;
    }

    final start = LatLng(pickup.latitude, pickup.longitude);
    final end = LatLng(dropoff.latitude, dropoff.longitude);

    if (_isLoadingPreviewRoute) {
      final waitDeadline = DateTime.now().add(const Duration(seconds: 2));
      while (mounted &&
          _isLoadingPreviewRoute &&
          DateTime.now().isBefore(waitDeadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      if (_previewRoutePoints.length > 1) {
        return _previewRoutePoints;
      }
    }

    try {
      final route = await TripRouteBuilder.buildRoadFirstRoute(
        start,
        end,
        minPoints: 80,
      ).timeout(const Duration(seconds: 4));
      if (route.length > 1) {
        return route;
      }
    } catch (_) {
      // Fall through to the deterministic local route.
    }

    return TripRouteBuilder.buildHighFidelityMockRoute(
      start,
      end,
      minPoints: 80,
    );
  }

  Future<void> _publishSharedRide(RideRequest ride) async {
    const attempts = 2;
    Object? lastError;

    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        await RideService.publishRide(ride).timeout(const Duration(seconds: 5));
        return;
      } catch (error) {
        lastError = error;
        if (attempt < attempts - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
        }
      }
    }

    throw lastError ?? Exception('Could not publish ride');
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

      final boundsPoints = _previewRoutePoints.length > 1
          ? _previewRoutePoints
          : [pickupLatLng, LatLng(dropoff.latitude, dropoff.longitude)];
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(boundsPoints),
          padding: const EdgeInsets.fromLTRB(48, 48, 48, 48),
        ),
      );
    } catch (_) {
      // Ignore camera calls before map is fully attached.
    }
  }

  void _setDropoffFromMap(LatLng location) async {
    // Reverse geocode the tapped point for a real address
    final address = await GeocodingService.reverseGeocode(
      location.latitude,
      location.longitude,
    );
    if (!mounted) return;

    setState(() {
      _dropoff = LocationPoint(
        latitude: location.latitude,
        longitude: location.longitude,
        address: address,
      );
      _dropoffSearchController.text = address;
      _searchResults = [];
    });
    _focusRouteOrPickup();
    unawaited(_refreshPreviewRoute());
  }

  Future<void> _refreshPreviewRoute() async {
    final pickup = _pickup;
    final dropoff = _dropoff;
    final requestId = ++_previewRouteRequestId;

    if (pickup == null || dropoff == null) {
      if (!mounted) return;
      setState(() {
        _previewRoutePoints = const [];
        _isLoadingPreviewRoute = false;
      });
      return;
    }

    setState(() => _isLoadingPreviewRoute = true);

    final route = await TripRouteBuilder.buildRoadFirstRoute(
      LatLng(pickup.latitude, pickup.longitude),
      LatLng(dropoff.latitude, dropoff.longitude),
      minPoints: 80,
    );

    if (!mounted || requestId != _previewRouteRequestId) return;

    setState(() {
      _previewRoutePoints = route;
      _isLoadingPreviewRoute = false;
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
                      points: _previewRoutePoints.length > 1
                          ? _previewRoutePoints
                          : [
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
          if (_isLoadingPreviewRoute)
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading road route...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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

            // ── Pickup (GPS + real address) ──
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

            // ── Pickup (manual input option) ──
            Text(
              'Pickup Location',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(delay: 180.ms),
            const SizedBox(height: 8),
            _buildPickupSearchField().animate().fadeIn(delay: 220.ms),

            const SizedBox(height: 16),

            // ── Drop-off (search autocomplete) ──
            Text(
              'Drop-off Location',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            _buildDropoffSearchField().animate().fadeIn(delay: 300.ms),

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

  Widget _buildPickupSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _pickupSearchController,
          onChanged: _onPickupSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search pickup place (instead of current location)...',
            prefixIcon: const Icon(Icons.my_location, color: AppColors.info),
            suffixIcon: _isSearchingPickup
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _pickupSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _pickupSearchController.clear();
                      setState(() {
                        _pickupSearchResults = [];
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_pickupSearchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _pickupSearchResults.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 48),
              itemBuilder: (context, index) {
                final loc = _pickupSearchResults[index];
                return ListTile(
                  leading: const Icon(
                    Icons.place_rounded,
                    color: AppColors.info,
                    size: 22,
                  ),
                  title: Text(
                    loc.address,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  onTap: () => _selectPickup(loc),
                );
              },
            ),
          ),
      ],
    );
  }

  /// Search-based drop-off field with autocomplete results.
  Widget _buildDropoffSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _dropoffSearchController,
          onChanged: _onDropoffSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search for a place...',
            prefixIcon: const Icon(Icons.location_on, color: AppColors.danger),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _dropoffSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _dropoffSearchController.clear();
                      setState(() {
                        _dropoff = null;
                        _searchResults = [];
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 48),
              itemBuilder: (context, index) {
                final loc = _searchResults[index];
                return ListTile(
                  leading: const Icon(
                    Icons.place_rounded,
                    color: AppColors.danger,
                    size: 22,
                  ),
                  title: Text(
                    loc.address,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  onTap: () => _selectDropoff(loc),
                );
              },
            ),
          ),
      ],
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
