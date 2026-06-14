import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricResult { authenticated, unsupported, lockedOut, canceled, failed }

enum BiometricFailureCode { unsupported, lockedOut, userCanceled, failed }

class BiometricPlatformException implements Exception {
  const BiometricPlatformException(this.code);

  final BiometricFailureCode code;
}

abstract interface class BiometricPlatform {
  Future<bool> isSupported();

  Future<bool> authenticate();
}

class BiometricService {
  BiometricService({required BiometricPlatform platform})
    : _platform = platform;

  factory BiometricService.localAuth({
    LocalAuthentication? localAuthentication,
  }) {
    return BiometricService(
      platform: LocalAuthBiometricPlatform(
        localAuthentication: localAuthentication,
      ),
    );
  }

  final BiometricPlatform _platform;

  Future<BiometricResult> authenticate() async {
    if (kIsWeb) return BiometricResult.unsupported;
    try {
      if (!await _platform.isSupported()) {
        return BiometricResult.unsupported;
      }
      return await _platform.authenticate()
          ? BiometricResult.authenticated
          : BiometricResult.failed;
    } on BiometricPlatformException catch (error) {
      return switch (error.code) {
        BiometricFailureCode.unsupported => BiometricResult.unsupported,
        BiometricFailureCode.lockedOut => BiometricResult.lockedOut,
        BiometricFailureCode.userCanceled => BiometricResult.canceled,
        BiometricFailureCode.failed => BiometricResult.failed,
      };
    } catch (_) {
      return BiometricResult.failed;
    }
  }
}

class LocalAuthBiometricPlatform implements BiometricPlatform {
  LocalAuthBiometricPlatform({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> isSupported() => _localAuthentication.isDeviceSupported();

  @override
  Future<bool> authenticate() async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: 'Unlock LessDo',
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (error) {
      throw BiometricPlatformException(_mapCode(error.code));
    }
  }

  BiometricFailureCode _mapCode(LocalAuthExceptionCode code) {
    return switch (code) {
      LocalAuthExceptionCode.userCanceled ||
      LocalAuthExceptionCode.systemCanceled ||
      LocalAuthExceptionCode.userRequestedFallback =>
        BiometricFailureCode.userCanceled,
      LocalAuthExceptionCode.temporaryLockout ||
      LocalAuthExceptionCode.biometricLockout => BiometricFailureCode.lockedOut,
      LocalAuthExceptionCode.noBiometricHardware ||
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.noCredentialsSet =>
        BiometricFailureCode.unsupported,
      _ => BiometricFailureCode.failed,
    };
  }
}
