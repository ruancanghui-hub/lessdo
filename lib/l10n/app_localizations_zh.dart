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
  String get editList => '编辑清单';

  @override
  String get deleteList => '删除清单';

  @override
  String get deleteListQuestion => '这个清单中的任务要如何处理？';

  @override
  String get moveTasksToInbox => '移到收件箱';

  @override
  String get deleteTasks => '同时删除任务';

  @override
  String get cancel => '取消';

  @override
  String get retry => '重试';

  @override
  String get couldNotSaveChanges => '无法保存更改。';

  @override
  String get reminderSchedulingFailed => '提醒无法安排。';

  @override
  String get clearCompleted => '清除已完成';

  @override
  String get clearCompletedTitle => '清除已完成任务？';

  @override
  String get clearCompletedBody => '这会永久删除此清单中已完成的任务。';

  @override
  String get clearAction => '清除';

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

  @override
  String get startupLoading => '正在载入 LessDo';

  @override
  String get startupFailureTitle => 'LessDo 无法启动';

  @override
  String get startupFailureBody => '你的数据没有被删除。请重试，或导出不含任务内容的诊断文件以便获取支持。';

  @override
  String get exportDiagnostics => '导出诊断文件';

  @override
  String get quickAddHint => '要做什么？';

  @override
  String get groceryAddHint => '添加物品';

  @override
  String get addAction => '添加';

  @override
  String get smartInputHint => '智能输入支持“明天下午 2 点”';

  @override
  String get taskDetails => '任务详情';

  @override
  String get save => '保存';

  @override
  String get listLabel => '清单';

  @override
  String get dateLabel => '日期';

  @override
  String get none => '无';

  @override
  String get reminder => '提醒';

  @override
  String get repeat => '重复';

  @override
  String get repeatDaily => '每天';

  @override
  String get repeatWeekly => '每周';

  @override
  String get repeatMonthly => '每月';

  @override
  String get priority => '优先级';

  @override
  String get priorityLow => '低';

  @override
  String get priorityNormal => '普通';

  @override
  String get priorityHigh => '高';

  @override
  String get notes => '备注';

  @override
  String get addNoteHint => '添加备注…';

  @override
  String get subtasks => '子任务';

  @override
  String get addSubtask => '添加子任务';

  @override
  String get deleteTask => '删除任务';

  @override
  String get newList => '新建清单';

  @override
  String get create => '创建';

  @override
  String get listName => '清单名称';

  @override
  String get listNameHint => '周末旅行';

  @override
  String get standardList => '标准清单';

  @override
  String get groceryList => '购物清单';

  @override
  String get colorLabel => '颜色';

  @override
  String get allTasks => '所有任务';

  @override
  String get completedLabel => '已完成';

  @override
  String tasksCount(int count) {
    return '$count 个任务';
  }

  @override
  String remainingCount(int count) {
    return '还剩 $count 个';
  }

  @override
  String get everythingDone => '全部完成';

  @override
  String get everythingDoneBody => '需要时可以继续添加任务。';

  @override
  String get shareList => '分享清单';

  @override
  String get workingOn => '正在处理';

  @override
  String get openFocusSession => '开放式专注';

  @override
  String get focusModePomodoro => '番茄钟';

  @override
  String get focusModeCountdown => '倒计时';

  @override
  String get focusModeCountUp => '正计时';

  @override
  String get focusLabelPomodoro => '25 分钟专注';

  @override
  String get focusLabelCountdown => '10 分钟计时';

  @override
  String get focusLabelCountUp => '开放式专注';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get start => '开始';

  @override
  String get reset => '重置';

  @override
  String get endSession => '结束专注';

  @override
  String completeNamedTask(String title) {
    return '完成“$title”';
  }

  @override
  String get recentSessions => '最近专注';

  @override
  String minutesShort(int count) {
    return '$count 分钟';
  }

  @override
  String get emptyFocusHistory => '完成的专注记录会显示在这里。';

  @override
  String get focusUpdateFailed => '无法更新专注状态。';

  @override
  String completeTaskAccessibility(String title) {
    return '完成 $title';
  }

  @override
  String restoreTaskAccessibility(String title) {
    return '恢复 $title';
  }

  @override
  String get otherCategory => '其他';
}
