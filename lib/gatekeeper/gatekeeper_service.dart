import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gatekeeper_result.dart';

/// Service to handle Gatekeeper checks (Child Agent status)
class GatekeeperService extends ChangeNotifier {
  final bool _isSystemOnline = true;

  bool get isSystemOnline => _isSystemOnline;

  /// Checks if the Child Agent is active.
  /// Returns a GatekeeperResult with specific result code
  /// Path: users/{parentId}/children/{childId}
  /// Field: lastSeen (root level) or details.lastSeen
  Future<GatekeeperResult> isChildAgentActive(
    String parentId,
    String childId,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(parentId)
          .collection('children')
          .doc(childId);

      final snapshot = await docRef.get();

      // RC 01: User Not Found
      if (!snapshot.exists) {
        debugPrint(
          "Gatekeeper [01]: Child Agent document not found at $parentId/$childId",
        );
        return GatekeeperResult(
          GatekeeperResultCode.userNotFound,
          'Path: users/$parentId/children/$childId',
        );
      }

      final data = snapshot.data();
      if (data == null) {
        return GatekeeperResult(
          GatekeeperResultCode.userNotFound,
          'Document exists but has no data',
        );
      }

      // Check root level first (based on screenshot), then fallback to details
      Timestamp? lastSeen = data['lastSeen'] as Timestamp?;

      if (lastSeen == null && data.containsKey('details')) {
        final details = data['details'] as Map<String, dynamic>;
        lastSeen = details['lastSeen'] as Timestamp?;
      }

      // RC 03: Missing lastSeen field
      if (lastSeen == null) {
        debugPrint(
          "Gatekeeper [03]: lastSeen field missing in ${snapshot.reference.path}",
        );
        return const GatekeeperResult(GatekeeperResultCode.missingLastSeen);
      }

      final lastSeenDate = lastSeen.toDate();
      final difference = DateTime.now().difference(lastSeenDate);

      // Active if seen within last 24 HOURS (Relaxed for testing)
      // Original: 5 minutes
      if (difference.inMinutes.abs() < 1440) {
        // RC 00: Success
        return const GatekeeperResult(GatekeeperResultCode.success);
      } else {
        // RC 02: User Inactive
        debugPrint(
          "Gatekeeper [02]: Agent inactive. Last seen: $difference ago.",
        );
        return GatekeeperResult(
          GatekeeperResultCode.userInactive,
          'Last seen: ${difference.inHours} hours ago',
        );
      }
    } catch (e) {
      // RC 04: Connection Error
      debugPrint("Gatekeeper [04]: $e");
      return GatekeeperResult(
        GatekeeperResultCode.connectionError,
        e.toString(),
      );
    }
  }

  // Legacy/Mock status (kept for compatibility with Splash Screen)
  Future<void> checkStatus() async {
    // Avoid notifyListeners() here (causes "setState during build" error on startup)
    // Just wait a tick to simulate async check
    await Future.delayed(Duration.zero);
  }
}
