import 'dart:io';

import 'package:flutter/foundation.dart';

/// AdMob identifiers for LessDo.
abstract final class AdMobConfig {
  /// Publisher app ID from AdMob console.
  static const applicationId = 'ca-app-pub-1210970407399902~1651813383';

  /// Production app open ad unit.
  static const appOpenAdUnitId = 'ca-app-pub-1210970407399902/9742322322';

  static String get appOpenUnitId {
    if (kReleaseMode) return appOpenAdUnitId;
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/9257395921';
    }
    return 'ca-app-pub-3940256099942544/5575463023';
  }
}
