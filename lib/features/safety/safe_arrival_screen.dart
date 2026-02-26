// -- Shared Cab System --
// Safe Arrival PIN Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/models/trip_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SafeArrivalScreen extends ConsumerStatefulWidget {
  final String tripId;

  const SafeArrivalScreen({super.key, required this.tripId});

  @override
  ConsumerState<SafeArrivalScreen> createState() => _SafeArrivalScreenState();
}

class _SafeArrivalScreenState extends ConsumerState<SafeArrivalScreen> {
  final _pinController = TextEditingController();
  String? _error;
  bool _verified = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPin() {
    final trip = ref.read(activeTripProvider);
    if (trip == null) return;

    if (_pinController.text == trip.safeArrivalPin) {
      setState(() {
        _verified = true;
        _error = null;
      });

      final completedTrip = trip.copyWith(
        isPinConfirmed: true,
        status: TripStatus.completed,
        endTime: DateTime.now(),
      );
      ref.read(activeTripProvider.notifier).state = completedTrip;
      archiveTripToHistory(ref, completedTrip);

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        context.goNamed(
          'tripComplete',
          pathParameters: {'tripId': widget.tripId},
        );
      });
    } else {
      setState(() => _error = 'Incorrect PIN. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(activeTripProvider);

    return Scaffold(
      backgroundColor: AppColors.nightPrimary,
      appBar: AppBar(
        title: const Text('Safe Arrival'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _verified
                    ? Icons.verified_user_rounded
                    : Icons.shield_moon_rounded,
                size: 72,
                color: _verified ? AppColors.success : AppColors.nightMoon,
              ).animate().fadeIn().scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
              ),
              const SizedBox(height: 24),
              Text(
                _verified ? 'Safe Arrival Confirmed!' : 'Confirm Safe Arrival',
                style: TextStyle(
                  color: _verified ? AppColors.success : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              Text(
                _verified
                    ? 'Your emergency contacts have been notified'
                    : 'Enter the 4-digit PIN shared with you',
                style: const TextStyle(color: Colors.white60, fontSize: 14),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 8),
              if (trip?.safeArrivalPin != null && !_verified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Demo PIN: ${trip!.safeArrivalPin}',
                    style: const TextStyle(
                      color: AppColors.info,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 32),
              if (!_verified) ...[
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 4,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 12,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '* * * *',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        letterSpacing: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.nightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.nightMoon,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 14,
                    ),
                  ).animate().shakeX(),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifyPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.nightMoon,
                      foregroundColor: AppColors.nightPrimary,
                    ),
                    child: const Text('Verify PIN'),
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
