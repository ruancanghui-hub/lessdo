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
  String get retry => 'Retry';

  @override
  String get couldNotSaveChanges => 'Could not save changes.';

  @override
  String get reminderSchedulingFailed => 'Reminder could not be scheduled.';

  @override
  String get clearCompleted => 'Clear completed';

  @override
  String get clearCompletedTitle => 'Clear Completed Tasks?';

  @override
  String get clearCompletedBody =>
      'This permanently deletes completed tasks from this list.';

  @override
  String get clearAction => 'Clear';

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

  @override
  String get startupLoading => 'Loading LessDo';

  @override
  String get startupFailureTitle => 'LessDo could not start';

  @override
  String get startupFailureBody =>
      'Your data was not deleted. Try again, or export a private diagnostic file for support.';

  @override
  String get exportDiagnostics => 'Export diagnostics';

  @override
  String get quickAddHint => 'What needs doing?';

  @override
  String get groceryAddHint => 'Add an item';

  @override
  String get addAction => 'Add';

  @override
  String get smartInputHint => 'Smart input understands “tomorrow at 2pm”';

  @override
  String get voiceInputHint => 'Use keyboard dictation';

  @override
  String get taskDetails => 'Task details';

  @override
  String get save => 'Save';

  @override
  String get listLabel => 'List';

  @override
  String get dateLabel => 'Date';

  @override
  String get none => 'None';

  @override
  String get reminder => 'Reminder';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get priority => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityHigh => 'High';

  @override
  String get notes => 'Notes';

  @override
  String get addNoteHint => 'Add a note…';

  @override
  String get subtasks => 'Subtasks';

  @override
  String get addSubtask => 'Add subtask';

  @override
  String get deleteTask => 'Delete task';

  @override
  String get newList => 'New list';

  @override
  String get create => 'Create';

  @override
  String get listName => 'List name';

  @override
  String get listNameHint => 'Weekend trip';

  @override
  String get standardList => 'Standard';

  @override
  String get groceryList => 'Grocery';

  @override
  String get colorLabel => 'Color';

  @override
  String get allTasks => 'All tasks';

  @override
  String get completedLabel => 'Completed';

  @override
  String tasksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String remainingCount(int count) {
    return '$count remaining';
  }

  @override
  String get everythingDone => 'Everything is done';

  @override
  String get everythingDoneBody => 'Add another item whenever you need it.';

  @override
  String get shareList => 'Share list';

  @override
  String get workingOn => 'Working on';

  @override
  String get openFocusSession => 'Open focus session';

  @override
  String get focusModePomodoro => 'Pomodoro';

  @override
  String get focusModeCountdown => 'Countdown';

  @override
  String get focusModeCountUp => 'Count up';

  @override
  String get focusLabelPomodoro => '25 min focus';

  @override
  String get focusLabelCountdown => '10 min timer';

  @override
  String get focusLabelCountUp => 'Open session';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get start => 'Start';

  @override
  String get reset => 'Reset';

  @override
  String get endSession => 'End session';

  @override
  String completeNamedTask(String title) {
    return 'Complete “$title”';
  }

  @override
  String get recentSessions => 'Recent sessions';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get emptyFocusHistory =>
      'Your completed focus sessions will appear here.';

  @override
  String get focusUpdateFailed => 'Could not update the focus session.';

  @override
  String completeTaskAccessibility(String title) {
    return 'Complete $title';
  }

  @override
  String restoreTaskAccessibility(String title) {
    return 'Restore $title';
  }

  @override
  String get otherCategory => 'Other';
}
