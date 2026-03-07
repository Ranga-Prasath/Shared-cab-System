// -- Shared Cab System --
// Create Recurring Ride Screen — Schedule form

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/services/geocoding_service.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/core/utils/night_mode_utils.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/models/recurring_ride_model.dart';
import 'package:shared_cab/models/location_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

class CreateRecurringRideScreen extends ConsumerStatefulWidget {
  const CreateRecurringRideScreen({super.key});

  @override
  ConsumerState<CreateRecurringRideScreen> createState() =>
      _CreateRecurringRideScreenState();
}

class _CreateRecurringRideScreenState
    extends ConsumerState<CreateRecurringRideScreen> {
  LocationPoint? _pickup;
  LocationPoint? _dropoff;
  TimeOfDay _departureTime = const TimeOfDay(hour: 8, minute: 0);
  final Set<int> _selectedDays = {1, 2, 3, 4, 5}; // Default: weekdays

  final TextEditingController _pickupSearchController = TextEditingController();
  final TextEditingController _dropoffSearchController =
      TextEditingController();
  List<LocationPoint> _pickupResults = [];
  List<LocationPoint> _dropoffResults = [];
  bool _isSearchingPickup = false;
  bool _isSearchingDropoff = false;
  Timer? _pickupDebounce;
  Timer? _dropoffDebounce;

  @override
  void dispose() {
    _pickupSearchController.dispose();
    _dropoffSearchController.dispose();
    _pickupDebounce?.cancel();
    _dropoffDebounce?.cancel();
    super.dispose();
  }

  void _onPickupSearchChanged(String query) {
    _pickupDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _pickupResults = [];
        _isSearchingPickup = false;
      });
      return;
    }
    setState(() => _isSearchingPickup = true);
    _pickupDebounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await GeocodingService.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _pickupResults = results;
        _isSearchingPickup = false;
      });
    });
  }

  void _onDropoffSearchChanged(String query) {
    _dropoffDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _dropoffResults = [];
        _isSearchingDropoff = false;
      });
      return;
    }
    setState(() => _isSearchingDropoff = true);
    _dropoffDebounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await GeocodingService.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _dropoffResults = results;
        _isSearchingDropoff = false;
      });
    });
  }

  void _selectPickup(LocationPoint loc) {
    setState(() {
      _pickup = loc;
      _pickupSearchController.text = loc.address;
      _pickupResults = [];
    });
  }

  void _selectDropoff(LocationPoint loc) {
    setState(() {
      _dropoff = loc;
      _dropoffSearchController.text = loc.address;
      _dropoffResults = [];
    });
  }

  void _saveSchedule() {
    if (_pickup == null || _dropoff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and drop-off')),
      );
      return;
    }

    if (_pickup!.latitude == _dropoff!.latitude &&
        _pickup!.longitude == _dropoff!.longitude) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup and drop-off cannot be the same location'),
        ),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final ride = RecurringRide(
      id: const Uuid().v4(),
      userId: ref.read(effectiveCurrentUserProvider).id,
      pickup: _pickup!,
      dropoff: _dropoff!,
      departureTime: _departureTime,
      activeDays: _selectedDays.toList()..sort(),
      createdAt: DateTime.now(),
    );

    final rides = ref.read(recurringRidesProvider);
    ref.read(recurringRidesProvider.notifier).state = [...rides, ride];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Schedule saved!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = ref.watch(effectiveNightModeProvider);
    final accentColor = isNight ? AppColors.nightAccent : AppColors.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('New Schedule')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_repeat_rounded,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Set your daily commute once — we\'ll auto-find matches for you!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // Pickup
            Text(
              'Pickup Location',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            _buildSearchField(
              controller: _pickupSearchController,
              hint: 'Search pickup location...',
              icon: Icons.trip_origin,
              color: AppColors.success,
              isSearching: _isSearchingPickup,
              results: _pickupResults,
              onChanged: _onPickupSearchChanged,
              onSelect: _selectPickup,
              onClear: () {
                _pickupSearchController.clear();
                setState(() {
                  _pickup = null;
                  _pickupResults = [];
                });
              },
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 20),

            // Swap button
            Center(
              child: IconButton(
                onPressed: () {
                  setState(() {
                    final temp = _pickup;
                    _pickup = _dropoff;
                    _dropoff = temp;
                    final tempText = _pickupSearchController.text;
                    _pickupSearchController.text =
                        _dropoffSearchController.text;
                    _dropoffSearchController.text = tempText;
                  });
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.swap_vert_rounded, color: accentColor),
                ),
              ),
            ),

            // Dropoff
            Text(
              'Drop-off Location',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            _buildSearchField(
              controller: _dropoffSearchController,
              hint: 'Search drop-off location...',
              icon: Icons.location_on,
              color: AppColors.danger,
              isSearching: _isSearchingDropoff,
              results: _dropoffResults,
              onChanged: _onDropoffSearchChanged,
              onSelect: _selectDropoff,
              onClear: () {
                _dropoffSearchController.clear();
                setState(() {
                  _dropoff = null;
                  _dropoffResults = [];
                });
              },
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 24),

            // Departure Time
            Text(
              'Departure Time',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _departureTime,
                );
                if (time != null) {
                  setState(() => _departureTime = time);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: accentColor),
                    const SizedBox(width: 12),
                    Text(
                      _departureTime.format(context),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (isNightTimeOfDay(_departureTime))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.nightMoon.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.nightlight_round,
                              color: AppColors.nightMoon,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Night',
                              style: TextStyle(
                                color: AppColors.nightMoon,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 350.ms),

            const SizedBox(height: 24),

            // Day selector
            Text(
              'Repeat On',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 4),
            Text(
              'Tap days to toggle',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _buildDaySelector(accentColor).animate().fadeIn(delay: 450.ms),

            const SizedBox(height: 8),

            // Quick select buttons
            Row(
              children: [
                _buildQuickSelectChip('Weekdays', {1, 2, 3, 4, 5}, accentColor),
                const SizedBox(width: 8),
                _buildQuickSelectChip('Weekends', {6, 7}, accentColor),
                const SizedBox(width: 8),
                _buildQuickSelectChip('All', {
                  1,
                  2,
                  3,
                  4,
                  5,
                  6,
                  7,
                }, accentColor),
              ],
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 32),

            // Distance preview
            if (_pickup != null && _dropoff != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.straighten_rounded,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Est. distance: ${_pickup!.distanceTo(_dropoff!).toStringAsFixed(1)} km',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

            // Save button
            ElevatedButton(
              onPressed: _saveSchedule,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Save Schedule'),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector(Color accentColor) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final dayNum = i + 1;
        final isSelected = _selectedDays.contains(dayNum);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedDays.remove(dayNum);
              } else {
                _selectedDays.add(dayNum);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.6)
                    : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                dayLabels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? accentColor : AppColors.textMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQuickSelectChip(String label, Set<int> days, Color accentColor) {
    final isActive =
        _selectedDays.containsAll(days) && _selectedDays.length == days.length;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedDays
          ..clear()
          ..addAll(days);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? accentColor.withValues(alpha: 0.5)
                : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? accentColor : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
    required bool isSearching,
    required List<LocationPoint> results,
    required ValueChanged<String> onChanged,
    required ValueChanged<LocationPoint> onSelect,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: color),
            suffixIcon: isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: onClear,
                      )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: results.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 48),
              itemBuilder: (context, index) {
                final loc = results[index];
                return ListTile(
                  leading: Icon(Icons.place_rounded, color: color, size: 22),
                  title: Text(
                    loc.address,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  onTap: () => onSelect(loc),
                );
              },
            ),
          ),
      ],
    );
  }
}
