// -- Shared Cab System --
// Rating Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String tripId;

  const RatingScreen({super.key, required this.tripId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _rating = 0;
  bool _submitted = false;

  void _submit() {
    if (_rating == 0) return;
    setState(() => _submitted = true);
    final trip = ref.read(activeTripProvider);
    if (trip != null) {
      archiveTripToHistory(ref, trip);
    }
    ref.read(activeTripProvider.notifier).state = null;
    ref.read(panicModeProvider.notifier).state = false;

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      context.goNamed('home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_submitted) ...[
                const Icon(
                  Icons.star_outline_rounded,
                  size: 64,
                  color: AppColors.warning,
                ).animate().fadeIn().scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                ),
                const SizedBox(height: 20),
                Text(
                  'How was your ride?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  'Your feedback helps keep the community safe',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                          onTap: () => setState(() => _rating = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              index < _rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 44,
                              color: AppColors.warning,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (400 + index * 80).ms)
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          delay: (400 + index * 80).ms,
                        );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  _rating == 0
                      ? 'Tap a star'
                      : _rating <= 2
                      ? 'We\'ll work on it'
                      : _rating <= 4
                      ? 'Good ride!'
                      : 'Amazing!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _rating > 0 ? _submit : null,
                    child: const Text('Submit Rating'),
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ] else ...[
                const Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: AppColors.success,
                ).animate().scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                ),
                const SizedBox(height: 20),
                Text(
                  'Thanks for your feedback!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 8),
                Text(
                  'Redirecting to home...',
                  style: Theme.of(context).textTheme.bodySmall,
                ).animate().fadeIn(delay: 500.ms),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
