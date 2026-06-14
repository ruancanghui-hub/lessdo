import 'biometric_service.dart';

abstract interface class AuthenticationCoordinator {
  Future<bool> authenticate();
}

abstract interface class SharingCoordinator {
  Future<void> share({required String title, required String text});
}

class LocalAuthenticationCoordinator implements AuthenticationCoordinator {
  LocalAuthenticationCoordinator({BiometricService? service})
    : _service = service ?? BiometricService.localAuth();

  final BiometricService _service;

  @override
  Future<bool> authenticate() async =>
      await _service.authenticate() == BiometricResult.authenticated;
}
