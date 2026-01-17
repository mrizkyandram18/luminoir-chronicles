import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class GameIdentityStore {
  Future<String?> loadDisplayName(String childId);
  Future<void> saveDisplayName(String childId, String displayName);
}

class SupabaseGameIdentityStore implements GameIdentityStore {
  final SupabaseClient _client;

  SupabaseGameIdentityStore({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<String?> loadDisplayName(String childId) async {
    final response = await _client
        .from('game_identities')
        .select('display_name')
        .eq('child_id', childId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return response['display_name'] as String?;
  }

  @override
  Future<void> saveDisplayName(String childId, String displayName) async {
    await _client.from('game_identities').upsert({
      'child_id': childId,
      'display_name': displayName,
    });
  }
}

class GameIdentityService extends ChangeNotifier {
  final GameIdentityStore _store;
  final Map<String, String> _namesByChildId = {};

  GameIdentityService({GameIdentityStore? store})
      : _store = store ?? SupabaseGameIdentityStore();

  String getName(String childId) {
    return _namesByChildId[childId] ?? childId;
  }

  Future<void> loadName(String childId) async {
    final value = await _store.loadDisplayName(childId);

    if (value != null) {
      _namesByChildId[childId] = value;
      notifyListeners();
    }
  }

  Future<void> rename(String childId, String newName) async {
    await _store.saveDisplayName(childId, newName);

    _namesByChildId[childId] = newName;
    notifyListeners();
  }
}
