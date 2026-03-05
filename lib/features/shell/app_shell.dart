// -- Shared Cab System --
// App Shell: Bottom navigation wrapper

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/router/app_routes.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/core/theme/app_colors.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final currentIndex = path == AppRoutes.profilePath ? 1 : 0;
    final isNight = ref.watch(effectiveNightModeProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: (isNight ? AppColors.nightAccent : AppColors.primary)
                  .withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.goNamed(AppRoutes.homeName);
                break;
              case 1:
                context.goNamed(AppRoutes.profileName);
                break;
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: Icon(
                Icons.home_rounded,
                color: isNight ? AppColors.nightAccent : AppColors.primary,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: isNight ? AppColors.nightAccent : AppColors.primary,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
