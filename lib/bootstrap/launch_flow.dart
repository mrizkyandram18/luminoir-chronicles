import '../gatekeeper/gatekeeper_result.dart';

class LaunchDecision {
  final bool canEnterGame;
  final String? reasonCode;

  const LaunchDecision({
    required this.canEnterGame,
    this.reasonCode,
  });
}

LaunchDecision evaluateLaunchDecision({
  required bool hasActiveAuthSession,
  required GatekeeperResult? heartbeat,
}) {
  if (!hasActiveAuthSession) {
    return const LaunchDecision(
      canEnterGame: false,
      reasonCode: 'SERVICE_STOPPED',
    );
  }

  if (heartbeat == null) {
    return const LaunchDecision(
      canEnterGame: false,
      reasonCode: 'OFFLINE',
    );
  }

  if (!heartbeat.isSuccess) {
    return const LaunchDecision(
      canEnterGame: false,
      reasonCode: 'OFFLINE',
    );
  }

  return const LaunchDecision(
    canEnterGame: true,
    reasonCode: null,
  );
}

