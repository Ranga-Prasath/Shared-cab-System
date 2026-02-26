import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/data/mock/mock_data.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/route_deviation_model.dart';
import 'package:shared_cab/models/trip_model.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/providers/gps_provider.dart';

import 'utils/trip_map_math.dart';
import 'utils/trip_route_builder.dart';

class TripStatusScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripStatusScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripStatusScreen> createState() => _TripStatusScreenState();
}

class _TripStatusScreenState extends ConsumerState<TripStatusScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  late final AnimationController _segmentController;
  late final AnimationController _pickupRippleController;

  final ValueNotifier<_TripVisualState> _visualState = ValueNotifier(
    const _TripVisualState(),
  );

  List<LatLng> _routePoints = const [];
  LatLng _pickupLatLng = const LatLng(13.0850, 80.2101);
  LatLng _dropoffLatLng = const LatLng(12.9516, 80.2413);

  double _segmentStartBearing = 0;
  double _segmentEndBearing = 0;
  bool _deviationTriggered = false;
  double _routeDistanceKm = 0;
  int _pickupRouteIndex = 0;
  LatLng? _riderCurrentLatLng;

  DateTime _lastCameraFrame = DateTime.fromMillisecondsSinceEpoch(0);
  StreamSubscription<Position>? _riderPositionSubscription;

  @override
  void initState() {
    super.initState();

    _segmentController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 780),
          )
          ..addListener(_onSegmentTick)
          ..addStatusListener(_onSegmentStatusChange);

    _pickupRippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _startRiderLocationTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareTripScene());
  }

  @override
  void dispose() {
    _segmentController
      ..removeListener(_onSegmentTick)
      ..removeStatusListener(_onSegmentStatusChange)
      ..dispose();
    _pickupRippleController.dispose();
    _riderPositionSubscription?.cancel();
    _visualState.dispose();
    super.dispose();
  }

  Future<void> _startRiderLocationTracking() async {
    final hasPermission = await GpsService.ensurePermission();
    if (!hasPermission) return;

    Position? initialPosition;
    try {
      initialPosition = await GpsService.getCurrentPosition().timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {
      initialPosition = null;
    }

    if (!mounted) return;

    if (initialPosition != null) {
      final firstFix = initialPosition;
      setState(() {
        _riderCurrentLatLng = LatLng(firstFix.latitude, firstFix.longitude);
      });
    }

    _riderPositionSubscription?.cancel();
    _riderPositionSubscription = GpsService.positionStream().listen((position) {
      if (!mounted) return;
      setState(() {
        _riderCurrentLatLng = LatLng(position.latitude, position.longitude);
      });
    });
  }

  Future<void> _prepareTripScene() async {
    ref.read(routeDeviationProvider.notifier).state = null;
    ref.read(deviationAlertDismissedProvider.notifier).state = false;

    final rideRequest = ref.read(currentRideRequestProvider);
    if (rideRequest != null) {
      _pickupLatLng = LatLng(
        rideRequest.pickup.latitude,
        rideRequest.pickup.longitude,
      );
      _dropoffLatLng = LatLng(
        rideRequest.dropoff.latitude,
        rideRequest.dropoff.longitude,
      );
    }

    final approachStart = _offsetPoint(
      _pickupLatLng,
      distanceMeters: 1800,
      bearingDegrees: 312,
    );
    final toPickup = await TripRouteBuilder.buildRoadFirstRoute(
      approachStart,
      _pickupLatLng,
      minPoints: 80,
    );
    final toDropoff = await TripRouteBuilder.buildRoadFirstRoute(
      _pickupLatLng,
      _dropoffLatLng,
      minPoints: 140,
    );
    _pickupRouteIndex = toPickup.length - 1;
    _routePoints = [...toPickup, ...toDropoff.skip(1)];

    if (_routePoints.isEmpty) {
      _routePoints = [_pickupLatLng, _dropoffLatLng];
      _pickupRouteIndex = 0;
    }

    _routeDistanceKm = TripRouteBuilder.estimatedDistanceKm(_routePoints);
    _deviationTriggered = false;

    if (_routePoints.length > 1) {
      _segmentStartBearing = TripMapMath.bearingBetween(
        _routePoints.first,
        _routePoints[1],
      );
      _segmentEndBearing = _segmentStartBearing;
    }

    _visualState.value = _TripVisualState(
      cabPosition: _routePoints.first,
      segmentIndex: 0,
      progress: 0,
      cabBearing: _segmentStartBearing,
    );

    _fitRouteBounds();

    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted || _routePoints.length < 2) return;

    _segmentController.forward(from: 0);
  }

  LatLng _offsetPoint(
    LatLng source, {
    required double distanceMeters,
    required double bearingDegrees,
  }) {
    const earthRadius = 6378137.0;
    final distanceRatio = distanceMeters / earthRadius;
    final bearing = bearingDegrees * math.pi / 180;
    final sourceLat = source.latitude * math.pi / 180;
    final sourceLng = source.longitude * math.pi / 180;

    final lat = math.asin(
      math.sin(sourceLat) * math.cos(distanceRatio) +
          math.cos(sourceLat) * math.sin(distanceRatio) * math.cos(bearing),
    );
    final lng =
        sourceLng +
        math.atan2(
          math.sin(bearing) * math.sin(distanceRatio) * math.cos(sourceLat),
          math.cos(distanceRatio) - math.sin(sourceLat) * math.sin(lat),
        );

    return LatLng(lat * 180 / math.pi, lng * 180 / math.pi);
  }

  void _onSegmentTick() {
    if (!mounted || _routePoints.length < 2) return;

    final state = _visualState.value;
    final safeSegment = state.segmentIndex.clamp(0, _routePoints.length - 2);

    final segmentStart = _routePoints[safeSegment];
    final segmentEnd = _routePoints[safeSegment + 1];
    final segmentT = _segmentController.value;

    final cabPosition = TripMapMath.lerpLatLng(
      segmentStart,
      segmentEnd,
      segmentT,
    );
    final cabBearing = TripMapMath.lerpBearing(
      _segmentStartBearing,
      _segmentEndBearing,
      segmentT,
    );
    final progress = ((safeSegment + segmentT) / (_routePoints.length - 1))
        .clamp(0.0, 1.0)
        .toDouble();

    _visualState.value = state.copyWith(
      cabPosition: cabPosition,
      progress: progress,
      cabBearing: cabBearing,
    );

    _updateTripMilestones(progress);
    _followCabCamera(cabPosition);
  }

  void _onSegmentStatusChange(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;

    final state = _visualState.value;

    if (state.segmentIndex >= _routePoints.length - 2) {
      _onTripArrived();
      return;
    }

    final nextIndex = state.segmentIndex + 1;
    _segmentStartBearing = _segmentEndBearing;
    _segmentEndBearing = TripMapMath.bearingBetween(
      _routePoints[nextIndex],
      _routePoints[nextIndex + 1],
    );

    _visualState.value = state.copyWith(segmentIndex: nextIndex);
    _segmentController.forward(from: 0);
  }

  void _updateTripMilestones(double progress) {
    final trip = ref.read(activeTripProvider);
    if (trip == null) return;

    final reachedPickup = _visualState.value.segmentIndex >= _pickupRouteIndex;

    if (reachedPickup && trip.status == TripStatus.waitingForPickup) {
      ref.read(activeTripProvider.notifier).state = trip.copyWith(
        status: TripStatus.inProgress,
      );
    }

    if (progress >= 0.72 && !_deviationTriggered) {
      _deviationTriggered = true;
      ref.read(routeDeviationProvider.notifier).state =
          MockData.getMockDeviation(trip.id);
      ref.read(deviationAlertDismissedProvider.notifier).state = false;
    }
  }

  void _onTripArrived() {
    final trip = ref.read(activeTripProvider);
    if (trip == null) return;

    final destination = _routePoints.isEmpty ? null : _routePoints.last;

    _visualState.value = _visualState.value.copyWith(
      progress: 1,
      cabPosition: destination,
    );

    ref.read(activeTripProvider.notifier).state = trip.copyWith(
      status: TripStatus.arrivedDestination,
    );
    ref.read(routeDeviationProvider.notifier).state = null;

    if (destination != null) {
      _followCabCamera(destination, force: true);
    }
  }

  void _followCabCamera(LatLng cabPosition, {bool force = false}) {
    final now = DateTime.now();
    if (!force &&
        now.difference(_lastCameraFrame) < const Duration(milliseconds: 110)) {
      return;
    }
    _lastCameraFrame = now;
    _mapController.move(cabPosition, 16.0);
  }

  void _fitRouteBounds() {
    final boundsPoints = <LatLng>[
      ..._routePoints,
      ...?_riderCurrentLatLng == null ? null : <LatLng>[_riderCurrentLatLng!],
    ];

    if (boundsPoints.length < 2) {
      _mapController.move(_riderCurrentLatLng ?? _pickupLatLng, 15.5);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(boundsPoints),
        padding: const EdgeInsets.fromLTRB(56, 120, 56, 310),
      ),
    );
  }

  void _dismissDeviation() {
    ref.read(deviationAlertDismissedProvider.notifier).state = true;
  }

  void _alertContacts() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text('Emergency contacts alerted with your live location'),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Polyline> _buildPolylines({
    required _TripVisualState state,
    required bool hasDeviation,
  }) {
    if (_routePoints.length < 2) return const [];

    final traveled = <LatLng>[..._routePoints.take(state.segmentIndex + 1)];
    if (state.cabPosition != null) traveled.add(state.cabPosition!);

    final upcoming = <LatLng>[
      ...state.cabPosition == null ? const [] : [state.cabPosition!],
      ..._routePoints.skip(state.segmentIndex + 1),
    ];

    final simulatedTraffic = <Polyline>[];
    if (!hasDeviation) {
      for (
        var i = state.segmentIndex + 8;
        i < _routePoints.length - 6;
        i += 22
      ) {
        final endIndex = (i + 6).clamp(0, _routePoints.length - 1);
        if (endIndex - i < 2) continue;

        simulatedTraffic.add(
          Polyline(
            points: _routePoints.sublist(i, endIndex),
            color: i.isEven ? AppColors.danger : AppColors.warning,
            strokeWidth: 7,
          ),
        );
      }
    }

    return [
      Polyline(
        points: _routePoints,
        color: Colors.black.withValues(alpha: 0.18),
        strokeWidth: 10,
      ),
      if (traveled.length > 1)
        Polyline(points: traveled, color: Colors.grey.shade500, strokeWidth: 7),
      if (upcoming.length > 1)
        Polyline(
          points: upcoming,
          color: hasDeviation ? AppColors.danger : const Color(0xFF0F3D91),
          strokeWidth: 8,
        ),
      ...simulatedTraffic,
    ];
  }

  List<CircleMarker> _buildCircles() {
    final pulse = _pickupRippleController.value;

    return [
      CircleMarker(
        point: _pickupLatLng,
        radius: 12 + (pulse * 28),
        color: AppColors.success.withValues(alpha: 0.20 * (1 - pulse)),
        borderStrokeWidth: 0,
      ),
      CircleMarker(
        point: _pickupLatLng,
        radius: 8,
        color: AppColors.success.withValues(alpha: 0.20),
        borderColor: AppColors.success,
        borderStrokeWidth: 1.4,
      ),
    ];
  }

  List<Marker> _buildMarkers({
    required _TripVisualState state,
    required bool hasDeviation,
    required bool isApproachingPickup,
  }) {
    return [
      Marker(
        point: _pickupLatLng,
        width: 110,
        height: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Text(
                'PICKUP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 2),
            const Icon(Icons.trip_origin, color: AppColors.success, size: 18),
          ],
        ),
      ),
      Marker(
        point: _dropoffLatLng,
        width: 86,
        height: 54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Text(
                'DROP',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.danger,
                ),
              ),
            ),
            const SizedBox(height: 1),
            const Icon(
              Icons.hexagon_rounded,
              color: AppColors.danger,
              size: 20,
            ),
          ],
        ),
      ),
      if (state.cabPosition != null)
        Marker(
          point: state.cabPosition!,
          width: 56,
          height: 56,
          child: Transform.rotate(
            angle: state.cabBearing * math.pi / 180,
            child: Container(
              decoration: BoxDecoration(
                color: hasDeviation ? AppColors.danger : AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: (hasDeviation ? AppColors.danger : AppColors.primary)
                        .withValues(alpha: 0.40),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      if (_riderCurrentLatLng != null)
        Marker(
          point: _riderCurrentLatLng!,
          width: 46,
          height: 46,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              isApproachingPickup
                  ? Icons.person_pin_circle_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(activeTripProvider);
    final rideRequest = ref.watch(currentRideRequestProvider);
    final isNight = ref.watch(effectiveNightModeProvider);
    final deviation = ref.watch(routeDeviationProvider);
    final isDeviationDismissed = ref.watch(deviationAlertDismissedProvider);

    if (trip == null) {
      return const Scaffold(body: Center(child: Text('No active trip')));
    }

    final hasDeviationBanner = deviation != null && !isDeviationDismissed;
    final primaryAccent = isNight ? AppColors.nightAccent : AppColors.primary;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([
              _visualState,
              _pickupRippleController,
            ]),
            builder: (context, _) {
              final state = _visualState.value;
              final isApproachingPickup =
                  state.segmentIndex < _pickupRouteIndex;
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _pickupLatLng,
                  initialZoom: 14.2,
                  onMapReady: _fitRouteBounds,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sharedcab.app',
                  ),
                  if (_routePoints.length > 1)
                    PolylineLayer(
                      polylines: _buildPolylines(
                        state: state,
                        hasDeviation: hasDeviationBanner,
                      ),
                    ),
                  CircleLayer(circles: _buildCircles()),
                  MarkerLayer(
                    markers: _buildMarkers(
                      state: state,
                      hasDeviation: hasDeviationBanner,
                      isApproachingPickup: isApproachingPickup,
                    ),
                  ),
                ],
              );
            },
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: ValueListenableBuilder<_TripVisualState>(
              valueListenable: _visualState,
              builder: (context, state, _) => _TripTopBar(
                trip: trip,
                progress: state.progress,
                onBack: () => context.goNamed('home'),
              ),
            ),
          ),

          if (hasDeviationBanner)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 12,
              right: 12,
              child: _DeviationBanner(
                deviation: deviation,
                onAlertContacts: _alertContacts,
                onDismiss: _dismissDeviation,
              ),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<_TripVisualState>(
              valueListenable: _visualState,
              builder: (context, state, _) {
                final pickupFraction = _pickupRouteIndex <= 0
                    ? 0.0
                    : (((_pickupRouteIndex - state.segmentIndex) -
                                      state.progress)
                                  .clamp(0.0, _pickupRouteIndex.toDouble()) /
                              _pickupRouteIndex)
                          .toDouble();
                final isApproachingPickup =
                    state.segmentIndex < _pickupRouteIndex;
                final pickupEtaMin = (1 + (pickupFraction * 8)).round();
                final destinationEtaMin = (1 + ((1 - state.progress) * 12))
                    .clamp(1, 12)
                    .round();

                return _TripBottomSheet(
                  trip: trip,
                  rideRequest: rideRequest,
                  isNight: isNight,
                  accentColor: primaryAccent,
                  progress: state.progress,
                  routeDistanceKm: _routeDistanceKm,
                  isApproachingPickup: isApproachingPickup,
                  pickupEtaMin: pickupEtaMin,
                  destinationEtaMin: destinationEtaMin,
                );
              },
            ),
          ),

          Positioned(
            bottom: 280,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _fitRouteBounds,
              heroTag: 'trip_recenter',
              backgroundColor: Colors.white,
              child: Icon(Icons.zoom_out_map_rounded, color: primaryAccent),
            ),
          ),
          Positioned(
            bottom: 336,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: () {
                final riderLocation = _riderCurrentLatLng;
                if (riderLocation != null) {
                  _mapController.move(riderLocation, 16.0);
                }
              },
              heroTag: 'trip_my_location',
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location_rounded, color: primaryAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripVisualState {
  final LatLng? cabPosition;
  final int segmentIndex;
  final double progress;
  final double cabBearing;

  const _TripVisualState({
    this.cabPosition,
    this.segmentIndex = 0,
    this.progress = 0,
    this.cabBearing = 0,
  });

  _TripVisualState copyWith({
    LatLng? cabPosition,
    int? segmentIndex,
    double? progress,
    double? cabBearing,
  }) {
    return _TripVisualState(
      cabPosition: cabPosition ?? this.cabPosition,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      progress: progress ?? this.progress,
      cabBearing: cabBearing ?? this.cabBearing,
    );
  }
}

class _TripTopBar extends StatelessWidget {
  final Trip trip;
  final double progress;
  final VoidCallback onBack;

  const _TripTopBar({
    required this.trip,
    required this.progress,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (trip.status) {
      TripStatus.waitingForPickup => ('Waiting for Pickup', AppColors.warning),
      TripStatus.inProgress => ('Ride in Progress', AppColors.success),
      TripStatus.arrivedDestination => ('Arrived', AppColors.primary),
      _ => ('Trip', AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusLabel,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: statusColor,
                fontSize: 15,
              ),
            ),
          ),
          if (trip.isNightTrip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 10),
          Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviationBanner extends StatelessWidget {
  final RouteDeviation deviation;
  final VoidCallback onAlertContacts;
  final VoidCallback onDismiss;

  const _DeviationBanner({
    required this.deviation,
    required this.onAlertContacts,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.danger,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Route deviation: ${deviation.deviationDistanceKm.toStringAsFixed(1)} km off route',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAlertContacts,
                  icon: const Icon(Icons.sos_rounded, size: 16),
                  label: const Text(
                    'Alert Contacts',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripBottomSheet extends StatelessWidget {
  final Trip trip;
  final RideRequest? rideRequest;
  final bool isNight;
  final Color accentColor;
  final double progress;
  final double routeDistanceKm;
  final bool isApproachingPickup;
  final int pickupEtaMin;
  final int destinationEtaMin;

  const _TripBottomSheet({
    required this.trip,
    required this.rideRequest,
    required this.isNight,
    required this.accentColor,
    required this.progress,
    required this.routeDistanceKm,
    required this.isApproachingPickup,
    required this.pickupEtaMin,
    required this.destinationEtaMin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isNight ? AppColors.nightSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, size: 10, color: AppColors.success),
                  Container(width: 1.5, height: 28, color: AppColors.divider),
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppColors.danger,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rideRequest?.pickup.address ?? 'Pickup Location',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      rideRequest?.dropoff.address ?? 'Drop-off Location',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trip.farePerPerson != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'INR ${trip.farePerPerson!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        'per head',
                        style: TextStyle(
                          fontSize: 10,
                          color: accentColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          if (isApproachingPickup)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_taxi_rounded,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Driver is on the way to pickup ($pickupEtaMin min)',
                      style: const TextStyle(
                        color: AppColors.info,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (isApproachingPickup) const SizedBox(height: 14),

          Row(
            children: [
              _InfoChip(
                icon: Icons.straighten_rounded,
                label:
                    '${(trip.tripDistanceKm ?? routeDistanceKm).toStringAsFixed(1)} km',
                color: AppColors.info,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label:
                    '${isApproachingPickup ? pickupEtaMin : destinationEtaMin} min',
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.people_outline_rounded,
                label: '${trip.riderIds.length}',
                color: AppColors.success,
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.pushNamed(
                    'liveTracking',
                    pathParameters: {'tripId': trip.id},
                  ),
                  icon: const Icon(Icons.satellite_alt_rounded, size: 16),
                  label: const Text('GPS', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentColor,
                    side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (trip.isNightTrip || isNight)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.pushNamed('panic'),
                    icon: const Icon(Icons.sos_rounded, size: 16),
                    label: const Text('SOS', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              if (trip.isNightTrip || isNight) const SizedBox(width: 8),
              if (trip.status == TripStatus.arrivedDestination)
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (trip.isNightTrip || isNight) {
                        context.goNamed(
                          'safeArrival',
                          pathParameters: {'tripId': trip.id},
                        );
                      } else {
                        context.goNamed(
                          'tripComplete',
                          pathParameters: {'tripId': trip.id},
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      trip.isNightTrip || isNight
                          ? 'Safe Arrival'
                          : 'Complete Trip',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
