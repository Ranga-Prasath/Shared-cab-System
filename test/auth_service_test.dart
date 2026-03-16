import 'package:flutter_test/flutter_test.dart';
import 'package:shared_cab/core/services/auth_service.dart';
import 'package:shared_cab/models/user_model.dart';

void main() {
  group('AuthService.saveUserProfile', () {
    tearDown(() async {
      await AuthService.signOut();
    });

    test('stores the profile in fallback session state when Firebase is unavailable', () async {
      const user = User(
        id: 'user-1',
        name: 'Rider One',
        phone: '9999999999',
        email: 'rider@example.com',
        gender: 'female',
        emergencyContacts: [
          EmergencyContact(
            id: 'ec-1',
            name: 'Asha',
            phone: '8888888888',
            relationship: 'Friend',
          ),
        ],
      );

      final saved = await AuthService.saveUserProfile(user);

      expect(saved, same(user));
      expect(AuthService.currentUserProfile?.id, user.id);
      expect(AuthService.currentUserProfile?.emergencyContacts, hasLength(1));
    });

    test('signOut clears fallback session state', () async {
      const user = User(
        id: 'user-2',
        name: 'Rider Two',
        phone: '7777777777',
        email: 'rider2@example.com',
        gender: 'male',
      );

      await AuthService.saveUserProfile(user);
      await AuthService.signOut();

      expect(AuthService.currentUserProfile, isNull);
    });
  });
}
