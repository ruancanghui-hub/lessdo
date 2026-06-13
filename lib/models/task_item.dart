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
  const TaskItem({
    required this.id,
    required this.title,
    required this.listId,
    required this.createdAt,
    this.dueAt,
    this.reminderAt,
    this.notes = '',
    this.priority = TaskPriority.normal,
    this.repeatRule = RepeatRule.none,
    this.locationReminder = false,
    this.locationName = '',
    this.category = '',
    this.subtasks = const [],
    this.completed = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final String listId;
  final DateTime createdAt;
  final DateTime? dueAt;
  final DateTime? reminderAt;
  final String notes;
  final TaskPriority priority;
  final RepeatRule repeatRule;
  final bool locationReminder;
  final String locationName;
  final String category;
  final List<SubTask> subtasks;
  final bool completed;
  final DateTime? completedAt;

  bool get overdue =>
      !completed &&
      dueAt != null &&
      dueAt!.isBefore(DateTime.now()) &&
      !isSameDay(dueAt!, DateTime.now());

  bool get dueToday => dueAt == null || isSameDay(dueAt!, DateTime.now());

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
    bool? locationReminder,
    String? locationName,
    String? category,
    List<SubTask>? subtasks,
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      listId: listId ?? this.listId,
      createdAt: createdAt,
      dueAt: clearDueAt ? null : dueAt ?? this.dueAt,
      reminderAt: clearReminderAt ? null : reminderAt ?? this.reminderAt,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      repeatRule: repeatRule ?? this.repeatRule,
      locationReminder: locationReminder ?? this.locationReminder,
      locationName: locationName ?? this.locationName,
      category: category ?? this.category,
      subtasks: subtasks ?? this.subtasks,
      completed: completed ?? this.completed,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'listId': listId,
    'createdAt': createdAt.toIso8601String(),
    'dueAt': dueAt?.toIso8601String(),
    'reminderAt': reminderAt?.toIso8601String(),
    'notes': notes,
    'priority': priority.name,
    'repeatRule': repeatRule.name,
    'locationReminder': locationReminder,
    'locationName': locationName,
    'category': category,
    'subtasks': subtasks.map((item) => item.toJson()).toList(),
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory TaskItem.fromJson(Map<String, Object?> json) {
    final rawSubtasks = (json['subtasks'] as List<Object?>?) ?? const [];
    return TaskItem(
      id: json['id']! as String,
      title: json['title']! as String,
      listId: json['listId']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      dueAt: _date(json['dueAt']),
      reminderAt: _date(json['reminderAt']),
      notes: (json['notes'] as String?) ?? '',
      priority: TaskPriority.values.byName(
        (json['priority'] as String?) ?? TaskPriority.normal.name,
      ),
      repeatRule: RepeatRule.values.byName(
        (json['repeatRule'] as String?) ?? RepeatRule.none.name,
      ),
      locationReminder: (json['locationReminder'] as bool?) ?? false,
      locationName: (json['locationName'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      subtasks: rawSubtasks
          .map(
            (item) => SubTask.fromJson(Map<String, Object?>.from(item! as Map)),
          )
          .toList(),
      completed: (json['completed'] as bool?) ?? false,
      completedAt: _date(json['completedAt']),
    );
  }

  static DateTime? _date(Object? value) {
    return value is String && value.isNotEmpty ? DateTime.parse(value) : null;
  }
}

bool isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
