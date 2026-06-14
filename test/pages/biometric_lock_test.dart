import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/services/biometric_service.dart';

void main() {
  test('reports unsupported biometric hardware', () async {
    final service = BiometricService(
      platform: _BiometricPlatform(supported: false),
    );

    expect(await service.authenticate(), BiometricResult.unsupported);
  });

  test('distinguishes cancellation and lockout', () async {
    final canceled = BiometricService(
      platform: _BiometricPlatform(failure: BiometricFailureCode.userCanceled),
    );
    final locked = BiometricService(
      platform: _BiometricPlatform(failure: BiometricFailureCode.lockedOut),
    );

    expect(await canceled.authenticate(), BiometricResult.canceled);
    expect(await locked.authenticate(), BiometricResult.lockedOut);
  });

  test('reports authentication success and ordinary failure', () async {
    final success = BiometricService(
      platform: _BiometricPlatform(authenticated: true),
    );
    final failure = BiometricService(
      platform: _BiometricPlatform(authenticated: false),
    );

    expect(await success.authenticate(), BiometricResult.authenticated);
    expect(await failure.authenticate(), BiometricResult.failed);
  });
}

class _BiometricPlatform implements BiometricPlatform {
  _BiometricPlatform({
    this.supported = true,
    this.authenticated = false,
    this.failure,
  });

  final bool supported;
  final bool authenticated;
  final BiometricFailureCode? failure;

  @override
  Future<bool> authenticate() async {
    final code = failure;
    if (code != null) throw BiometricPlatformException(code);
    return authenticated;
  }

  @override
  Future<bool> isSupported() async => supported;
}
