import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to handle Gatekeeper checks (Child Agent status)
class GatekeeperService extends ChangeNotifier {
  bool _isSystemOnline = true;

  bool get isSystemOnline => _isSystemOnline;

  /// Checks if the Child Agent is active (last_seen < 5 mins ago).
  /// Returns true if active, false if offline.
  Future<bool> isChildAgentActive(String childId) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('child_agents')
          .doc(childId);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        debugPrint("Gatekeeper: Agent $childId not found in Firestore.");
        return false;
      }

      final data = snapshot.data();
      if (data == null || !data.containsKey('last_seen')) {
        return false;
      }

      final Timestamp lastSeen = data['last_seen'];
      final DateTime lastSeenDate = lastSeen.toDate();
      final DateTime now = DateTime.now();

      final difference = now.difference(lastSeenDate).inMinutes;

      // Active if seen within last 5 minutes
      final isActive = difference < 5;

      if (!isActive) {
        debugPrint(
          "Gatekeeper: Agent inactive. Last seen $difference mins ago.",
        );
      }
      return isActive;
    } catch (e) {
      debugPrint("Gatekeeper Error: $e");
      // Fallback for demo if config missing, but strictly should be false.
      // We'll return false to enforce the rule.
      return false;
    }
  }

  // Legacy/Mock status (kept for compatibility with Splash Screen)
  Future<void> checkStatus() async {
    // In a real app, we might check Auth/Connectivity here
    notifyListeners();
  }
}
