class FocusSession {
  const FocusSession({
    required this.id,
    required this.taskTitle,
    required this.minutes,
    required this.completedAt,
  });

  final String id;
  final String taskTitle;
  final int minutes;
  final DateTime completedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'taskTitle': taskTitle,
    'minutes': minutes,
    'completedAt': completedAt.toIso8601String(),
  };

  factory FocusSession.fromJson(Map<String, Object?> json) {
    return FocusSession(
      id: json['id']! as String,
      taskTitle: json['taskTitle']! as String,
      minutes: json['minutes']! as int,
      completedAt: DateTime.parse(json['completedAt']! as String),
    );
  }
}
