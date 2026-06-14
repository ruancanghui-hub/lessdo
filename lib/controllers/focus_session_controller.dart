import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/task_repository.dart';
import '../models/active_focus_session.dart';
import '../models/focus_session.dart';
import '../notifications/notification_coordinator.dart';

typedef FocusCompletionCallback =
    Future<void> Function(FocusSession history, String? completedTaskId);
typedef FocusWarningCallback = void Function(FocusSessionWarning warning);

class FocusSessionWarning {
  const FocusSessionWarning({
    required this.operation,
    required this.sessionId,
    required this.cause,
  });

  final String operation;
  final String sessionId;
  final Object cause;
}

class FocusSessionController extends ChangeNotifier {
  FocusSessionController({
    required TaskRepository repository,
    required FocusNotificationCoordinatorContract notifications,
    DateTime Function()? clock,
    String Function()? idFactory,
    FocusCompletionCallback? onCompleted,
    FocusWarningCallback? onWarning,
  }) : _repository = repository,
       _notifications = notifications,
       _clock = clock ?? DateTime.now,
       _idFactory = idFactory ?? const Uuid().v4,
       _onCompleted = onCompleted,
       _onWarning = onWarning;

  final TaskRepository _repository;
  final FocusNotificationCoordinatorContract _notifications;
  final DateTime Function() _clock;
  final String Function() _idFactory;
  final FocusCompletionCallback? _onCompleted;
  final FocusWarningCallback? _onWarning;

  ActiveFocusSession? _activeSession;
  List<FocusSession> _history = const [];
  Future<void> _mutationQueue = Future.value();
  Future<void>? _loadFuture;
  Future<FocusSession?>? _completionFuture;
  String? _lastCompletedSessionId;
  int _pendingMutations = 0;
  FocusSessionWarning? _lastWarning;

  ActiveFocusSession? get activeSession => _activeSession;
  List<FocusSession> get history => _history;
  bool get isRunning =>
      _activeSession != null && _activeSession!.pausedAt == null;
  bool get isPaused => _activeSession?.pausedAt != null;
  bool get isCompleting => _completionFuture != null;
  bool get isMutating => _pendingMutations > 0;
  String? get lastCompletedSessionId => _lastCompletedSessionId;
  FocusSessionWarning? get lastWarning => _lastWarning;

  Duration get elapsed => _activeSession?.elapsedAt(_clock()) ?? Duration.zero;

  Duration get remaining =>
      _activeSession?.remainingAt(_clock()) ?? Duration.zero;

  Future<void> load() {
    final active = _loadFuture;
    if (active != null) return active;
    final future = _enqueue(_load);
    _loadFuture = future;
    future.then(
      (_) => _clearLoad(future),
      onError: (_, _) => _clearLoad(future),
    );
    return future;
  }

  void _clearLoad(Future<void> future) {
    if (identical(_loadFuture, future)) _loadFuture = null;
  }

  Future<void> _load() async {
    await _retryWarningCleanup();
    final values = await Future.wait<Object?>([
      _repository.loadActiveFocus(),
      _repository.loadFocusHistory(),
    ]);
    _activeSession = values[0] as ActiveFocusSession?;
    _history = List.unmodifiable(values[1]! as List<FocusSession>);
    notifyListeners();
    final session = _activeSession;
    if (session == null) return;
    if (_isExpired(session)) {
      await _complete(completeTask: false);
    } else if (session.pausedAt == null && session.mode != FocusMode.countUp) {
      await _scheduleFocusSafely(session, requestPermission: false);
    } else {
      await _cancelFocusSafely(session.id);
    }
  }

  Future<void> startPomodoro(
    Duration duration, {
    String? taskId,
    String taskTitle = '',
  }) {
    return _start(
      ActiveFocusSession.pomodoro(
        id: _idFactory(),
        startedAt: _clock(),
        duration: duration,
        taskId: taskId,
        taskTitle: taskTitle,
      ),
    );
  }

  Future<void> startCountdown(
    Duration duration, {
    String? taskId,
    String taskTitle = '',
  }) {
    return _start(
      ActiveFocusSession.countdown(
        id: _idFactory(),
        startedAt: _clock(),
        duration: duration,
        taskId: taskId,
        taskTitle: taskTitle,
      ),
    );
  }

  Future<void> startCountUp({String? taskId, String taskTitle = ''}) {
    return _start(
      ActiveFocusSession.countUp(
        id: _idFactory(),
        startedAt: _clock(),
        taskId: taskId,
        taskTitle: taskTitle,
      ),
    );
  }

  Future<void> _start(ActiveFocusSession session) {
    return _enqueue(() async {
      final previous = _activeSession;
      if (previous != null) {
        await _cancelFocusSafely(previous.id);
      }
      await _repository.saveActiveFocus(session);
      _activeSession = session;
      notifyListeners();
      if (session.mode != FocusMode.countUp) {
        await _scheduleFocusSafely(session);
      }
    });
  }

