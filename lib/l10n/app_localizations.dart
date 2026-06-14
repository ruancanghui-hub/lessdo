import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'LessDo'**
  String get appName;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @lists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get lists;

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSimplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageSimplifiedChinese;

  /// No description provided for @largeText.
  ///
  /// In en, this message translates to:
  /// **'Large text'**
  String get largeText;

  /// No description provided for @largeTextSubtitle.
  ///
  /// In en, this message translates to:
  /// **'More comfortable list reading'**
  String get largeTextSubtitle;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @faceIdLock.
  ///
  /// In en, this message translates to:
  /// **'Face ID lock'**
  String get faceIdLock;

  /// No description provided for @faceIdLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protect your private lists'**
  String get faceIdLockSubtitle;

  /// No description provided for @biometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is unavailable or was canceled.'**
  String get biometricUnavailable;

  /// No description provided for @privacyPermissions.
  ///
  /// In en, this message translates to:
  /// **'Privacy & permissions'**
  String get privacyPermissions;

  /// No description provided for @privacyPermissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How LessDo handles your data'**
  String get privacyPermissionsSubtitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @termsOfUseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The terms that govern use of LessDo'**
  String get termsOfUseSubtitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get themeSnow;

  /// No description provided for @themeMint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get themeMint;

  /// No description provided for @themeSky.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get themeSky;

  /// No description provided for @themeBlush.
  ///
  /// In en, this message translates to:
  /// **'Blush'**
  String get themeBlush;

  /// No description provided for @editList.
  ///
  /// In en, this message translates to:
  /// **'Edit List'**
  String get editList;

  /// No description provided for @deleteList.
  ///
  /// In en, this message translates to:
  /// **'Delete List'**
  String get deleteList;

  /// No description provided for @deleteListQuestion.
  ///
  /// In en, this message translates to:
  /// **'What should happen to the tasks in this list?'**
  String get deleteListQuestion;

  /// No description provided for @moveTasksToInbox.
  ///
  /// In en, this message translates to:
  /// **'Move Tasks to Inbox'**
  String get moveTasksToInbox;

  /// No description provided for @deleteTasks.
  ///
  /// In en, this message translates to:
  /// **'Delete Tasks'**
  String get deleteTasks;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to LessDo'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A calm place for tasks, reminders, and focused work.'**
  String get welcomeSubtitle;

  /// No description provided for @onboardingCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture quickly'**
  String get onboardingCaptureTitle;

  /// No description provided for @onboardingCaptureBody.
  ///
  /// In en, this message translates to:
  /// **'Add a thought in seconds and organize it when you are ready.'**
  String get onboardingCaptureBody;

  /// No description provided for @onboardingRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Remember at the right time'**
  String get onboardingRemindersTitle;

  /// No description provided for @onboardingRemindersBody.
  ///
  /// In en, this message translates to:
  /// **'Optional local reminders stay on your device and work without an account.'**
  String get onboardingRemindersBody;

  /// No description provided for @onboardingFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Make room to focus'**
  String get onboardingFocusTitle;

  /// No description provided for @onboardingFocusBody.
  ///
  /// In en, this message translates to:
  /// **'Use a simple timer and keep a private history of completed sessions.'**
  String get onboardingFocusBody;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'Inbox is empty'**
  String get inboxEmpty;

  /// No description provided for @inboxEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a task below when something comes to mind.'**
  String get inboxEmptyBody;

  /// No description provided for @thingsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing left} =1{1 thing left} other{{count} things left}}'**
  String thingsLeft(int count);

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @nextReminder.
  ///
  /// In en, this message translates to:
  /// **'NEXT REMINDER'**
  String get nextReminder;

  /// No description provided for @reminderAt.
  ///
  /// In en, this message translates to:
  /// **'{title} at {time}'**
  String reminderAt(String title, String time);

  /// No description provided for @focusTime.
  ///
  /// In en, this message translates to:
  /// **'Focus time'**
  String get focusTime;

  /// No description provided for @startFocusSession.
  ///
  /// In en, this message translates to:
  /// **'Start a 25-minute session'**
  String get startFocusSession;

  /// No description provided for @completedCount.
  ///
  /// In en, this message translates to:
  /// **'Completed · {count}'**
  String completedCount(int count);

  /// No description provided for @lockedTitle.
  ///
  /// In en, this message translates to:
  /// **'LessDo is locked'**
  String get lockedTitle;

  /// No description provided for @lockedBody.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to view your lists.'**
  String get lockedBody;

  /// No description provided for @authenticating.
  ///
  /// In en, this message translates to:
  /// **'Authenticating'**
  String get authenticating;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
