enum FocusMode { pomodoro, countdown, countUp }

class FocusSession {
  FocusSession({
    required this.id,
    required this.taskTitle,
    required this.minutes,
    required DateTime completedAt,
    this.mode = FocusMode.pomodoro,
    int? durationSeconds,
  }) : durationSeconds = durationSeconds ?? minutes * 60,
       completedAt = completedAt.toUtc();

  final String id;
  final String taskTitle;
  final int minutes;
  final FocusMode mode;
  final int durationSeconds;
  final DateTime completedAt;

  Map<String, Object?> toJson() => {
    'id': id,
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

class ActiveFocusSession {
  ActiveFocusSession({
    required this.id,
    required this.mode,
    required DateTime startedAt,
    this.taskId,
    DateTime? pausedAt,
    DateTime? targetAt,
    this.durationSeconds,
    this.accumulatedPaused = Duration.zero,
  }) : startedAt = startedAt.toUtc(),
       pausedAt = pausedAt?.toUtc(),
       targetAt = targetAt?.toUtc();

  final String id;
  final String? taskId;
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
    return ActiveFocusSession(
      id: id,
      taskId: taskId,
      mode: mode,
      startedAt: startedAt,
      targetAt: targetAt?.add(pausedDuration),
      durationSeconds: durationSeconds,
      accumulatedPaused: accumulatedPaused + pausedDuration,
    );
  }

  ActiveFocusSession _copyWith({DateTime? pausedAt}) {
    return ActiveFocusSession(
      id: id,
      taskId: taskId,
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
    'mode': mode.name,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'pausedAt': pausedAt?.toUtc().toIso8601String(),
    'targetAt': targetAt?.toUtc().toIso8601String(),
    'durationSeconds': durationSeconds,
    'accumulatedPausedSeconds': accumulatedPaused.inSeconds,
  };

  factory ActiveFocusSession.fromJson(Map<String, Object?> json) {
    return ActiveFocusSession(
      id: json['id']! as String,
      taskId: json['taskId'] as String?,
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