  Future<void> pause() {
    return _enqueue(() async {
      final session = _activeSession;
      if (session == null || session.pausedAt != null) return;
      final paused = session.pause(_clock());
      await _repository.saveActiveFocus(paused);
      _activeSession = paused;
      notifyListeners();
      await _cancelFocusSafely(session.id);
    });
  }

  Future<void> resume() {
    return _enqueue(() async {
      final session = _activeSession;
      if (session == null || session.pausedAt == null) return;
      final resumed = session.resume(_clock());
      await _repository.saveActiveFocus(resumed);
      _activeSession = resumed;
      notifyListeners();
      if (resumed.mode != FocusMode.countUp) {
        await _scheduleFocusSafely(resumed);
      }
    });
  }

  Future<void> reset() => cancel();

  Future<void> cancel() {
    return _enqueue(() async {
      final session = _activeSession;
      if (session == null) return;
      await _repository.saveActiveFocus(null);
      _activeSession = null;
      notifyListeners();
      await _cancelFocusSafely(session.id);
    });
  }

  Future<FocusSession?> complete({bool completeTask = false}) {
    final active = _completionFuture;
    if (active != null) return active;
    final future = _enqueue(() => _complete(completeTask: completeTask));
    _completionFuture = future;
    future.then(
      (_) => _clearCompletion(future),
      onError: (_, _) => _clearCompletion(future),
    );
    return future;
  }

  void _clearCompletion(Future<FocusSession?> future) {
    if (!identical(_completionFuture, future)) return;
    _completionFuture = null;
    notifyListeners();
  }

  Future<FocusSession?> _complete({required bool completeTask}) async {
    final session = _activeSession ?? await _repository.loadActiveFocus();
    if (session == null) return null;

    final elapsedSeconds = session.elapsedAt(_clock()).inSeconds;
    final durationSeconds = session.mode == FocusMode.countUp
        ? elapsedSeconds
        : elapsedSeconds.clamp(0, session.durationSeconds!);
    final completedAt = _clock().toUtc();
    final history = FocusSession(
      id: session.id,
      taskId: session.taskId,
      taskTitle: session.taskTitle.isEmpty
          ? 'Open focus session'
          : session.taskTitle,
      minutes: durationSeconds ~/ 60,
      mode: session.mode,
      durationSeconds: durationSeconds,
      completedAt: completedAt,
    );
    final completedTaskId = completeTask ? session.taskId : null;
    await _repository.completeFocus(history, completedTaskId: completedTaskId);
    _lastCompletedSessionId = session.id;
    _activeSession = null;
    _history = List.unmodifiable([history, ..._history]);
    notifyListeners();
    await _onCompleted?.call(history, completedTaskId);
    await _cancelFocusSafely(session.id);
    return history;
  }

  Future<void> _scheduleFocusSafely(
    ActiveFocusSession session, {
    bool requestPermission = true,
  }) async {
    try {
      await _notifications.scheduleFocus(
        session,
        requestPermission: requestPermission,
      );
      _clearWarningFor('scheduleFocus', session.id);
    } catch (error) {
      _recordWarning(
        FocusSessionWarning(
          operation: 'scheduleFocus',
          sessionId: session.id,
          cause: error,
        ),
      );
    }
  }

  Future<void> _cancelFocusSafely(String sessionId) async {
    try {
      await _notifications.cancelFocus(sessionId);
      _clearWarningFor('cancelFocus', sessionId);
    } catch (error) {
      _recordWarning(
        FocusSessionWarning(
          operation: 'cancelFocus',
          sessionId: sessionId,
          cause: error,
        ),
      );
    }
  }

  Future<void> _retryWarningCleanup() async {
    final warning = _lastWarning;
    if (warning?.operation == 'cancelFocus') {
      await _cancelFocusSafely(warning!.sessionId);
    }
  }

  void _clearWarningFor(String operation, String sessionId) {
    final warning = _lastWarning;
    if (warning?.operation == operation && warning?.sessionId == sessionId) {
      _lastWarning = null;
      notifyListeners();
    }
  }

  void clearWarning() {
    if (_lastWarning == null) return;
    _lastWarning = null;
    notifyListeners();
  }

  void _recordWarning(FocusSessionWarning warning) {
    _lastWarning = warning;
    _onWarning?.call(warning);
    notifyListeners();
  }

  Future<void> refresh() async {
    final session = _activeSession;
    if (session != null && _isExpired(session)) {
      await complete();
      return;
    }
    notifyListeners();
  }

  Future<void> handleLifecycleResume() async {
    if (_activeSession == null) await load();
    await refresh();
  }

  bool _isExpired(ActiveFocusSession session) =>
      session.mode != FocusMode.countUp &&
      session.pausedAt == null &&
      session.remainingAt(_clock()) == Duration.zero;

  Future<T> _enqueue<T>(Future<T> Function() mutation) {
    final completer = Completer<T>();
    _pendingMutations += 1;
    notifyListeners();
    _mutationQueue = _mutationQueue.then((_) async {
      try {
        completer.complete(await mutation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        _pendingMutations -= 1;
        notifyListeners();
      }
    });
    return completer.future;
  }
}
