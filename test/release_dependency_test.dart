import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free release excludes purchase code and future feature plugins', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('in_app_purchase:')));
    expect(File('lib/services/purchase_service.dart').existsSync(), isFalse);
  });

  test('iOS deployment target is 16', () {
    final podfile = File('ios/Podfile').readAsStringSync();
    expect(podfile, contains("platform :ios, '16.0'"));
  });
}
