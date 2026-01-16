/// Gatekeeper authentication result codes
enum GatekeeperResultCode {
  /// 00: Success - Agent is active and verified
  success('00', 'Agent verified and active'),

  /// 01: User document not found in Firestore
  userNotFound('01', 'Agent not found in system'),

  /// 02: User exists but lastSeen indicates inactive (beyond timeout)
  userInactive('02', 'Agent is offline or inactive'),

  /// 03: User document missing lastSeen field
  missingLastSeen('03', 'Agent data incomplete (missing lastSeen)'),

  /// 04: Firestore connection error or exception
  connectionError('04', 'Unable to connect to authentication server'),

  /// 99: Unknown error
  unknownError('99', 'An unknown error occurred');

  const GatekeeperResultCode(this.code, this.message);

  final String code;
  final String message;

  bool get isSuccess => this == GatekeeperResultCode.success;

  @override
  String toString() => '[$code] $message';
}

/// Result wrapper for Gatekeeper checks
class GatekeeperResult {
  final GatekeeperResultCode resultCode;
  final String? additionalInfo;

  const GatekeeperResult(this.resultCode, [this.additionalInfo]);

  bool get isSuccess => resultCode.isSuccess;

  String get displayMessage {
    if (additionalInfo != null) {
      return '${resultCode.message}\n$additionalInfo';
    }
    return resultCode.message;
  }

  @override
  String toString() =>
      'GatekeeperResult(${resultCode.code}: ${resultCode.message})';
}
