import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game_identity/game_identity_service.dart';

void main() {
  group('GameIdentityService', () {
    test('returns childId when no custom name set', () {
      final service = GameIdentityService();

      final name = service.getName('child-123');

      expect(name, 'child-123');
    });

    test('rename stores name only in local game identity service', () async {
      final service = GameIdentityService();

      await service.rename('child-123', 'Neo');

      expect(service.getName('child-123'), 'Neo');
    });
  });
}

