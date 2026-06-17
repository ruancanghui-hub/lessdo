import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('privacy manifest declares only the app UserDefaults reason', () {
    final manifest = File('ios/Runner/PrivacyInfo.xcprivacy');
    expect(manifest.existsSync(), isTrue);
    final contents = manifest.readAsStringSync();
    expect(contents, contains('NSPrivacyAccessedAPICategoryUserDefaults'));
    expect(contents, contains('CA92.1'));
    expect(contents, contains('<key>NSPrivacyTracking</key>'));
    expect(contents, contains('<false/>'));
    expect(contents, contains('<key>NSPrivacyCollectedDataTypes</key>'));
  });

  test('iOS permission declarations are minimal and localized', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('NSFaceIDUsageDescription'));
    for (final forbidden in [
      'NSLocation',
      'NSCalendarsUsageDescription',
      'NSCameraUsageDescription',
      'NSMicrophoneUsageDescription',
      'NSUserTrackingUsageDescription',
    ]) {
      expect(plist, isNot(contains(forbidden)));
    }

    for (final locale in ['en', 'zh-Hans']) {
      final strings = File('ios/Runner/$locale.lproj/InfoPlist.strings');
      expect(strings.existsSync(), isTrue);
      expect(strings.readAsStringSync(), contains('NSFaceIDUsageDescription'));
    }
  });

  test(
    'privacy resources and notification callbacks are in the iOS target',
    () {
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      expect(project, contains('PrivacyInfo.xcprivacy in Resources'));
      expect(project, contains('InfoPlist.strings'));

      final delegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
      expect(delegate, contains('import flutter_local_notifications'));
      expect(
        delegate,
        contains('FlutterLocalNotificationsPlugin.setPluginRegistrantCallback'),
      );
      expect(delegate, contains('UNUserNotificationCenter.current().delegate'));
    },
  );

  test('release documents match the free local-only release', () {
    final privacy = File('docs/PRIVACY_POLICY.md').readAsStringSync();
    final release = File('docs/APP_STORE_RELEASE.md').readAsStringSync();
    final metadata = File('docs/APP_STORE_METADATA.md');

    expect(privacy, contains('does not collect'));
    if (privacy.contains('DRAFT')) {
      expect(release, contains('PUBLISHER REQUIRED'));
    }
    expect(release, contains('public support URL'));
    expect(metadata.existsSync(), isTrue);

    final combined = '$privacy\n$release\n${metadata.readAsStringSync()}';
    expect(combined, isNot(contains('must add a support email')));
    expect(combined.toLowerCase(), isNot(contains('subscription')));
    expect(combined.toLowerCase(), isNot(contains('in-app purchase')));
    expect(combined, contains('No, we do not collect data from this app'));
    expect(combined, contains('lessdo://x-callback-url/create'));
    expect(combined, contains('Physical-device evidence'));
  });
}
