import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/models/ride_request_model.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/providers/gps_provider.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String tripId;

  const LiveTrackingScreen({super.key, required this.tripId});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  static const _maxTrailPoints = 450;

  final MapController _mapController = MapController();
  final ValueNotifier<_LiveVisualState> _liveVisualState = ValueNotifier(
    const _LiveVisualState(),
  );

  StreamSubscription<Position>? _positionSubscription;
  late final AnimationController _pulseController;

  bool _isPermissionDenied = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _startTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _pulseController.dispose();
    _liveVisualState.dispose();
    ref.read(gpsTrackingActiveProvider.notifier).state = false;
    super.dispose();
  }

  Future<void> _startTracking() async {
    final hasPermission = await GpsService.ensurePermission();
    if (!hasPermission) {
      if (!mounted) return;
      setState(() {
        _isPermissionDenied = true;
        _isLoading = false;
      });
      return;
    }

    Position? initialPosition;
    try {
      initialPosition = await GpsService.getCurrentPosition().timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {
      initialPosition = null;
    }

    final fallbackPosition = const LatLng(13.0827, 80.2707);
    final startingPosition = initialPosition == null
        ? fallbackPosition
        : LatLng(initialPosition.latitude, initialPosition.longitude);

    final initialHeading =
        (initialPosition?.heading.isFinite ?? false) &&
            (initialPosition?.heading ?? 0) >= 0
        ? initialPosition!.heading
        : 0.0;

    _liveVisualState.value = _LiveVisualState(
      currentPosition: startingPosition,
      headingDegrees: initialHeading,
      trail: [startingPosition],
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isPermissionDenied = false;
    });

    _positionSubscription?.cancel();
    _positionSubscription = GpsService.positionStream().listen(
      _handlePositionUpdate,
      onError: (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS stream error. Retrying updates...'),
          ),
        );
      },
    );

    ref.read(gpsTrackingActiveProvider.notifier).state = true;
  }

  void _handlePositionUpdate(Position position) {
    if (!mounted) return;

    final nextPosition = LatLng(position.latitude, position.longitude);
    final previousState = _liveVisualState.value;

    final updatedTrail = <LatLng>[...previousState.trail, nextPosition];
    if (updatedTrail.length > _maxTrailPoints) {
      updatedTrail.removeRange(0, updatedTrail.length - _maxTrailPoints);
    }

    final heading = (position.heading.isFinite && position.heading >= 0)
        ? position.heading
        : previousState.headingDegrees;

    _liveVisualState.value = previousState.copyWith(
      currentPosition: nextPosition,
      trail: updatedTrail,
      headingDegrees: heading,
    );

    _mapController.move(nextPosition, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    final isNightMode = ref.watch(effectiveNightModeProvider);
    final accentColor = isNightMode ? AppColors.nightAccent : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        actions: [
          ValueListenableBuilder<_LiveVisualState>(
            valueListenable: _liveVisualState,
            builder: (context, visualState, _) {
              final isGpsActive = visualState.currentPosition != null;
              final statusColor = isGpsActive
                  ? AppColors.success
                  : AppColors.danger;

              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGpsActive ? Icons.gps_fixed : Icons.gps_off,
                      color: statusColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isGpsActive ? 'GPS Active' : 'No GPS',
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Acquiring GPS signal...'),
                ],
              ),
            )
          : _isPermissionDenied
          ? _PermissionDeniedView(onRetry: _retryTracking)
          : _LiveMapView(
              mapController: _mapController,
              visualStateListenable: _liveVisualState,
              pulseController: _pulseController,
              accentColor: accentColor,
              isNightMode: isNightMode,
              rideRequest: ref.read(currentRideRequestProvider),
              onRecenter: _recenter,
            ),
    );
  }

  Future<void> _retryTracking() async {
    setState(() => _isLoading = true);
    await _startTracking();
  }

  void _recenter() {
    final position = _liveVisualState.value.currentPosition;
    if (position == null) return;
    _mapController.move(position, 16.0);
  }
}

class _LiveVisualState {
  final LatLng? currentPosition;
  final double headingDegrees;
  final List<LatLng> trail;

