import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free release excludes purchase code and future feature plugins', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('in_app_purchase:')));
    expect(pubspec, contains('google_mobile_ads:'));
    expect(File('lib/services/purchase_service.dart').existsSync(), isFalse);
  });

  test('iOS deployment target is 16', () {
    final podfile = File('ios/Podfile').readAsStringSync();
    expect(podfile, contains("platform :ios, '16.0'"));

    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final deploymentTargets = RegExp(
      r'IPHONEOS_DEPLOYMENT_TARGET = ([^;]+);',
    ).allMatches(project).map((match) => match.group(1)).toList();
    expect(deploymentTargets, hasLength(3));
    expect(deploymentTargets, everyElement('16.0'));
  });

  test('Apple plugin lockfiles match the free release dependencies', () {
    final iosLock = File('ios/Podfile.lock').readAsStringSync();
    expect(iosLock, isNot(contains('in_app_purchase_storekit')));

    final macosLock = File('macos/Podfile.lock').readAsStringSync();
    expect(macosLock, isNot(contains('in_app_purchase_storekit')));
    expect(macosLock, contains('sqflite_darwin'));
  });
}
