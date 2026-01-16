import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'gatekeeper_result.dart';

/// Service to handle Gatekeeper checks (Child Agent status)
class GatekeeperService extends ChangeNotifier {
  final bool _isSystemOnline = true;

  // Realtime monitoring
  StreamSubscription<DocumentSnapshot>? _realtimeListener;
  bool _isRealtimeActive = true;
  String? _displayName;

  bool get isSystemOnline => _isSystemOnline;
  bool get isRealtimeActive => _isRealtimeActive;
  String? get displayName => _displayName;

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
        debugPrint("Gatekeeper [01]: User not found at $parentId/$childId");
        return const GatekeeperResult(GatekeeperResultCode.userNotFound);
      }

      final data = snapshot.data();
      if (data == null) {
        return const GatekeeperResult(GatekeeperResultCode.userNotFound);
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

      // Active if seen within last 1 MINUTE (Strict realtime monitoring)
      if (difference.inMinutes.abs() < 1) {
        // Fetch display name if available
        _displayName = data['name'] ?? data['displayName'] ?? childId;
        notifyListeners();

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

  /// Start realtime monitoring of child agent's online status
  /// Listens to isOnline field changes in Firestore
  void startRealtimeMonitoring(String parentId, String childId) {
    stopRealtimeMonitoring(); // Clean up previous listener

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(parentId)
        .collection('children')
        .doc(childId);

    _realtimeListener = docRef.snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) {
          if (_isRealtimeActive) {
            debugPrint("Gatekeeper [$childId]: OFFLINE (not found)");
          }
          _isRealtimeActive = false;
          notifyListeners();
          return;
        }

        final data = snapshot.data();
        if (data == null) {
          if (_isRealtimeActive) {
            debugPrint("Gatekeeper [$childId]: OFFLINE (no data)");
          }
          _isRealtimeActive = false;
          notifyListeners();
          return;
        }

        // Check isOnline field from details map (matching production schema)
        final details = data['details'] as Map<String, dynamic>?;
        final isOnline = details?['isOnline'] as bool? ?? false;

        // Only log and notify if status actually changed
        if (_isRealtimeActive != isOnline) {
          debugPrint(
            "Gatekeeper [$childId]: ${isOnline ? 'ONLINE' : 'OFFLINE'}",
          );
          _isRealtimeActive = isOnline;
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint("Gatekeeper [$childId] Error: $error");
        _isRealtimeActive = false;
        notifyListeners();
      },
    );
  }

  /// Stop realtime monitoring
  void stopRealtimeMonitoring() {
    _realtimeListener?.cancel();
    _realtimeListener = null;
  }

  // Legacy/Mock status (kept for compatibility with Splash Screen)
  Future<void> checkStatus() async {
    // Avoid notifyListeners() here (causes "setState during build" error on startup)
    // Just wait a tick to simulate async check
    await Future.delayed(Duration.zero);
  }

  @override
  void dispose() {
    stopRealtimeMonitoring();
    super.dispose();
  }

  /// Update display name in Firestore
  Future<void> updateDisplayName(
    String parentId,
    String childId,
    String newName,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .update({'name': newName});

      _displayName = newName;
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating display name: $e");
    }
  }
}
