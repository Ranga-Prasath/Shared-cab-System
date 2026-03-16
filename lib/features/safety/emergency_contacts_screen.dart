// -- Shared Cab System --
// Emergency Contacts Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_cab/core/services/auth_service.dart';
import 'package:shared_cab/core/theme/app_colors.dart';
import 'package:shared_cab/core/utils/ride_formatters.dart';
import 'package:shared_cab/data/mock/mock_data.dart';
import 'package:shared_cab/providers/app_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_cab/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> {
  Future<void> _launchPhone(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to open dialer for $number')),
    );
  }

  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    final newContact = await showDialog<EmergencyContact>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(labelText: 'Relationship'),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final relationship = relationController.text.trim();

              if (name.isEmpty || phone.isEmpty || relationship.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter name, phone, and relationship'),
                  ),
                );
                return;
              }

              Navigator.of(dialogContext).pop(
                EmergencyContact(
                  id: 'ec_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  phone: phone,
                  relationship: relationship,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    phoneController.dispose();
    relationController.dispose();

    if (newContact == null || !mounted) return;

    final baseUser = ref.read(currentUserProvider) ?? MockData.demoUser;
    final updatedUser = baseUser.copyWith(
      emergencyContacts: [...baseUser.emergencyContacts, newContact],
    );

    try {
      final savedUser = await AuthService.saveUserProfile(updatedUser);
      ref.read(currentUserOverrideProvider.notifier).state = savedUser;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newContact.name} added as an emergency contact'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save this contact right now. Please try again.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      'These contacts are shown during emergency flows. This demo does not automatically message them.',
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
                                    RideFormatters.safeInitial(contact.name),
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
                                  onPressed: () => _launchPhone(contact.phone),
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
              onPressed: _showAddContactDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
            ),
          ],
        ),
      ),
    );
  }
}
