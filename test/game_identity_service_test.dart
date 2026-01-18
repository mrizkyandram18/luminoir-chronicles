import 'package:flutter_test/flutter_test.dart';
import 'package:luminoir_chronicles/game_identity/game_identity_service.dart';

class InMemoryGameIdentityStore implements GameIdentityStore {
  final Map<String, String> saved = {};

  @override
  Future<String?> loadDisplayName(String childId) async {
    return saved[childId];
  }

  @override
  Future<void> saveDisplayName(String childId, String displayName) async {
    saved[childId] = displayName;
  }
}

void main() {
  group('GameIdentityService', () {
    late InMemoryGameIdentityStore store;
    late GameIdentityService service;

    setUp(() {
      store = InMemoryGameIdentityStore();
      service = GameIdentityService(store: store);
    });

    test('returns childId when no custom name set', () {
      final name = service.getName('child-123');

      expect(name, 'child-123');
    });

    test('rename updates Supabase-backed store only', () async {
      await service.rename('child-123', 'Neo');

      expect(store.saved['child-123'], 'Neo');
      expect(service.getName('child-123'), 'Neo');
    });
  });
}
