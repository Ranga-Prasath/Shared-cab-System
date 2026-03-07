// -- Shared Cab System --
// Trip Complete Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TripCompleteScreen extends ConsumerWidget {
  final String tripId;

  const TripCompleteScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(activeTripProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.savingsGradientStart,
                      AppColors.savingsGradientEnd,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ).animate().scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
              const SizedBox(height: 24),
              Text(
                'Trip Complete!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 24),
              // Trip summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SummaryRow(
                        icon: Icons.straighten_rounded,
                        label: 'Distance',
                        value:
                            '${trip?.tripDistanceKm?.toStringAsFixed(1) ?? '14.2'} km',
                      ),
                      const Divider(height: 20),
                      _SummaryRow(
                        icon: Icons.currency_rupee_rounded,
                        label: 'Your fare',
                        value:
                            'INR ${trip?.farePerPerson?.toStringAsFixed(0) ?? '120'}',
                      ),
                      const Divider(height: 20),
                      _SummaryRow(
                        icon: Icons.savings_rounded,
                        label: 'You saved',
                        value: 'INR 240',
                        valueColor: AppColors.success,
                      ),
                      const Divider(height: 20),
                      _SummaryRow(
                        icon: Icons.people_outline_rounded,
                        label: 'Co-riders',
                        value: '${(trip?.riderIds.length ?? 3) - 1}',
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (trip != null) {
                      archiveTripToHistory(ref, trip);
                    }
                    context.goNamed(
                      'rating',
                      pathParameters: {'tripId': tripId},
                    );
                  },
                  icon: const Icon(Icons.star_outline_rounded),
                  label: const Text('Rate Your Ride'),
                ),
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  if (trip != null) {
                    archiveTripToHistory(ref, trip);
                  }
                  ref.read(activeTripProvider.notifier).state = null;
                  ref.read(panicModeProvider.notifier).state = false;
                  context.goNamed('home');
                },
                child: const Text('Skip & Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
