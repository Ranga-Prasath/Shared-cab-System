// -- Shared Cab System --
// Emergency Contacts Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(effectiveCurrentUserProvider);
    final contacts = user.emergencyContacts;
    final isNight = ref.watch(effectiveNightModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'These contacts will be notified in emergencies and during Night Mode trips.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 20),
            Expanded(
              child: contacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.contacts_outlined,
                            size: 64,
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text('No emergency contacts yet'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isNight
                                      ? AppColors.nightAccent
                                      : AppColors.primary,
                                  child: Text(
                                    contact.name[0],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                title: Text(contact.name),
                                subtitle: Text(
                                  '${contact.relationship} - ${contact.phone}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.phone_outlined,
                                    color: AppColors.success,
                                  ),
                                  onPressed: () {},
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: (100 * index).ms)
                            .slideX(begin: 0.1, end: 0);
                      },
                    ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Demo: show add contact dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add contact feature - coming soon'),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
            ),
          ],
        ),
      ),
    );
  }
}
