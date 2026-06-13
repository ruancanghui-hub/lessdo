enum FocusMode { pomodoro, countdown, countUp }

class ActiveFocusSession {
  factory ActiveFocusSession._({
    required String id,
    required FocusMode mode,
    required DateTime startedAt,
    String? taskId,
    String taskTitle = '',
    DateTime? pausedAt,
    DateTime? targetAt,
    int? durationSeconds,
    Duration accumulatedPaused = Duration.zero,
  }) {
    final utcStartedAt = startedAt.toUtc();
    final utcPausedAt = pausedAt?.toUtc();
    final utcTargetAt = targetAt?.toUtc();
    _validateState(
      mode: mode,
      startedAt: utcStartedAt,
      pausedAt: utcPausedAt,
      targetAt: utcTargetAt,
      durationSeconds: durationSeconds,
      accumulatedPaused: accumulatedPaused,
    );
    return ActiveFocusSession._raw(
      id: id,
      mode: mode,
      startedAt: utcStartedAt,
      taskId: taskId,
      taskTitle: taskTitle,
      pausedAt: utcPausedAt,
      targetAt: utcTargetAt,
      durationSeconds: durationSeconds,
      accumulatedPaused: accumulatedPaused,
    );
  }

  const ActiveFocusSession._raw({
    required this.id,
    required this.mode,
    required this.startedAt,
    required this.taskId,
    required this.taskTitle,
    required this.pausedAt,
    required this.targetAt,
    required this.durationSeconds,
    required this.accumulatedPaused,
  });

  factory ActiveFocusSession.countdown({
    required String id,
    required DateTime startedAt,
    required Duration duration,
    String? taskId,
    String taskTitle = '',
  }) {
    _validateDuration(duration);
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
    _validateDuration(duration);
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
    if (pausedAt != null) {
      throw StateError('Focus session is already paused.');
    }
    final pauseAt = at.toUtc();
    if (pauseAt.isBefore(startedAt)) {
      throw ArgumentError.value(at, 'at', 'Pause cannot precede start.');
    }
    return _copyWith(pausedAt: pauseAt);
  }

  ActiveFocusSession resume(DateTime at) {
    if (pausedAt == null) {
      throw StateError('Focus session is not paused.');
    }
    final resumedAt = at.toUtc();
    if (resumedAt.isBefore(pausedAt!)) {
      throw ArgumentError.value(at, 'at', 'Resume cannot precede pause.');
    }
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
    'accumulatedPausedMicroseconds': accumulatedPaused.inMicroseconds,
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
        microseconds:
            (json['accumulatedPausedMicroseconds'] as int?) ??
            ((json['accumulatedPausedSeconds'] as int?) ?? 0) *
                Duration.microsecondsPerSecond,
      ),
    );
  }

  static DateTime? _date(Object? value) {
    return value is String && value.isNotEmpty ? DateTime.parse(value) : null;
  }

  static void _validateDuration(Duration duration) {
    if (duration.inSeconds <= 0) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Duration must be at least one second.',
      );
    }
  }

  static void _validateState({
    required FocusMode mode,
    required DateTime startedAt,
    required DateTime? pausedAt,
    required DateTime? targetAt,
    required int? durationSeconds,
    required Duration accumulatedPaused,
  }) {
    if (accumulatedPaused.isNegative) {
      throw ArgumentError.value(
        accumulatedPaused,
        'accumulatedPaused',
        'Accumulated pause cannot be negative.',
      );
    }
    if (pausedAt != null && pausedAt.isBefore(startedAt)) {
      throw ArgumentError.value(
        pausedAt,
        'pausedAt',
        'Pause cannot precede start.',
      );
    }

    if (mode == FocusMode.countUp) {
      if (targetAt != null || durationSeconds != null) {
        throw ArgumentError(
          'Count-up sessions cannot have a target or duration.',
        );
      }
      return;
    }

    if (durationSeconds == null || durationSeconds <= 0) {
      throw ArgumentError.value(
        durationSeconds,
        'durationSeconds',
        'Timed sessions require a positive duration.',
      );
    }
    final expectedTarget = startedAt
        .add(Duration(seconds: durationSeconds))
        .add(accumulatedPaused);
    if (targetAt == null || targetAt != expectedTarget) {
      throw ArgumentError.value(
        targetAt,
        'targetAt',
        'Target must match start, duration, and accumulated pause.',
      );
    }
  }
}
