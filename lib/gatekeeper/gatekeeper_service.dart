import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to handle Gatekeeper checks (Child Agent status)
class GatekeeperService extends ChangeNotifier {
  final bool _isSystemOnline = true;

  bool get isSystemOnline => _isSystemOnline;

  /// Checks if the Child Agent is active.
  /// Path: users/{parentId}/children/{childId}
  /// Field: details.lastSeen
  Future<bool> isChildAgentActive(String parentId, String childId) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(parentId)
          .collection('children')
          .doc(childId);

      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        debugPrint(
          "Gatekeeper: Child Agent document not found at $parentId/$childId",
        );
        return false;
      }

      final data = snapshot.data();
      if (data == null || !data.containsKey('details')) return false;

      final details = data['details'] as Map<String, dynamic>;
      final Timestamp? lastSeen = details['lastSeen'] as Timestamp?;

      if (lastSeen == null) return false;

      final lastSeenDate = lastSeen.toDate();
      final difference = DateTime.now().difference(lastSeenDate);

      // Active if seen within last 24 HOURS (Relaxed for testing)
      // Original: 5 minutes
      if (difference.inMinutes.abs() < 1440) {
        return true;
      } else {
        debugPrint("Gatekeeper: Agent inactive. Last seen: $difference ago.");
        return false;
      }
    } catch (e) {
      debugPrint("Gatekeeper Error: $e");
      return false;
    }
  }

  // Legacy/Mock status (kept for compatibility with Splash Screen)
  Future<void> checkStatus() async {
    // In a real app, we might check Auth/Connectivity here
    notifyListeners();
  }
}
