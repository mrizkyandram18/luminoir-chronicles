import 'package:flutter_test/flutter_test.dart';
import 'package:luminoir_chronicles/bootstrap/launch_flow.dart';
import 'package:luminoir_chronicles/gatekeeper/gatekeeper_result.dart';

void main() {
  group('LaunchDecision', () {
    test('blocks when auth session is missing', () {
      final decision = evaluateLaunchDecision(
        hasActiveAuthSession: false,
        heartbeat: null,
      );

      expect(decision.canEnterGame, isFalse);
      expect(decision.reasonCode, 'SERVICE_STOPPED');
    });

    test('blocks when heartbeat is invalid', () {
      const heartbeat = GatekeeperResult(GatekeeperResultCode.userInactive);

      final decision = evaluateLaunchDecision(
        hasActiveAuthSession: true,
        heartbeat: heartbeat,
      );

      expect(decision.canEnterGame, isFalse);
      expect(decision.reasonCode, 'OFFLINE');
    });

    test('allows entry when auth and heartbeat are valid', () {
      const heartbeat = GatekeeperResult(GatekeeperResultCode.success);

      final decision = evaluateLaunchDecision(
        hasActiveAuthSession: true,
        heartbeat: heartbeat,
      );

      expect(decision.canEnterGame, isTrue);
      expect(decision.reasonCode, isNull);
    });
  });
}

