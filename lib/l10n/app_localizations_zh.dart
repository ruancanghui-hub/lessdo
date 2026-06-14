// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'LessDo';

  @override
  String get today => '今天';

  @override
  String get lists => '清单';

  @override
  String get focus => '专注';

  @override
  String get settings => '设置';

  @override
  String get appearance => '外观';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get largeText => '大号文字';

  @override
  String get largeTextSubtitle => '更舒适地阅读清单';

  @override
  String get privacy => '隐私';

  @override
  String get faceIdLock => 'Face ID 锁定';

  @override
  String get faceIdLockSubtitle => '保护你的私人清单';

  @override
  String get biometricUnavailable => '生物识别不可用或验证已取消。';

  @override
  String get privacyPermissions => '隐私与权限';

  @override
  String get privacyPermissionsSubtitle => 'LessDo 如何处理你的数据';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get termsOfUse => '使用条款';

  @override
  String get termsOfUseSubtitle => '使用 LessDo 时适用的条款';

  @override
  String get themeSystem => '系统';

  @override
  String get themeSnow => '雪白';

  @override
  String get themeMint => '薄荷';

  @override
  String get themeSky => '天空';

  @override
  String get themeBlush => '浅绯';

  @override
  String get welcomeTitle => '欢迎使用 LessDo';

  @override
  String get welcomeSubtitle => '安静地管理任务、提醒与专注时间。';

  @override
  String get onboardingCaptureTitle => '快速记录';

  @override
  String get onboardingCaptureBody => '几秒钟记下一件事，准备好时再整理。';

  @override
  String get onboardingRemindersTitle => '在合适的时间提醒';

  @override
  String get onboardingRemindersBody => '可选的本地提醒保存在设备上，无需账户也能使用。';

  @override
  String get onboardingFocusTitle => '留出专注时间';

  @override
  String get onboardingFocusBody => '使用简单的计时器，并在设备上保留私人专注记录。';

  @override
  String get skip => '跳过';

  @override
  String get continueAction => '继续';

  @override
  String get inboxEmpty => '收件箱是空的';

  @override
  String get inboxEmptyBody => '想到事情时，可以在下方添加任务。';

  @override
  String thingsLeft(int count) {
    return '还剩 $count 件事';
  }

  @override
  String get overdue => '已逾期';

  @override
  String get nextReminder => '下一个提醒';

  @override
  String reminderAt(String title, String time) {
    return '$title，$time';
  }

  @override
  String get focusTime => '专注时间';

  @override
  String get startFocusSession => '开始 25 分钟专注';

  @override
  String completedCount(int count) {
    return '已完成 · $count';
  }

  @override
  String get lockedTitle => 'LessDo 已锁定';

  @override
  String get lockedBody => '验证身份后查看你的清单。';

  @override
  String get authenticating => '正在验证';

  @override
  String get unlock => '解锁';
}
