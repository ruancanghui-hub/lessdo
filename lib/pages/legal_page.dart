import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/lessdo_top_bar.dart';

const privacyPolicy = '''
Effective date: June 13, 2026

LessDo is designed as a local-first productivity app.

Data storage
Your lists, tasks, settings, and focus history are stored on your device. LessDo does not require an account and does not operate an analytics or advertising backend in version 1.0.

Notifications and biometrics
Notification permission is used only to deliver reminders you create. Biometric authentication is handled by the operating system; LessDo does not receive or store biometric data.

Purchases
Optional purchases are processed by Apple App Store or Google Play. LessDo receives purchase status but not your full payment-card details.

Sharing
List content leaves the app only when you choose the system Share command.

Data deletion
Deleting tasks removes them from the app. Uninstalling LessDo removes locally stored app data, subject to your device backup settings.

Contact
Before public release, the publisher will provide a support email and a hosted copy of this policy in the store listing.
''';

const termsOfUse = '''
Effective date: June 13, 2026

LessDo is provided as a personal productivity tool. You are responsible for reviewing tasks and reminders and should not rely on the app for emergency, medical, legal, or other safety-critical alerts.

Optional subscriptions renew automatically unless canceled through your store account at least 24 hours before the end of the current period. Available products, prices, trial eligibility, and renewal terms are shown by the store before purchase.

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
