import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mathquest/models/user_account.dart';

void main() {
  test('serializes the selected character with the user profile', () {
    final account = UserAccount(
      email: 'student@example.com',
      role: 'student',
      status: 'pending',
      name: 'Student',
      address: 'School',
      lrn: '123456789012',
      character: 'girl',
      profilePhotoUrl: 'https://example.com/profile-photo',
    );

    expect(account.toJson()['character'], 'girl');
    expect(
      UserAccount.fromJson(account.toJson()).profilePhotoUrl,
      'https://example.com/profile-photo',
    );
  });

  test('defaults legacy profiles to boy', () {
    final account = UserAccount.fromJson({
      'email': 'student@example.com',
      'role': 'student',
      'status': 'pending',
      'name': 'Student',
      'address': 'School',
      'lrn': '123456789012',
    });

    expect(account.character, 'boy');
    expect(account.profilePhotoUrl, isEmpty);
  });

  test('persists an inline profile photo in the account record', () {
    const photoDataUrl = 'data:image/jpeg;base64,YWJj';
    final account = UserAccount.fromJson({
      'email': 'student@example.com',
      'role': 'student',
      'status': 'approved',
      'name': 'Student',
      'address': 'School',
      'lrn': '123456789012',
      'profilePhotoUrl': photoDataUrl,
    });

    expect(account.toJson()['profilePhotoUrl'], photoDataUrl);
  });
}
