import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class AuthenticationCoordinator {
  Future<bool> authenticate();
}

abstract interface class SharingCoordinator {
  Future<void> share({required String title, required String text});
}

class LocalAuthenticationCoordinator implements AuthenticationCoordinator {
  LocalAuthenticationCoordinator({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> authenticate() async {
    if (kIsWeb) return false;
    try {
      if (!await _localAuthentication.isDeviceSupported()) return false;
      return _localAuthentication.authenticate(
        localizedReason: 'Unlock LessDo',
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

class SharePlusCoordinator implements SharingCoordinator {
  @override
  Future<void> share({required String title, required String text}) {
    return SharePlus.instance.share(ShareParams(title: title, text: text));
  }
}
