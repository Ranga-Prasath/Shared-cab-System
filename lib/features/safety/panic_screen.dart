// -- Shared Cab System --
// Panic Screen (Emergency)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:shared_cab/data/mock/mock_data.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PanicScreen extends ConsumerStatefulWidget {
  const PanicScreen({super.key});

  @override
  ConsumerState<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends ConsumerState<PanicScreen> {
  bool _alertSent = false;

  void _triggerAlert() {
    setState(() => _alertSent = true);
    ref.read(panicModeProvider.notifier).state = true;

    final trip = ref.read(activeTripProvider);
    if (trip != null) {
      ref.read(activeTripProvider.notifier).state = trip.copyWith(
        panicTriggered: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nightPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_alertSent) ...[
                const Icon(
                      Icons.warning_amber_rounded,
                      size: 80,
                      color: AppColors.danger,
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 800.ms,
                    ),
                const SizedBox(height: 24),
                const Text(
                  'EMERGENCY',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 12),
                const Text(
                  'Tap the button below to send an\nemergency alert to your contacts',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                GestureDetector(
                      onTap: _triggerAlert,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.danger,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.danger.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1.05, 1.05),
                      duration: 1200.ms,
                    ),
                const SizedBox(height: 40),
                // Quick dial
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _EmergencyDialButton(
                      icon: Icons.local_police_outlined,
                      label: '100',
                      onTap: () {},
                    ),
                    const SizedBox(width: 24),
                    _EmergencyDialButton(
                      icon: Icons.local_hospital_outlined,
                      label: '108',
                      onTap: () {},
                    ),
                    const SizedBox(width: 24),
                    _EmergencyDialButton(
                      icon: Icons.emergency_outlined,
                      label: '112',
                      onTap: () {},
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),
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
                const SizedBox(height: 24),
                const Text(
                  'ALERT SENT',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 12),
                Text(
                  'Emergency contacts notified:\n${MockData.demoUser.emergencyContacts.map((c) => c.name).join(', ')}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 8),
                const Text(
                  'Your live location is being shared',
                  style: TextStyle(color: AppColors.nightMoon, fontSize: 14),
                ).animate().fadeIn(delay: 700.ms),
              ],
              const Spacer(),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'Back to Trip',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyDialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EmergencyDialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
