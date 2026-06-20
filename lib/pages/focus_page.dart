import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/active_focus_session.dart';
import '../controllers/app_controller.dart';
import '../l10n/app_localizations.dart';
import '../widgets/lessdo_top_bar.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key, required this.store, this.initialTaskId});

  final AppController store;
  final String? initialTaskId;

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with WidgetsBindingObserver {
  FocusMode _mode = FocusMode.pomodoro;
  String? _taskId;
  Timer? _displayTimer;
  var _handlingAction = false;

  @override
  void initState() {
    super.initState();
    final available = widget.store.tasks
        .where((task) => !task.completed)
        .toList();
    _taskId = widget.initialTaskId ?? available.firstOrNull?.id;
    widget.store.focusController.addListener(_handleFocusChanged);
    WidgetsBinding.instance.addObserver(this);
    _displayTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(widget.store.focusController.refresh()),
    );
  }

  @override
  void didUpdateWidget(covariant FocusPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      oldWidget.store.focusController.removeListener(_handleFocusChanged);
      widget.store.focusController.addListener(_handleFocusChanged);
    }
    if (widget.initialTaskId != null &&
        widget.initialTaskId != oldWidget.initialTaskId) {
      _taskId = widget.initialTaskId;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.store.focusController.handleLifecycleResume());
    }
  }

  @override
  void dispose() {
    widget.store.focusController.removeListener(_handleFocusChanged);
    WidgetsBinding.instance.removeObserver(this);
    _displayTimer?.cancel();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  int get _baseSeconds => switch (_currentMode) {
    FocusMode.pomodoro => 25 * 60,
    FocusMode.countdown => 10 * 60,
    FocusMode.countUp => 0,
  };

  FocusMode get _currentMode =>
      widget.store.focusController.activeSession?.mode ?? _mode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final focus = widget.store.focusController;
    final actionsDisabled =
        _handlingAction || focus.isMutating || focus.isCompleting;
    final mode = _currentMode;
    final seconds = mode == FocusMode.countUp
        ? focus.elapsed.inSeconds
        : focus.activeSession == null
        ? _baseSeconds
        : focus.remaining.inSeconds;
    final tasks = widget.store.tasks.where((task) => !task.completed).toList();
    if (_taskId != null && tasks.every((task) => task.id != _taskId)) {
      _taskId = tasks.firstOrNull?.id;
    }
    final selected = tasks.where((task) => task.id == _taskId).firstOrNull;

    return Column(
      children: [
        LessDoTopBar(title: l10n.focus),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
            children: [
              _ModeSelector(
                mode: mode,
                onChanged: focus.activeSession == null ? _changeMode : null,
              ),
              const SizedBox(height: 25),
              Text(
                l10n.workingOn,
                style: const TextStyle(
                  color: Color(0xFF83868E),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _taskId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.openFocusSession),
                  ),
                  for (final task in tasks)
                    DropdownMenuItem<String?>(
                      value: task.id,
                      child: Text(task.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: focus.activeSession == null
                    ? (value) => setState(() => _taskId = value)
                    : null,
              ),
              const SizedBox(height: 28),
              Center(
                child: AnimatedScale(
                  scale: focus.isRunning ? 1.02 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    width: 224,
                    height: 224,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFCFE8D6),
                        width: 7,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(seconds),
                              style: const TextStyle(
                                fontSize: 47,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              switch (mode) {
                                FocusMode.pomodoro => l10n.focusLabelPomodoro,
                                FocusMode.countdown =>
                                  l10n.focusLabelCountdown,
                                FocusMode.countUp => l10n.focusLabelCountUp,
                              },
                              style: const TextStyle(
                                color: Color(0xFF50875E),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: actionsDisabled
                        ? null
                        : () => _runFocusMutation(_toggleTimer),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(190, 48),
                      backgroundColor: const Color(0xFF33894B),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      focus.isRunning
                          ? l10n.pause
                          : focus.isPaused
                          ? l10n.resume
                          : l10n.start,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: focus.activeSession == null || actionsDisabled
                        ? null
                        : () => _runFocusMutation(focus.reset),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(78, 48),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(l10n.reset),
                  ),
                ],
              ),
              if (focus.activeSession != null)
                TextButton(
                  onPressed: actionsDisabled
                      ? null
                      : () => _runFocusMutation(() async {
                          await focus.complete();
                        }),
                  child: Text(l10n.endSession),
                ),
              if (selected != null)
                TextButton.icon(
                  onPressed:
                      focus.activeSession?.taskId == selected.id &&
                          !actionsDisabled
                      ? () => _runFocusMutation(() async {
                          await focus.complete(completeTask: true);
                        })
                      : null,
                  icon: const Icon(CupertinoIcons.check_mark),
                  label: Text(l10n.completeNamedTask(selected.title)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF388F5A),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.only(top: 18),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.recentSessions,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          l10n.minutesShort(
                            focus.history.fold<int>(
                              0,
                              (sum, item) => sum + item.minutes,
                            ),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF8B8E96),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (focus.history.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.emptyFocusHistory,
                            style: const TextStyle(
                              color: Color(0xFF93969E),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      for (final session in focus.history.take(4))
                        Container(
                          height: 49,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.timer,
                                color: Color(0xFF4CA269),
                                size: 21,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  session.taskTitle,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                l10n.minutesShort(session.minutes),
                                style: const TextStyle(
                                  color: Color(0xFF777A82),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _changeMode(FocusMode value) {
    setState(() => _mode = value);
  }

  Future<void> _runFocusMutation(Future<void> Function() action) async {
    final focus = widget.store.focusController;
    if (_handlingAction || focus.isMutating || focus.isCompleting) return;
    setState(() => _handlingAction = true);
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).focusUpdateFailed),
        ),
      );
    } finally {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _handlingAction = false);
        });
      }
    }
  }

  Future<void> _toggleTimer() async {
    final focus = widget.store.focusController;
    if (focus.isRunning) {
      await focus.pause();
      return;
    }
    if (focus.isPaused) {
      await focus.resume();
      return;
    }
    final selected = widget.store.tasks
        .where((task) => task.id == _taskId)
        .firstOrNull;
    final taskTitle =
        selected?.title ?? AppLocalizations.of(context).openFocusSession;
    switch (_mode) {
      case FocusMode.pomodoro:
        await focus.startPomodoro(
          const Duration(minutes: 25),
          taskId: selected?.id,
          taskTitle: taskTitle,
        );
      case FocusMode.countdown:
        await focus.startCountdown(
          const Duration(minutes: 10),
          taskId: selected?.id,
          taskTitle: taskTitle,
        );
      case FocusMode.countUp:
        await focus.startCountUp(taskId: selected?.id, taskTitle: taskTitle);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final FocusMode mode;
  final ValueChanged<FocusMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      FocusMode.pomodoro: l10n.focusModePomodoro,
      FocusMode.countdown: l10n.focusModeCountdown,
      FocusMode.countUp: l10n.focusModeCountUp,
    };
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (final item in labels.entries)
            Expanded(
              child: InkWell(
                onTap: onChanged == null ? null : () => onChanged!(item.key),
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: mode == item.key
                        ? Theme.of(context).colorScheme.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: mode == item.key
                        ? const [
                            BoxShadow(
                              color: Color(0x19000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    item.value,
                    style: TextStyle(
                      color: mode == item.key
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension _FirstTaskOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
