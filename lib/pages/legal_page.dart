import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/lessdo_top_bar.dart';

const privacyPolicy = '''
Effective date: June 14, 2026

LessDo is a local-first task and focus app. Version 1.0 does not collect, transmit, sell, or share personal data with the publisher or third parties. It has no account system, advertising, analytics, tracking, or remote backend.

Data stored on the device
Lists, tasks, reminders, settings, and focus history are stored locally in the app's private container. Removing the app may remove this local data. LessDo does not upload or synchronize it in version 1.0.

The app keeps a bounded diagnostic log containing event type, time, app version, platform, and technical error type. It excludes task titles, list names, notes, and exception messages. The log remains on the device unless you explicitly export it.

Optional system features
Notifications are requested only when you create or retry a reminder. Reminder text is delivered through Apple's local notification system.

Face ID or Touch ID is optional. Authentication is performed by iOS, and LessDo does not receive or store biometric data.

Sharing occurs only after you choose a share action. The user controls the destination through the iOS share sheet.

Deep links use the registered lessdo URL scheme and are validated before they can create or open local content.

Permissions
Version 1.0 may request notification and biometric authentication access. It does not request location, calendar, contacts, camera, microphone, photo library, Bluetooth, local network, or tracking permission.

Contact
Publisher support email: PUBLISHER_REQUIRED_SUPPORT_EMAIL

Public privacy policy URL: PUBLISHER_REQUIRED_PRIVACY_URL
''';

const termsOfUse = '''
Effective date: June 14, 2026

LessDo is provided as a personal productivity tool. You are responsible for reviewing tasks and reminders and should not rely on the app for emergency, medical, legal, or other safety-critical alerts.

Version 1.0 is free. It has no subscriptions, in-app purchases, or paid upgrades.

Use of the iOS version is also subject to Apple's Standard Licensed Application End User License Agreement.

The app is provided without a guarantee that reminders will be delivered when a device is powered off, permissions are disabled, or the operating system restricts background activity.
''';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LessDoTopBar(
              title: title,
              leadingIcon: CupertinoIcons.chevron_left,
              onLeading: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  SelectableText(
                    content,
                    style: const TextStyle(fontSize: 14, height: 1.55),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
