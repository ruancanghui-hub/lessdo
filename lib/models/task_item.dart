enum TaskPriority { low, normal, high }

enum RepeatRule { none, daily, weekly, monthly }

class SubTask {
  const SubTask({
    required this.id,
    required this.title,
    this.completed = false,
  });

  final String id;
  final String title;
  final bool completed;

  SubTask copyWith({String? title, bool? completed}) {
    return SubTask(
      id: id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
  };

  factory SubTask.fromJson(Map<String, Object?> json) {
    return SubTask(
      id: json['id']! as String,
      title: json['title']! as String,
      completed: (json['completed'] as bool?) ?? false,
    );
  }
}

class TaskItem {
  factory TaskItem({
    required String id,
    required String title,
    required String listId,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? dueAt,
    DateTime? reminderAt,
    String notes = '',
    TaskPriority priority = TaskPriority.normal,
    RepeatRule repeatRule = RepeatRule.none,
    String category = '',
    List<SubTask> subtasks = const [],
    bool completed = false,
    DateTime? completedAt,
    int sortOrder = 0,
    bool reminderSchedulingFailed = false,
  }) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Task title cannot be empty.');
    }
    return TaskItem._(
      id: id,
      title: cleanTitle,
      listId: listId,
      createdAt: createdAt.toUtc(),
      updatedAt: (updatedAt ?? createdAt).toUtc(),
      dueAt: dueAt?.toUtc(),
      reminderAt: reminderAt?.toUtc(),
      notes: notes,
      priority: priority,
      repeatRule: repeatRule,
      category: category,
      subtasks: List<SubTask>.unmodifiable(subtasks),
      completed: completed,
      completedAt: completedAt?.toUtc(),
      sortOrder: sortOrder,
      reminderSchedulingFailed: reminderSchedulingFailed,
    );
  }

  const TaskItem._({
    required this.id,
    required this.title,
    required this.listId,
    required this.createdAt,
    required this.updatedAt,
    required this.dueAt,
    required this.reminderAt,
    required this.notes,
    required this.priority,
    required this.repeatRule,
    required this.category,
    required this.subtasks,
    required this.completed,
    required this.completedAt,
    required this.sortOrder,
    required this.reminderSchedulingFailed,
  });

  factory TaskItem.create({
    required String id,
    required String title,
    required String listId,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? dueAt,
    DateTime? reminderAt,
    String notes = '',
    TaskPriority priority = TaskPriority.normal,
    RepeatRule repeatRule = RepeatRule.none,
    String category = '',
    List<SubTask> subtasks = const [],
    bool completed = false,
    DateTime? completedAt,
    int sortOrder = 0,
    bool reminderSchedulingFailed = false,
  }) {
    return TaskItem(
      id: id,
      title: title,
      listId: listId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      dueAt: dueAt,
      reminderAt: reminderAt,
      notes: notes,
      priority: priority,
      repeatRule: repeatRule,
      category: category,
      subtasks: subtasks,
      completed: completed,
      completedAt: completedAt,
      sortOrder: sortOrder,
      reminderSchedulingFailed: reminderSchedulingFailed,
    );
  }

  final String id;
  final String title;
  final String listId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueAt;
  final DateTime? reminderAt;
  final String notes;
  final TaskPriority priority;
  final RepeatRule repeatRule;
  final String category;
  final List<SubTask> subtasks;
  final bool completed;
  final DateTime? completedAt;
  final int sortOrder;
  final bool reminderSchedulingFailed;

  DateTime? get dueAtLocal => dueAt?.toLocal();

  DateTime? get reminderAtLocal => reminderAt?.toLocal();

  bool get overdue => isOverdue(DateTime.now());

  bool get dueToday => dueAt == null || isDueToday(DateTime.now());

  bool isOverdue(DateTime nowLocal) {
    final localDue = dueAt?.toLocal();
    return !completed &&
        localDue != null &&
        localDue.isBefore(nowLocal) &&
        !isSameCalendarDay(localDue, nowLocal);
  }

  bool isDueToday(DateTime nowLocal) =>
      dueAt != null && isSameCalendarDay(dueAt!.toLocal(), nowLocal);

  TaskItem copyWith({
    String? title,
    String? listId,
    DateTime? dueAt,
    bool clearDueAt = false,
    DateTime? reminderAt,
    bool clearReminderAt = false,
    String? notes,
    TaskPriority? priority,
    RepeatRule? repeatRule,
    String? category,
    List<SubTask>? subtasks,
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? updatedAt,
    int? sortOrder,
    bool? reminderSchedulingFailed,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      listId: listId ?? this.listId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueAt: clearDueAt ? null : dueAt ?? this.dueAt,
      reminderAt: clearReminderAt ? null : reminderAt ?? this.reminderAt,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      repeatRule: repeatRule ?? this.repeatRule,
      category: category ?? this.category,
      subtasks: subtasks ?? this.subtasks,
      completed: completed ?? this.completed,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      reminderSchedulingFailed:
          reminderSchedulingFailed ?? this.reminderSchedulingFailed,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'listId': listId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'dueAt': dueAt?.toUtc().toIso8601String(),
    'reminderAt': reminderAt?.toUtc().toIso8601String(),
    'notes': notes,
    'priority': priority.name,
    'repeatRule': repeatRule.name,
    'category': category,
    'subtasks': subtasks.map((item) => item.toJson()).toList(),
    'completed': completed,
    'completedAt': completedAt?.toUtc().toIso8601String(),
    'sortOrder': sortOrder,
    'reminderSchedulingFailed': reminderSchedulingFailed,
  };

  factory TaskItem.fromJson(Map<String, Object?> json) {
    final rawSubtasks = (json['subtasks'] as List<Object?>?) ?? const [];
    return TaskItem(
      id: json['id']! as String,
      title: json['title']! as String,
      listId: json['listId']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
      updatedAt:
          _date(json['updatedAt']) ??
          DateTime.parse(json['createdAt']! as String).toUtc(),
      dueAt: _date(json['dueAt']),
      reminderAt: _date(json['reminderAt']),
      notes: (json['notes'] as String?) ?? '',
      priority: TaskPriority.values.byName(
        (json['priority'] as String?) ?? TaskPriority.normal.name,
      ),
      repeatRule: RepeatRule.values.byName(
        (json['repeatRule'] as String?) ?? RepeatRule.none.name,
      ),
      category: (json['category'] as String?) ?? '',
      subtasks: rawSubtasks
          .map(
            (item) => SubTask.fromJson(Map<String, Object?>.from(item! as Map)),
          )
          .toList(),
      completed: (json['completed'] as bool?) ?? false,
      completedAt: _date(json['completedAt']),
      sortOrder: (json['sortOrder'] as int?) ?? 0,
      reminderSchedulingFailed:
          (json['reminderSchedulingFailed'] as bool?) ?? false,
    );
  }

  static DateTime? _date(Object? value) {
    return value is String && value.isNotEmpty
        ? DateTime.parse(value).toUtc()
        : null;
  }
}

bool isSameCalendarDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
