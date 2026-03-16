import 'package:flutter_test/flutter_test.dart';
import 'package:shared_cab/features/safety/panic_screen.dart';
import 'package:shared_cab/models/user_model.dart';

void main() {
  test('panic screen copy uses current contact names and honest demo wording', () {
    const contacts = [
      EmergencyContact(
        id: 'ec-1',
        name: 'Priya',
        phone: '9000000001',
        relationship: 'Sister',
      ),
      EmergencyContact(
        id: 'ec-2',
        name: 'Karan',
        phone: '9000000002',
        relationship: 'Friend',
      ),
    ];

    expect(
      PanicScreen.activeModeSummary(contacts),
      'Emergency mode is active.\nSaved contacts: Priya, Karan',
    );
    expect(PanicScreen.demoDisclaimerText, contains('does not auto-message'));
    expect(PanicScreen.demoDisclaimerText, isNot(contains('notified')));
  });
}
