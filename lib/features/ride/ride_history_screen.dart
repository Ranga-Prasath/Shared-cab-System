import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/models/trip_model.dart';
import 'package:shared_cab/providers/app_providers.dart';

class RideHistoryScreen extends ConsumerWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(rideHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ride History')),
      body: history.isEmpty
          ? _EmptyHistory(onCreateRide: () => context.goNamed('createRide'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _HistoryCard(trip: history[index]);
              },
            ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final VoidCallback onCreateRide;

  const _EmptyHistory({required this.onCreateRide});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_toggle_off_rounded, size: 64),
            const SizedBox(height: 12),
            Text(
              'No completed rides yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Finish a trip and it will appear here.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreateRide,
              icon: const Icon(Icons.add_road_rounded),
              label: const Text('Create Ride'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Trip trip;

  const _HistoryCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final endedAt = trip.endTime ?? trip.startTime;
    final statusLabel = _statusText(trip.status);
    final statusColor = _statusColor(trip.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(endedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Trip #${trip.id.split('_').last}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.straighten_rounded,
                  label: '${(trip.tripDistanceKm ?? 0).toStringAsFixed(1)} km',
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.currency_rupee_rounded,
                  label: 'INR ${(trip.farePerPerson ?? 0).toStringAsFixed(0)}',
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.people_outline_rounded,
                  label: '${trip.riderIds.length}',
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(TripStatus status) {
    return switch (status) {
      TripStatus.completed => 'Completed',
      TripStatus.arrivedDestination => 'Arrived',
      TripStatus.inProgress => 'In Progress',
      TripStatus.waitingForPickup => 'Waiting',
      TripStatus.emergency => 'Emergency',
    };
  }

  Color _statusColor(TripStatus status) {
    return switch (status) {
      TripStatus.completed => AppColors.success,
      TripStatus.arrivedDestination => AppColors.primary,
      TripStatus.inProgress => AppColors.info,
      TripStatus.waitingForPickup => AppColors.warning,
      TripStatus.emergency => AppColors.danger,
    };
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
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
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
