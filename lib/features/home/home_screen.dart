// -- Shared Cab System --
// Home Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(effectiveCurrentUserProvider);
    final isNight = ref.watch(effectiveNightModeProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(context, user, isNight),
              const SizedBox(height: 24),

              // Night mode banner
              if (isNight) _buildNightBanner(context),
              if (isNight) const SizedBox(height: 16),

              // Quick action: Create Ride
              _buildCreateRideCard(context, isNight),
              const SizedBox(height: 20),

              // Stats row
              _buildStatsRow(context, user),
              const SizedBox(height: 20),

              // Safety Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context, isNight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User user, bool isNight) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: isNight ? AppColors.nightAccent : AppColors.primary,
          child: Text(
            user.name[0],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hey, ${user.name.split(' ')[0]}!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Where are you heading today?',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (isNight)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.nightMoon.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.nightlight_round,
              color: AppColors.nightMoon,
              size: 20,
            ),
          ).animate().shimmer(duration: 2000.ms),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildNightBanner(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.nightAccent.withValues(alpha: 0.9),
                AppColors.nightAccent.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_moon_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Night Mode Active',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Same-gender matching & enhanced safety ON',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: -0.1, end: 0, duration: 400.ms);
  }

  Widget _buildCreateRideCard(BuildContext context, bool isNight) {
    return InkWell(
          onTap: () => context.goNamed('createRide'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
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
                  color: (isNight ? AppColors.nightAccent : AppColors.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_road,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create a Ride',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find co-riders and save up to 70%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .slideY(begin: 0.2, end: 0, delay: 200.ms);
  }

  Widget _buildStatsRow(BuildContext context, User user) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.directions_car_outlined,
            label: 'Rides',
            value: '${user.totalTrips}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.savings_outlined,
            label: 'Saved',
            value: 'INR ${(user.totalTrips * 200).toStringAsFixed(0)}',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.star_outline_rounded,
            label: 'Rating',
            value: '${user.rating}',
            color: AppColors.warning,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildQuickActions(BuildContext context, bool isNight) {
    final accentColor = isNight ? AppColors.nightAccent : AppColors.primary;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.contacts_outlined,
                label: 'Emergency\nContacts',
                color: AppColors.danger,
                onTap: () => context.pushNamed('emergencyContacts'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.event_repeat_rounded,
                label: 'My\nSchedules',
                color: accentColor,
                onTap: () => context.pushNamed('recurringRides'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.history_rounded,
                label: 'Ride\nHistory',
                color: AppColors.info,
                onTap: () => context.pushNamed('rideHistory'),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0, delay: 600.ms);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
