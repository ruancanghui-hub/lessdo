// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'LessDo';

  @override
  String get today => 'Today';

  @override
  String get lists => 'Lists';

  @override
  String get focus => 'Focus';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get largeText => 'Large text';

  @override
  String get largeTextSubtitle => 'More comfortable list reading';

  @override
  String get privacy => 'Privacy';

  @override
  String get faceIdLock => 'Face ID lock';

  @override
  String get faceIdLockSubtitle => 'Protect your private lists';

  @override
  String get biometricUnavailable =>
      'Biometric authentication is unavailable or was canceled.';

  @override
  String get privacyPermissions => 'Privacy & permissions';

  @override
  String get privacyPermissionsSubtitle => 'How LessDo handles your data';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get termsOfUseSubtitle => 'The terms that govern use of LessDo';

  @override
  String get themeSystem => 'System';

  @override
  String get themeSnow => 'Snow';

  @override
  String get themeMint => 'Mint';

  @override
  String get themeSky => 'Sky';

  @override
  String get themeBlush => 'Blush';

  @override
  String get editList => 'Edit List';

  @override
  String get deleteList => 'Delete List';

  @override
  String get deleteListQuestion =>
      'What should happen to the tasks in this list?';

  @override
  String get moveTasksToInbox => 'Move Tasks to Inbox';

  @override
  String get deleteTasks => 'Delete Tasks';

  @override
  String get cancel => 'Cancel';

  @override
  String get welcomeTitle => 'Welcome to LessDo';

  @override
  String get welcomeSubtitle =>
      'A calm place for tasks, reminders, and focused work.';

  @override
  String get onboardingCaptureTitle => 'Capture quickly';

  @override
  String get onboardingCaptureBody =>
      'Add a thought in seconds and organize it when you are ready.';

  @override
  String get onboardingRemindersTitle => 'Remember at the right time';

  @override
  String get onboardingRemindersBody =>
      'Optional local reminders stay on your device and work without an account.';

  @override
  String get onboardingFocusTitle => 'Make room to focus';

  @override
  String get onboardingFocusBody =>
      'Use a simple timer and keep a private history of completed sessions.';

  @override
  String get skip => 'Skip';

  @override
  String get continueAction => 'Continue';

  @override
  String get inboxEmpty => 'Inbox is empty';

  @override
  String get inboxEmptyBody => 'Add a task below when something comes to mind.';

  @override
  String thingsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things left',
      one: '1 thing left',
      zero: 'Nothing left',
    );
    return '$_temp0';
  }

  @override
  String get overdue => 'Overdue';

  @override
  String get nextReminder => 'NEXT REMINDER';

  @override
  String reminderAt(String title, String time) {
    return '$title at $time';
  }

  @override
  String get focusTime => 'Focus time';

  @override
  String get startFocusSession => 'Start a 25-minute session';

  @override
  String completedCount(int count) {
    return 'Completed · $count';
  }

  @override
  String get lockedTitle => 'LessDo is locked';

  @override
  String get lockedBody => 'Authenticate to view your lists.';

  @override
  String get authenticating => 'Authenticating';

  @override
  String get unlock => 'Unlock';
}