  const _LiveVisualState({
    this.currentPosition,
    this.headingDegrees = 0,
    this.trail = const [],
  });

  _LiveVisualState copyWith({
    LatLng? currentPosition,
    double? headingDegrees,
    List<LatLng>? trail,
  }) {
    return _LiveVisualState(
      currentPosition: currentPosition ?? this.currentPosition,
      headingDegrees: headingDegrees ?? this.headingDegrees,
      trail: trail ?? this.trail,
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _PermissionDeniedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_rounded,
              size: 80,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            Text(
              'Location Permission Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please enable location access in your browser to use live GPS tracking.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveMapView extends StatelessWidget {
  final MapController mapController;
  final ValueNotifier<_LiveVisualState> visualStateListenable;
  final AnimationController pulseController;
  final Color accentColor;
  final bool isNightMode;
  final RideRequest? rideRequest;
  final VoidCallback onRecenter;

  const _LiveMapView({
    required this.mapController,
    required this.visualStateListenable,
    required this.pulseController,
    required this.accentColor,
    required this.isNightMode,
    required this.rideRequest,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([visualStateListenable, pulseController]),
          builder: (context, _) {
            final state = visualStateListenable.value;
            final center =
                state.currentPosition ?? const LatLng(13.0827, 80.2707);
            final ride = rideRequest;

            return FlutterMap(
              mapController: mapController,
              options: MapOptions(initialCenter: center, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sharedcab.app',
                ),
                if (state.trail.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: state.trail,
                        color: accentColor.withValues(alpha: 0.9),
                        strokeWidth: 6,
                      ),
                    ],
                  ),
                if (state.currentPosition != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: state.currentPosition!,
                        radius: 10 + (pulseController.value * 22),
                        color: accentColor.withValues(
                          alpha: 0.2 * (1 - pulseController.value),
                        ),
                        borderStrokeWidth: 0,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (state.currentPosition != null)
                      Marker(
                        point: state.currentPosition!,
                        width: 54,
                        height: 54,
                        child: Transform.rotate(
                          angle: state.headingDegrees * math.pi / 180,
                          child: Container(
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.directions_car_rounded,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                    if (ride != null)
                      Marker(
                        point: LatLng(
                          ride.pickup.latitude,
                          ride.pickup.longitude,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.trip_origin,
                          color: AppColors.success,
                          size: 26,
                        ),
                      ),
                    if (ride != null)
                      Marker(
                        point: LatLng(
                          ride.dropoff.latitude,
                          ride.dropoff.longitude,
                        ),
                        width: 42,
                        height: 42,
                        child: const Icon(
                          Icons.hexagon_rounded,
                          color: AppColors.danger,
                          size: 30,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _LiveInfoPanel(
            accentColor: accentColor,
            isNightMode: isNightMode,
            visualStateListenable: visualStateListenable,
          ),
        ),

        Positioned(
          bottom: 180,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: onRecenter,
            backgroundColor: Colors.white,
            child: Icon(Icons.my_location_rounded, color: accentColor),
          ),
        ),
      ],
    );
  }
}

class _LiveInfoPanel extends StatelessWidget {
  final Color accentColor;
  final bool isNightMode;
  final ValueNotifier<_LiveVisualState> visualStateListenable;

  const _LiveInfoPanel({
    required this.accentColor,
    required this.isNightMode,
    required this.visualStateListenable,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_LiveVisualState>(
      valueListenable: visualStateListenable,
      builder: (context, state, _) {
        final coordinatesLabel = state.currentPosition == null
            ? 'Waiting for signal...'
            : '${state.currentPosition!.latitude.toStringAsFixed(6)}, ${state.currentPosition!.longitude.toStringAsFixed(6)}';

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: isNightMode
                ? AppColors.nightSurface
                : Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
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
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.satellite_alt_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live GPS Coordinates',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          coordinatesLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFamily: 'monospace',
                                color: accentColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timeline_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${state.trail.length}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.gpp_good_rounded,
                      color: AppColors.success,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GPS tracking active: live location is monitored for safety',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
