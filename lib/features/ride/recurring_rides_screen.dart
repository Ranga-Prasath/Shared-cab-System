// -- Shared Cab System --
// Recurring Rides Screen — List all scheduled rides

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/models/recurring_ride_model.dart';
import 'package:shared_cab/data/mock/mock_data.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecurringRidesScreen extends ConsumerStatefulWidget {
  const RecurringRidesScreen({super.key});

  @override
  ConsumerState<RecurringRidesScreen> createState() =>
      _RecurringRidesScreenState();
}

class _RecurringRidesScreenState extends ConsumerState<RecurringRidesScreen> {
  @override
  void initState() {
    super.initState();
    // Load mock data if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rides = ref.read(recurringRidesProvider);
      if (rides.isEmpty) {
        ref.read(recurringRidesProvider.notifier).state =
            MockData.mockRecurringRides;
      }
    });
  }

  void _deleteRide(String id) {
    final rides = ref.read(recurringRidesProvider);
    ref.read(recurringRidesProvider.notifier).state = rides
        .where((r) => r.id != id)
        .toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Schedule deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _toggleRide(String id) {
    final rides = ref.read(recurringRidesProvider);
    ref.read(recurringRidesProvider.notifier).state = rides.map((r) {
      if (r.id == id) return r.copyWith(isActive: !r.isActive);
      return r;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rides = ref.watch(recurringRidesProvider);
    final isNight = ref.watch(effectiveNightModeProvider);
    final accentColor = isNight ? AppColors.nightAccent : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedules'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed('home'),
        ),
      ),
      body: rides.isEmpty
          ? _buildEmptyState(context)
          : _buildList(rides, accentColor, isNight),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('createRecurringRide'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Schedule'),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_repeat_rounded,
            size: 80,
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No schedules yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a recurring ride to auto-find\nmatches every day',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildList(
    List<RecurringRide> rides,
    Color accentColor,
    bool isNight,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return _buildRideCard(context, ride, accentColor, isNight, index);
      },
    );
  }

  Widget _buildRideCard(
    BuildContext context,
    RecurringRide ride,
    Color accentColor,
    bool isNight,
    int index,
  ) {
    return Dismissible(
      key: ValueKey(ride.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
        ),
      ),
      onDismissed: (_) => _deleteRide(ride.id),
      child:
          Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: time + active toggle
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  ride.timeLabel,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: accentColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (ride.isNightRide)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.nightMoon.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.nightlight_round,
                                    color: AppColors.nightMoon,
                                    size: 12,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Night',
                                    style: TextStyle(
                                      color: AppColors.nightMoon,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          Switch(
                            value: ride.isActive,
                            onChanged: (_) => _toggleRide(ride.id),
                            activeThumbColor: accentColor,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Route
                      Row(
                        children: [
                          Column(
                            children: [
                              Icon(
                                Icons.trip_origin,
                                size: 16,
                                color: AppColors.success,
                              ),
                              Container(
                                width: 1.5,
                                height: 20,
                                color: AppColors.divider,
                              ),
                              Icon(
                                Icons.location_on,
                                size: 16,
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
                                  ride.pickup.address,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  ride.dropoff.address,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Day chips
                      _buildDayChips(ride, accentColor),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 80 * index))
              .slideX(begin: 0.1, end: 0),
    );
  }

  Widget _buildDayChips(RecurringRide ride, Color accentColor) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(7, (i) {
        final dayNum = i + 1;
        final isActive = ride.activeDays.contains(dayNum);
        return Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: isActive
                ? accentColor.withValues(alpha: ride.isActive ? 0.15 : 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? accentColor.withValues(alpha: ride.isActive ? 0.5 : 0.2)
                  : AppColors.divider,
            ),
          ),
          child: Center(
            child: Text(
              dayLabels[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? (ride.isActive ? accentColor : AppColors.textMuted)
                    : AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }),
    );
  }
}
