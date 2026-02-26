// -- Shared Cab System --
// Profile Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(effectiveCurrentUserProvider);
    final isNight = ref.watch(effectiveNightModeProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Avatar
              CircleAvatar(
                radius: 45,
                backgroundColor: isNight
                    ? AppColors.nightAccent
                    : AppColors.primary,
                child: Text(
                  user.name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ).animate().fadeIn().scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
              ),
              const SizedBox(height: 16),
              Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (user.isVerified)
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.success,
                      size: 18,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    user.phone,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Stats
              Row(
                children: [
                  Expanded(
                    child: _ProfileStat(
                      label: 'Trips',
                      value: '${user.totalTrips}',
                    ),
                  ),
                  Expanded(
                    child: _ProfileStat(
                      label: 'Rating',
                      value: '${user.rating}',
                    ),
                  ),
                  Expanded(
                    child: _ProfileStat(
                      label: 'Saved',
                      value: 'INR ${user.totalTrips * 200}',
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 24),
              // Menu items
              _ProfileMenuItem(
                icon: Icons.contacts_outlined,
                label: 'Emergency Contacts',
                subtitle: '${user.emergencyContacts.length} contacts',
                onTap: () => context.pushNamed('emergencyContacts'),
              ),
              _ProfileMenuItem(
                icon: Icons.nightlight_round,
                label: 'Night Mode',
                subtitle: isNight ? 'Active' : 'Inactive',
                trailing: Switch(
                  value: isNight,
                  onChanged: (val) {
                    ref.read(nightModeOverrideProvider.notifier).state = val;
                  },
                  activeThumbColor: AppColors.nightAccent,
                ),
              ),
              _ProfileMenuItem(
                icon: Icons.wc_rounded,
                label: 'Same-Gender Matching',
                subtitle: 'For night rides',
                trailing: Switch(
                  value: ref.watch(sameGenderOnlyProvider),
                  onChanged: (val) {
                    ref.read(sameGenderOnlyProvider.notifier).state = val;
                  },
                  activeThumbColor: AppColors.primary,
                ),
              ),
              _ProfileMenuItem(
                icon: Icons.info_outline,
                label: 'About',
                subtitle: 'Shared Cab v0.1.0',
                onTap: () {},
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(isLoggedInProvider.notifier).state = false;
                    ref.read(currentUserProvider.notifier).state = null;
                    ref.read(activeTripProvider.notifier).state = null;
                    ref.read(rideHistoryProvider.notifier).state = [];
                    ref.read(currentRideRequestProvider.notifier).state = null;
                    ref.read(panicModeProvider.notifier).state = false;
                    ref.read(bottomNavIndexProvider.notifier).state = 0;
                    context.goNamed('login');
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.danger,
                  ),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        subtitle: Text(subtitle),
        trailing:
            trailing ??
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
