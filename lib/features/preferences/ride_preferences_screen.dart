// -- Shared Cab System --
// Ride Preferences Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/models/ride_preferences_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RidePreferencesScreen extends ConsumerWidget {
  const RidePreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(ridePreferencesProvider);
    final isNight = ref.watch(effectiveNightModeProvider);
    final accent = isNight ? AppColors.nightAccent : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Preferences'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header illustration
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isNight
                      ? [AppColors.nightSurface, AppColors.nightPrimary]
                      : [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Customize Your Ride',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set your preferences for a comfortable ride.\nMatched riders will see your tags.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.15, end: 0),

            const SizedBox(height: 28),

            // Active Tags Preview
            if (prefs.activeTags.isNotEmpty) ...[
              Text(
                'Your Active Preferences',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: prefs.activeTags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 24),
            ],

            // Preference toggles
            Text(
              'Comfort',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _PreferenceTile(
              icon: Icons.ac_unit_rounded,
              label: 'AC Preferred',
              subtitle: 'Match with riders who prefer air conditioning',
              value: prefs.acPreferred,
              color: AppColors.info,
              onChanged: (val) {
                ref.read(ridePreferencesProvider.notifier).state =
                    prefs.copyWith(acPreferred: val);
              },
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05, end: 0),
            _PreferenceTile(
              icon: Icons.music_note_rounded,
              label: 'Music Allowed',
              subtitle: 'Okay with music or radio during the ride',
              value: prefs.musicAllowed,
              color: AppColors.accent,
              onChanged: (val) {
                ref.read(ridePreferencesProvider.notifier).state =
                    prefs.copyWith(musicAllowed: val);
              },
            ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.05, end: 0),
            _PreferenceTile(
              icon: Icons.volume_off_rounded,
              label: 'Silent Ride',
              subtitle: 'Prefer a quiet ride with no conversation',
              value: prefs.silentRide,
              color: AppColors.textSecondary,
              onChanged: (val) {
                ref.read(ridePreferencesProvider.notifier).state =
                    prefs.copyWith(silentRide: val);
              },
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05, end: 0),

            const SizedBox(height: 20),

            Text(
              'Special Needs',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _PreferenceTile(
              icon: Icons.pets_rounded,
              label: 'Pet-Friendly',
              subtitle: 'Traveling with a pet companion',
              value: prefs.petFriendly,
              color: AppColors.warning,
              onChanged: (val) {
                ref.read(ridePreferencesProvider.notifier).state =
                    prefs.copyWith(petFriendly: val);
              },
            ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.05, end: 0),
            _PreferenceTile(
              icon: Icons.luggage_rounded,
              label: 'Extra Luggage',
              subtitle: 'Need space for bags or suitcases',
              value: prefs.extraLuggage,
              color: AppColors.primary,
              onChanged: (val) {
                ref.read(ridePreferencesProvider.notifier).state =
                    prefs.copyWith(extraLuggage: val);
              },
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05, end: 0),
            _PreferenceTile(
              icon: Icons.window_rounded,
              label: 'Window Seat',
              subtitle: 'Prefer sitting by the window',
              value: prefs.windowSeat,
              color: AppColors.success,
              onChanged: (val) {
                ref.read(ridePreferencesProvider.notifier).state =
                    prefs.copyWith(windowSeat: val);
              },
            ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.05, end: 0),

            const SizedBox(height: 28),

            // Save confirmation card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-saved',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your preferences are applied to all future rides automatically.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _PreferenceTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: value
            ? BorderSide(color: color.withValues(alpha: 0.4), width: 1.5)
            : BorderSide.none,
      ),
      elevation: value ? 2 : 0.5,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: value ? 0.15 : 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ),
    );
  }
}
