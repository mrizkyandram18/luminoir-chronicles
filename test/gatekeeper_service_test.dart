import 'package:flutter_test/flutter_test.dart';
import 'package:luminoir_chronicles/gatekeeper/gatekeeper_result.dart';
import 'package:luminoir_chronicles/gatekeeper/gatekeeper_service.dart';

class TestGatekeeperService extends GatekeeperService {
  bool session = true;
  bool realtime = true;

  @override
  bool get hasActiveAuthSession => session;

  @override
  bool get isRealtimeActive => realtime;
}

void main() {
  group('GatekeeperService connectivity', () {
    test('isGatekeeperConnected true when auth and realtime are active', () {
      final service = TestGatekeeperService();
      service.session = true;
      service.realtime = true;

      expect(service.isGatekeeperConnected, isTrue);
    });

    test(
      'isGatekeeperConnected true even when auth session is missing (Relaxed Rule)',
      () {
        final service = TestGatekeeperService();
        service.session = false;
        service.realtime = true;

        expect(service.isGatekeeperConnected, isTrue);
      },
    );

    test('isGatekeeperConnected false when realtime flag is inactive', () {
      final service = TestGatekeeperService();
      service.session = true;
      service.realtime = false;

      expect(service.isGatekeeperConnected, isFalse);
    });
  });

  group('Result Code Validation', () {
    test('GatekeeperResult should have correct success check', () {
      const success = GatekeeperResult(GatekeeperResultCode.success);
      const inactive = GatekeeperResult(GatekeeperResultCode.userInactive);

      expect(success.isSuccess, isTrue);
      expect(inactive.isSuccess, isFalse);
    });

    test('GatekeeperResult should store error messages', () {
      const result = GatekeeperResult(
        GatekeeperResultCode.connectionError,
        'Network failure',
      );

      expect(result.resultCode, GatekeeperResultCode.connectionError);
      expect(result.additionalInfo, 'Network failure');
    });
  });
}
