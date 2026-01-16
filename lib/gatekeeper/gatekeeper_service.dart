import 'package:flutter/material.dart';

/// Service to handle Gatekeeper checks (Child Agent status)
class GatekeeperService extends ChangeNotifier {
  bool _isSystemOnline = true; // Default to true for development/mock

  bool get isSystemOnline => _isSystemOnline;

  Future<void> checkStatus() async {
    // ---------------------------------------------------------
    // REAL FIREBASE IMPLEMENTATION (Uncomment when config ready)
    // ---------------------------------------------------------
    /*
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('agents')
          .doc('child_agent_id') // Replace with actual ID
          .get();

      if (snapshot.exists) {
        final lastSeen = (snapshot.data()?['last_seen'] as Timestamp?)?.toDate();
        if (lastSeen != null) {
          final diff = DateTime.now().difference(lastSeen);
          // Active if seen in last 2 minutes
          _isSystemOnline = diff.inMinutes < 2;
        } else {
          _isSystemOnline = false;
        }
      }
    } catch (e) {
      debugPrint('Gatekeeper Error: $e');
      _isSystemOnline = false;
    }
    */

    // ---------------------------------------------------------
    // MOCK IMPLEMENTATION (For MVP / No Firebase Config)
    // ---------------------------------------------------------
    // simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Default to true for development. Set to false to test "Access Denied".
    _isSystemOnline = true;
    notifyListeners();
  }
}
