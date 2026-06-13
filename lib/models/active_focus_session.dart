enum FocusMode { pomodoro, countdown, countUp }

class ActiveFocusSession {
  ActiveFocusSession._({
    required this.id,
    required this.mode,
    required DateTime startedAt,
    this.taskId,
    this.taskTitle = '',
    DateTime? pausedAt,
    DateTime? targetAt,
    this.durationSeconds,
    this.accumulatedPaused = Duration.zero,
  }) : startedAt = startedAt.toUtc(),
       pausedAt = pausedAt?.toUtc(),
       targetAt = targetAt?.toUtc();

  factory ActiveFocusSession.countdown({
    required String id,
    required DateTime startedAt,
    required Duration duration,
    String? taskId,
    String taskTitle = '',
  }) {
    return ActiveFocusSession._(
      id: id,
      taskId: taskId,
      taskTitle: taskTitle,
      mode: FocusMode.countdown,
      startedAt: startedAt,
      targetAt: startedAt.add(duration),
      durationSeconds: duration.inSeconds,
    );
  }

  factory ActiveFocusSession.pomodoro({
    required String id,
    required DateTime startedAt,
    required Duration duration,
    String? taskId,
    String taskTitle = '',
  }) {
    return ActiveFocusSession._(
      id: id,
      taskId: taskId,
      taskTitle: taskTitle,
      mode: FocusMode.pomodoro,
      startedAt: startedAt,
      targetAt: startedAt.add(duration),
      durationSeconds: duration.inSeconds,
    );
  }

  factory ActiveFocusSession.countUp({
    required String id,
    required DateTime startedAt,
    String? taskId,
    String taskTitle = '',
  }) {
    return ActiveFocusSession._(
      id: id,
      taskId: taskId,
      taskTitle: taskTitle,
      mode: FocusMode.countUp,
      startedAt: startedAt,
    );
  }

  final String id;
  final String? taskId;
  final String taskTitle;
  final FocusMode mode;
  final DateTime startedAt;
  final DateTime? pausedAt;
  final DateTime? targetAt;
  final int? durationSeconds;
  final Duration accumulatedPaused;

  Duration elapsedAt(DateTime now) {
    final effectiveNow = pausedAt ?? now.toUtc();
    final elapsed = effectiveNow.difference(startedAt) - accumulatedPaused;
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  Duration remainingAt(DateTime now) {
    if (mode == FocusMode.countUp) return Duration.zero;
    final effectiveNow = pausedAt ?? now.toUtc();
    final remaining = targetAt != null
        ? targetAt!.difference(effectiveNow)
        : Duration(seconds: durationSeconds ?? 0) - elapsedAt(effectiveNow);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  ActiveFocusSession pause(DateTime at) {
    if (pausedAt != null) return this;
    return _copyWith(pausedAt: at.toUtc());
  }

  ActiveFocusSession resume(DateTime at) {
    if (pausedAt == null) return this;
    final resumedAt = at.toUtc();
    final pausedDuration = resumedAt.difference(pausedAt!);
    return ActiveFocusSession._(
      id: id,
      taskId: taskId,
      taskTitle: taskTitle,
      mode: mode,
      startedAt: startedAt,
      targetAt: targetAt?.add(pausedDuration),
      durationSeconds: durationSeconds,
      accumulatedPaused: accumulatedPaused + pausedDuration,
    );
  }

  ActiveFocusSession _copyWith({DateTime? pausedAt}) {
    return ActiveFocusSession._(
      id: id,
      taskId: taskId,
      taskTitle: taskTitle,
      mode: mode,
      startedAt: startedAt,
      pausedAt: pausedAt,
      targetAt: targetAt,
      durationSeconds: durationSeconds,
      accumulatedPaused: accumulatedPaused,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'taskId': taskId,
    'taskTitle': taskTitle,
    'mode': mode.name,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'pausedAt': pausedAt?.toUtc().toIso8601String(),
    'targetAt': targetAt?.toUtc().toIso8601String(),
    'durationSeconds': durationSeconds,
    'accumulatedPausedSeconds': accumulatedPaused.inSeconds,
  };

  factory ActiveFocusSession.fromJson(Map<String, Object?> json) {
    return ActiveFocusSession._(
      id: json['id']! as String,
      taskId: json['taskId'] as String?,
      taskTitle: (json['taskTitle'] as String?) ?? '',
      mode: FocusMode.values.byName(json['mode']! as String),
      startedAt: DateTime.parse(json['startedAt']! as String),
      pausedAt: _date(json['pausedAt']),
      targetAt: _date(json['targetAt']),
      durationSeconds: json['durationSeconds'] as int?,
      accumulatedPaused: Duration(
        seconds: (json['accumulatedPausedSeconds'] as int?) ?? 0,
      ),
    );
  }

  static DateTime? _date(Object? value) {
    return value is String && value.isNotEmpty ? DateTime.parse(value) : null;
  }
}
