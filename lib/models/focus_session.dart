import 'active_focus_session.dart';

class FocusSession {
  FocusSession({
    required this.id,
    this.taskId,
    required this.taskTitle,
    required this.minutes,
    required DateTime completedAt,
    this.mode = FocusMode.pomodoro,
    int? durationSeconds,
  }) : durationSeconds = durationSeconds ?? minutes * 60,
       completedAt = completedAt.toUtc();

  final String id;
  final String? taskId;
  final String taskTitle;
  final int minutes;
  final FocusMode mode;
  final int durationSeconds;
  final DateTime completedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'taskId': taskId,
    'taskTitle': taskTitle,
    'minutes': minutes,
    'mode': mode.name,
    'durationSeconds': durationSeconds,
    'completedAt': completedAt.toUtc().toIso8601String(),
  };

  factory FocusSession.fromJson(Map<String, Object?> json) {
    final minutes = json['minutes']! as int;
    return FocusSession(
      id: json['id']! as String,
      taskId: json['taskId'] as String?,
      taskTitle: json['taskTitle']! as String,
      minutes: minutes,
      mode: FocusMode.values.byName(
        (json['mode'] as String?) ?? FocusMode.pomodoro.name,
      ),
      durationSeconds: (json['durationSeconds'] as int?) ?? minutes * 60,
      completedAt: DateTime.parse(json['completedAt']! as String),
    );
  }
}
