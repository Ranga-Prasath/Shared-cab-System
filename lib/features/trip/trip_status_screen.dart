import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_cab/core/services/auth_service.dart';
import 'package:shared_cab/core/services/ride_service.dart';
import 'package:shared_cab/core/session/ride_session_controller.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/models/route_deviation_model.dart';
import 'package:shared_cab/models/location_model.dart';
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
  late final AnimationController _remoteSyncController;

  final ValueNotifier<_TripVisualState> _visualState = ValueNotifier(
    const _TripVisualState(),
  );

  List<LatLng> _routePoints = const [];
  LatLng _pickupLatLng = const LatLng(13.0850, 80.2101);
  LatLng _dropoffLatLng = const LatLng(12.9516, 80.2413);
  List<LatLng> _coRiderPickupLatLngs = const [];
  List<String> _orderedPickupAddresses = const [];

  double _segmentStartBearing = 0;
  double _segmentEndBearing = 0;
  bool _deviationTriggered = false;
  double _routeDistanceKm = 0;
  int _pickupRouteIndex = 0;
  LatLng? _riderCurrentLatLng;
  StreamSubscription<RideRequest?>? _rideSyncSubscription;
  bool _isPrimaryTripDriver = false;
  bool _isMapExpanded = false;
  String? _syncRideId;
  DateTime _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(0);
  int? _lastRemoteSyncAtMs;
  _RemoteSyncSnapshot? _remoteSyncStart;
  _RemoteSyncSnapshot? _remoteSyncTarget;

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
    _remoteSyncController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..addListener(_onRemoteSyncTick);

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
    _remoteSyncController
      ..removeListener(_onRemoteSyncTick)
      ..dispose();
    _riderPositionSubscription?.cancel();
    _rideSyncSubscription?.cancel();
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

    final localRideRequest = ref.read(currentRideRequestProvider);
    if (localRideRequest != null) {
      _pickupLatLng = LatLng(
        localRideRequest.pickup.latitude,
        localRideRequest.pickup.longitude,
      );
      _dropoffLatLng = LatLng(
        localRideRequest.dropoff.latitude,
        localRideRequest.dropoff.longitude,
      );
    }

    final syncAvailable = Firebase.apps.isNotEmpty;
    final canonicalRideId = syncAvailable
        ? _resolveSyncRideId(ref.read(activeTripProvider))
        : null;
    final canonicalRide = canonicalRideId == null
        ? null
        : await RideService.getRide(canonicalRideId);
    final routeRide = canonicalRide ?? localRideRequest;
    if (canonicalRide != null) {
      _pickupLatLng = LatLng(
        canonicalRide.pickup.latitude,
        canonicalRide.pickup.longitude,
      );
      _dropoffLatLng = LatLng(
        canonicalRide.dropoff.latitude,
        canonicalRide.dropoff.longitude,
      );
    }

    final hostPickupLatLng = _pickupLatLng;
    final pickupAddressByKey = <String, String>{
      _pickupKey(hostPickupLatLng):
          routeRide?.pickup.address ??
          localRideRequest?.pickup.address ??
          'Pickup Location',
    };

    final acceptedPickupWaypoints = routeRide == null
        ? const <LatLng>[]
        : [
            for (final pickupStop in routeRide.acceptedPickupStops)
              () {
                final pickupPoint = LatLng(
                  pickupStop.latitude,
                  pickupStop.longitude,
                );
                pickupAddressByKey[_pickupKey(pickupPoint)] =
                    pickupStop.address;
                return pickupPoint;
              }(),
          ];
    final pickupWaypoints = TripRouteBuilder.orderPickupWaypoints(
      hostPickup: hostPickupLatLng,
      coRiderPickups: acceptedPickupWaypoints,
      destination: _dropoffLatLng,
    );
    _orderedPickupAddresses = pickupWaypoints
        .map((pickupPoint) => pickupAddressByKey[_pickupKey(pickupPoint)])
        .whereType<String>()
        .toList();
    _pickupLatLng = pickupWaypoints.first;
    _coRiderPickupLatLngs = pickupWaypoints.skip(1).toList();

    final approachStart = _offsetPoint(
      _pickupLatLng,
      distanceMeters: 1800,
      bearingDegrees: 312,
    );

    final toPickup = await TripRouteBuilder.buildRoadFirstRoute(
      approachStart,
      pickupWaypoints.first,
      minPoints: 80,
    );

    final toDropoff = await _buildRouteThroughWaypoints(
      pickupWaypoints,
      _dropoffLatLng,
    );

    _pickupRouteIndex = (toPickup.length - 1) + toDropoff.finalPickupRouteIndex;
    _routePoints = [...toPickup, ...toDropoff.points.skip(1)];

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

    await _setupTripSync();
    _fitRouteBounds();

    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted || _routePoints.length < 2) return;

    if (_isPrimaryTripDriver) {
      _segmentController.forward(from: 0);
    }
  }

  String _pickupKey(LatLng point) {
    return '${point.latitude.toStringAsFixed(5)}|${point.longitude.toStringAsFixed(5)}';
  }

  Future<_WaypointRouteResult> _buildRouteThroughWaypoints(
    List<LatLng> pickups,
    LatLng destination,
  ) async {
    if (pickups.isEmpty) {
      return _WaypointRouteResult(
        points: [destination],
        finalPickupRouteIndex: 0,
      );
    }
    final route = <LatLng>[pickups.first];
    var current = pickups.first;
    var finalPickupRouteIndex = 0;

    for (var i = 1; i < pickups.length; i++) {
      final segment = await TripRouteBuilder.buildRoadFirstRoute(
        current,
        pickups[i],
        minPoints: 70,
      );
      route.addAll(segment.skip(1));
      current = pickups[i];
      finalPickupRouteIndex = route.length - 1;
    }

    final destinationSegment = await TripRouteBuilder.buildRoadFirstRoute(
      current,
      destination,
      minPoints: 140,
    );
    route.addAll(destinationSegment.skip(1));
    return _WaypointRouteResult(
      points: route,
      finalPickupRouteIndex: finalPickupRouteIndex,
    );
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
    if (!mounted || _routePoints.length < 2 || !_isPrimaryTripDriver) return;

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
    final segmentProgress = segmentT.clamp(0.0, 1.0).toDouble();
    final now = DateTime.now();
    if (now.difference(_lastSyncTime) > const Duration(milliseconds: 1500)) {
      _lastSyncTime = now;
      unawaited(
        _broadcastCabSyncState(
          cabPosition: cabPosition,
          segmentIndex: safeSegment,
          segmentProgress: segmentProgress,
          cabBearing: cabBearing,
        ),
      );
    }

    _updateTripMilestones(progress);
    _updateRouteDeviation(cabPosition);
    _followCabCamera(cabPosition);
  }

  void _onSegmentStatusChange(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        !mounted ||
        !_isPrimaryTripDriver) {
      return;
    }

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

  void _onRemoteSyncTick() {
    if (!mounted ||
        _isPrimaryTripDriver ||
        _routePoints.length < 2 ||
        _remoteSyncStart == null ||
        _remoteSyncTarget == null) {
      return;
    }

    final startSnapshot = _remoteSyncStart!;
    final targetSnapshot = _remoteSyncTarget!;
    final t = Curves.linear.transform(_remoteSyncController.value);
    final routeScalar =
        startSnapshot.routeScalar +
        ((targetSnapshot.routeScalar - startSnapshot.routeScalar) * t);
    final frame = TripMapMath.routeFrameFromScalar(
      routeScalar: routeScalar,
      pointCount: _routePoints.length,
    );
    final position = TripMapMath.lerpLatLng(
      startSnapshot.position,
      targetSnapshot.position,
      t,
    );
    final bearing = TripMapMath.lerpBearing(
      startSnapshot.bearing,
      targetSnapshot.bearing,
      t,
    );

    _visualState.value = _visualState.value.copyWith(
      cabPosition: position,
      segmentIndex: frame.segmentIndex,
      progress: frame.overallProgress,
      cabBearing: bearing,
    );
    _followCabCamera(position);
  }

  void _updateTripMilestones(double progress) {
    if (!_isPrimaryTripDriver) return;
    final trip = ref.read(activeTripProvider);
    if (trip == null) return;

    final reachedPickup = _visualState.value.segmentIndex >= _pickupRouteIndex;

    if (reachedPickup && trip.status == TripStatus.waitingForPickup) {
      RideSessionController.markTripInProgress(RideSessionStore.widget(ref));
      if (_isPrimaryTripDriver && _syncRideId != null) {
        unawaited(
          RideService.updateRideStatus(_syncRideId!, RideStatus.active),
        );
      }
    }
  }

  void _updateRouteDeviation(LatLng actualPosition) {
    if (_routePoints.isEmpty) return;

    LatLng nearestPoint = _routePoints.first;
    var minDistanceKm = TripMapMath.distanceKmBetween(
      actualPosition,
      nearestPoint,
    );

    for (final point in _routePoints.skip(1)) {
      final distanceKm = TripMapMath.distanceKmBetween(actualPosition, point);
      if (distanceKm < minDistanceKm) {
        minDistanceKm = distanceKm;
        nearestPoint = point;
      }
    }

    if (minDistanceKm <= 1.0) {
      if (_deviationTriggered) {
        _deviationTriggered = false;
        ref.read(routeDeviationProvider.notifier).state = null;
      }
      return;
    }

    if (_deviationTriggered) return;

    _deviationTriggered = true;
    final trip = ref.read(activeTripProvider);
    if (trip == null) return;

    final severity = minDistanceKm >= 2
        ? DeviationSeverity.high
        : minDistanceKm >= 1.5
        ? DeviationSeverity.medium
        : DeviationSeverity.low;

    ref.read(routeDeviationProvider.notifier).state = RouteDeviation(
      tripId: trip.id,
      deviationDistanceKm: minDistanceKm,
      expectedLocation: LocationPoint(
        latitude: nearestPoint.latitude,
        longitude: nearestPoint.longitude,
        address: 'Expected route location',
      ),
      actualLocation: LocationPoint(
        latitude: actualPosition.latitude,
        longitude: actualPosition.longitude,
        address: 'Current cab location',
      ),
      detectedAt: DateTime.now(),
      severity: severity,
    );
    ref.read(deviationAlertDismissedProvider.notifier).state = false;
  }

  void _onTripArrived() {
    final trip = ref.read(activeTripProvider);
    if (trip == null) return;

    final destination = _routePoints.isEmpty ? null : _routePoints.last;

    _visualState.value = _visualState.value.copyWith(
      progress: 1,
      cabPosition: destination,
    );

    RideSessionController.markTripArrived(RideSessionStore.widget(ref));
    ref.read(routeDeviationProvider.notifier).state = null;

    if (destination != null) {
      _followCabCamera(destination, force: true);
    }

    if (_isPrimaryTripDriver && _syncRideId != null) {
      unawaited(
        RideService.updateRideStatus(_syncRideId!, RideStatus.completed),
      );
    }
  }

  Future<void> _setupTripSync() async {
    _rideSyncSubscription?.cancel();
    final trip = ref.read(activeTripProvider);
    final rideId = _resolveSyncRideId(trip);
    _syncRideId = rideId;
    if (rideId == null || Firebase.apps.isEmpty) {
      _isPrimaryTripDriver = true;
      _remoteSyncController.stop();
      return;
    }

    final currentUid = AuthService.currentUserId;
    final providerUserId = ref.read(currentUserProvider)?.id;
    final effectiveUserId = ref.read(effectiveCurrentUserProvider).id;
    final ride = await RideService.getRide(rideId);
    final localUserIds = <String>{
      if (currentUid != null && currentUid.isNotEmpty) currentUid,
      if (providerUserId != null && providerUserId.isNotEmpty) providerUserId,
      if (effectiveUserId.isNotEmpty) effectiveUserId,
    };
    _isPrimaryTripDriver = ride == null
        ? true
        : localUserIds.contains(ride.userId);
    if (_isPrimaryTripDriver) {
      _remoteSyncController.stop();
      _remoteSyncStart = null;
      _remoteSyncTarget = null;
      return;
    }

    _rideSyncSubscription = RideService.rideStream(rideId).listen((rideUpdate) {
      if (!mounted || rideUpdate == null || _isPrimaryTripDriver) return;
      _applyRemoteCabSync(rideUpdate);
    });
  }

  String? _resolveSyncRideId(Trip? trip) {
    final request = ref.read(currentRideRequestProvider);
    final matchId = trip?.matchId ?? '';
    if (matchId.startsWith('direct_') || matchId.startsWith('shared_')) {
      final parts = matchId.split('_');
      if (parts.length >= 2) {
        return parts.sublist(1).join('_');
      }
    }
    return request?.id;
  }

  void _applyRemoteCabSync(RideRequest rideUpdate) {
    final remoteLat = rideUpdate.cabLat;
    final remoteLng = rideUpdate.cabLng;
    if (remoteLat == null || remoteLng == null || _routePoints.length < 2) {
      return;
    }

    final currentUpdateAtMs =
        rideUpdate.cabUpdatedAt ?? DateTime.now().millisecondsSinceEpoch;
    final previousUpdateAtMs = _lastRemoteSyncAtMs;
    if (previousUpdateAtMs != null && currentUpdateAtMs <= previousUpdateAtMs) {
      return;
    }

    final segmentIndex = (rideUpdate.cabSegmentIndex ?? 0).clamp(
      0,
      _routePoints.length - 2,
    );
    final segmentProgress = (rideUpdate.cabSegmentProgress ?? 0.0)
        .clamp(0.0, 1.0)
        .toDouble();
    final routeScalar = TripMapMath.routeScalarFromSegment(
      segmentIndex: segmentIndex,
      segmentProgress: segmentProgress,
      pointCount: _routePoints.length,
    );
    final routeProgress = TripMapMath.routeFrameFromScalar(
      routeScalar: routeScalar,
      pointCount: _routePoints.length,
    ).overallProgress;
    final cabBearing =
        rideUpdate.cabBearing ??
        TripMapMath.bearingBetween(
          _routePoints[segmentIndex],
          _routePoints[segmentIndex + 1],
        );

    _segmentStartBearing = TripMapMath.bearingBetween(
      _routePoints[segmentIndex],
      _routePoints[segmentIndex + 1],
    );
    _segmentEndBearing = _segmentStartBearing;

    final remotePosition = LatLng(remoteLat, remoteLng);
    final targetSnapshot = _RemoteSyncSnapshot(
      position: remotePosition,
      routeScalar: routeScalar,
      bearing: cabBearing,
    );
    final currentState = _visualState.value;
    final currentPosition = currentState.cabPosition;
    final currentScalar = TripMapMath.routeScalarFromProgress(
      overallProgress: currentState.progress,
      pointCount: _routePoints.length,
    );

    if (currentPosition == null) {
      _visualState.value = currentState.copyWith(
        cabPosition: remotePosition,
        segmentIndex: segmentIndex,
        progress: routeProgress,
        cabBearing: cabBearing,
      );
    } else {
      final startSnapshot = _RemoteSyncSnapshot(
        position: currentPosition,
        routeScalar: currentScalar,
        bearing: currentState.cabBearing,
      );
      final scalarDelta =
          (targetSnapshot.routeScalar - startSnapshot.routeScalar).abs();
      final distanceDeltaKm = TripMapMath.distanceKmBetween(
        startSnapshot.position,
        targetSnapshot.position,
      );

      if (scalarDelta < 0.01 && distanceDeltaKm < 0.005) {
        _visualState.value = currentState.copyWith(
          cabPosition: remotePosition,
          segmentIndex: segmentIndex,
          progress: routeProgress,
          cabBearing: cabBearing,
        );
      } else {
        _remoteSyncStart = startSnapshot;
        _remoteSyncTarget = targetSnapshot;
        _remoteSyncController
          ..stop()
          ..duration = TripMapMath.recommendedRemoteSyncDuration(
            previousUpdateAtMs: previousUpdateAtMs,
            currentUpdateAtMs: currentUpdateAtMs,
          )
          ..forward(from: 0);
      }
    }

    _lastRemoteSyncAtMs = currentUpdateAtMs;
    _updateRouteDeviation(remotePosition);
    if (!_remoteSyncController.isAnimating) {
      _followCabCamera(remotePosition);
    }

    if (rideUpdate.status == RideStatus.active) {
      RideSessionController.syncRemoteRideStatus(
        RideSessionStore.widget(ref),
        rideUpdate.status,
      );
    } else if (rideUpdate.status == RideStatus.completed) {
      RideSessionController.syncRemoteRideStatus(
        RideSessionStore.widget(ref),
        rideUpdate.status,
      );
    }
  }

  Future<void> _broadcastCabSyncState({
    required LatLng cabPosition,
    required int segmentIndex,
    required double segmentProgress,
    required double cabBearing,
  }) async {
    final rideId = _syncRideId;
    if (rideId == null) return;
    await RideService.updateCabSyncState(
      rideId: rideId,
      cabPosition: cabPosition,
      segmentIndex: segmentIndex,
      segmentProgress: segmentProgress,
      bearingDegrees: cabBearing,
    );
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

  Future<void> _toggleExpandedMap() async {
    setState(() {
      _isMapExpanded = !_isMapExpanded;
    });

    // WHY: wait for the scaffold to settle before refitting bounds, otherwise
    // the old bottom-sheet padding is still applied to the camera fit.
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    _fitRouteBounds();
  }

  Future<void> _centerMapOnLiveLocation() async {
    final cachedRiderLocation = _riderCurrentLatLng;
    if (cachedRiderLocation != null) {
      _mapController.move(cachedRiderLocation, 16.0);
      _showMapMessage('Centered on your live location');
      return;
    }

    try {
      final currentPosition = await GpsService.getCurrentPosition().timeout(
        const Duration(seconds: 3),
      );
      if (!mounted) return;
      if (currentPosition != null) {
        final liveLocation = LatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        );
        setState(() {
          _riderCurrentLatLng = liveLocation;
        });
        _mapController.move(liveLocation, 16.0);
        _showMapMessage('Centered on your live location');
        return;
      }
    } catch (_) {
      // Fall through to the next best live target for demo stability.
    }

    final cabLocation = _visualState.value.cabPosition;
    if (cabLocation != null) {
      _mapController.move(cabLocation, 16.0);
      _showMapMessage('Centered on the live cab');
      return;
    }

    _fitRouteBounds();
    _showMapMessage('Showing the full trip route');
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
        padding: EdgeInsets.fromLTRB(56, 120, 56, _isMapExpanded ? 72 : 310),
      ),
    );
  }

  void _showMapMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _dismissDeviation() {
    ref.read(deviationAlertDismissedProvider.notifier).state = true;
  }

  void _alertContacts() {
    if (!mounted) return;
    context.pushNamed('panic');
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
      for (final pickup in _coRiderPickupLatLngs)
        CircleMarker(
          point: pickup,
          radius: 7,
          color: AppColors.warning.withValues(alpha: 0.18),
          borderColor: AppColors.warning,
          borderStrokeWidth: 1.2,
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
      for (var index = 0; index < _coRiderPickupLatLngs.length; index++)
        Marker(
          point: _coRiderPickupLatLngs[index],
          width: 120,
          height: 60,
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
                child: Text(
                  'PICKUP ${index + 2}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Icon(Icons.trip_origin, color: AppColors.warning, size: 18),
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

          if (!_isMapExpanded)
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
                    pickupAddress: _orderedPickupAddresses.isNotEmpty
                        ? _orderedPickupAddresses.first
                        : rideRequest?.pickup.address ?? 'Pickup Location',
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
            bottom: _isMapExpanded ? 24 : 280,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _toggleExpandedMap,
              heroTag: 'trip_recenter',
              tooltip: _isMapExpanded ? 'Exit full screen map' : 'Expand map',
              backgroundColor: Colors.white,
              child: Icon(
                _isMapExpanded
                    ? Icons.fullscreen_exit_rounded
                    : Icons.zoom_out_map_rounded,
                color: primaryAccent,
              ),
            ),
          ),
          Positioned(
            bottom: _isMapExpanded ? 80 : 336,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _centerMapOnLiveLocation,
              heroTag: 'trip_my_location',
              tooltip: 'Center on live position',
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location_rounded, color: primaryAccent),
            ),
          ),
          if (_isMapExpanded)
            Positioned(
              left: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Text(
                  'Full map mode',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
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
                    'Open SOS',
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
  final String pickupAddress;
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
    required this.pickupAddress,
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
                      pickupAddress,
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

class _WaypointRouteResult {
  final List<LatLng> points;
  final int finalPickupRouteIndex;

  const _WaypointRouteResult({
    required this.points,
    required this.finalPickupRouteIndex,
  });
}

class _RemoteSyncSnapshot {
  final LatLng position;
  final double routeScalar;
  final double bearing;

  const _RemoteSyncSnapshot({
    required this.position,
    required this.routeScalar,
    required this.bearing,
  });
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
