import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class MobileAdsSupport {
  static bool get enabled {
    if (kIsWeb) return false;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    return Platform.isIOS || Platform.isAndroid;
  }
}
