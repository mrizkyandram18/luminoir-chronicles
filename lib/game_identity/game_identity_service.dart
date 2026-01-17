import 'package:flutter/material.dart';

class GameIdentityService extends ChangeNotifier {
  final Map<String, String> _namesByChildId = {};

  String getName(String childId) {
    return _namesByChildId[childId] ?? childId;
  }

  Future<void> rename(String childId, String newName) async {
    _namesByChildId[childId] = newName;
    notifyListeners();
  }
}

