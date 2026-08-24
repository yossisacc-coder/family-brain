import 'package:family_brain/domain/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hasFamily depends on familyId', () {
    final user = AppUser(
      id: 'u1',
      name: 'Alex',
      phone: '+16505551234',
      language: 'en',
      createdAt: DateTime(2026, 1, 1),
    );
    expect(user.hasFamily, isFalse);
    expect(user.copyWith(familyId: 'fam-1').hasFamily, isTrue);
  });

  test('phone is hidden unless the member chose to share it', () {
    final maya = AppUser(
      id: 'maya',
      name: 'Maya',
      phone: '+16505550000',
      language: 'en',
      createdAt: DateTime(2026, 1, 1),
    );
    expect(maya.sharePhone, isFalse);
    expect(maya.phoneVisibleTo('alex'), isFalse);
    expect(maya.phoneVisibleTo('maya'), isTrue);
    expect(maya.copyWith(sharePhone: true).phoneVisibleTo('alex'), isTrue);
    expect(AppUser.fromMap(maya.toMap()).sharePhone, isFalse);
  });
}
