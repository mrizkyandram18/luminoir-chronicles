import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'gatekeeper_result.dart';

/// Service to handle Gatekeeper checks (Child Agent status)
class GatekeeperService extends ChangeNotifier {
  bool _isSystemOnline = true;
  bool _disposed = false;

  // Realtime monitoring
  StreamSubscription<DocumentSnapshot>? _realtimeListener;
  bool _isRealtimeActive = false;

  bool get isSystemOnline => _isSystemOnline;
  bool get isRealtimeActive => _isRealtimeActive;
  bool get isGatekeeperConnected => isRealtimeActive;

  bool get hasActiveAuthSession {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }

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

      if (difference.inSeconds.abs() <= 60) {
        return const GatekeeperResult(GatekeeperResultCode.success);
      } else {
        debugPrint(
          "Gatekeeper [02]: Agent inactive. Last seen: $difference ago.",
        );
        return GatekeeperResult(
          GatekeeperResultCode.userInactive,
          'Last seen: ${difference.inSeconds} seconds ago',
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

  Future<void> checkStatus() async {
    await Future.delayed(Duration.zero);
    _isSystemOnline = hasActiveAuthSession;
  }

  @override
  void dispose() {
    _disposed = true;
    stopRealtimeMonitoring();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  /// Checks if the provided [userId] is present in the whitelist.
  ///
  /// It checks `config/whitelist` document in Firestore.
  Future<bool> isUserAllowed(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('whitelist')
          .get();

      if (!doc.exists || doc.data() == null) {
        debugPrint('Gatekeeper: Whitelist document not found or empty.');
        // Fail safe: valid users must be whitelisted.
        return false;
      }

      final data = doc.data()!;

      // Strict check: Iterate through all values in the document.
      for (final value in data.values) {
        // Direct value match
        if (value.toString() == userId) {
          return true;
        }

        // List field match
        if (value is List) {
          if (value.any((element) => element.toString() == userId)) {
            return true;
          }
        }
      }

      debugPrint('Gatekeeper: Access denied for $userId');
      return false;
    } catch (e) {
      debugPrint('Gatekeeper Error: $e');
      return false;
    }
  }
}
