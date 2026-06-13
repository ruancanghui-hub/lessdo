import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/active_focus_session.dart';
import '../store/app_store.dart';
import '../widgets/lessdo_top_bar.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key, required this.store, this.initialTaskId});

  final AppStore store;
  final String? initialTaskId;

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  FocusMode _mode = FocusMode.pomodoro;
  String? _taskId;
  var _seconds = 25 * 60;
  var _running = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final available = widget.store.tasks
        .where((task) => !task.completed)
        .toList();
    _taskId = widget.initialTaskId ?? available.firstOrNull?.id;
  }

  @override
  void didUpdateWidget(covariant FocusPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTaskId != null &&
        widget.initialTaskId != oldWidget.initialTaskId) {
      _taskId = widget.initialTaskId;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _baseSeconds => switch (_mode) {
    FocusMode.pomodoro => 25 * 60,
    FocusMode.countdown => 10 * 60,
    FocusMode.countUp => 0,
  };

  String get _modeLabel => switch (_mode) {
    FocusMode.pomodoro => '25 min focus',
    FocusMode.countdown => '10 min timer',
    FocusMode.countUp => 'Open session',
  };

  @override
  Widget build(BuildContext context) {
    final tasks = widget.store.tasks.where((task) => !task.completed).toList();
    if (_taskId != null && tasks.every((task) => task.id != _taskId)) {
      _taskId = tasks.firstOrNull?.id;
    }
    final selected = tasks.where((task) => task.id == _taskId).firstOrNull;

    return Column(
      children: [
        const LessDoTopBar(title: 'Focus'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
            children: [
              _ModeSelector(mode: _mode, onChanged: _changeMode),
              const SizedBox(height: 25),
              const Text(
                'Working on',
                style: TextStyle(color: Color(0xFF83868E), fontSize: 12),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _taskId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.7),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Open focus session'),
                  ),
                  for (final task in tasks)
                    DropdownMenuItem<String?>(
                      value: task.id,
                      child: Text(task.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() => _taskId = value),
              ),
              const SizedBox(height: 28),
              Center(
                child: AnimatedScale(
                  scale: _running ? 1.02 : 1,
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
                        Positioned(
                          top: -1,
                          child: Container(
                            width: 92,
                            height: 7,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3C9F5A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(_seconds),
                              style: const TextStyle(
                                fontSize: 47,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              _modeLabel,
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
                    onPressed: _toggleTimer,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(190, 48),
                      backgroundColor: const Color(0xFF33894B),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      _running ? 'Pause' : 'Start',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(78, 48),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              if (selected != null)
                TextButton.icon(
                  onPressed: () => widget.store.toggleTask(selected.id),
                  icon: const Icon(CupertinoIcons.check_mark),
                  label: Text('Complete “${selected.title}”'),
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
                        const Text(
                          'Recent sessions',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${widget.store.sessions.fold<int>(0, (sum, item) => sum + item.minutes)} min',
                          style: const TextStyle(
                            color: Color(0xFF8B8E96),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (widget.store.sessions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Your completed focus sessions will appear here.',
                            style: TextStyle(
                              color: Color(0xFF93969E),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      for (final session in widget.store.sessions.take(4))
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
                                '${session.minutes} min',
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
    _timer?.cancel();
    setState(() {
      _mode = value;
      _seconds = _baseSeconds;
      _running = false;
    });
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }

    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_mode == FocusMode.countUp) {
          _seconds += 1;
        } else if (_seconds > 0) {
          _seconds -= 1;
        }
      });
      if (_mode != FocusMode.countUp && _seconds == 0) {
        _finishSession();
      }
    });
  }

  Future<void> _finishSession() async {
    _timer?.cancel();
    setState(() => _running = false);
    final selected = widget.store.tasks
        .where((task) => task.id == _taskId)
        .firstOrNull;
    await widget.store.addSession(
      title: selected?.title ?? 'Open focus session',
      mode: _mode,
      durationSeconds: _mode == FocusMode.countUp ? _seconds : _baseSeconds,
    );
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _seconds = _baseSeconds;
    });
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
  final ValueChanged<FocusMode> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = {
      FocusMode.pomodoro: 'Pomodoro',
      FocusMode.countdown: 'Countdown',
      FocusMode.countUp: 'Count up',
    };
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFECEEF1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (final item in labels.entries)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(item.key),
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: mode == item.key ? Colors.white : Colors.transparent,
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
                          ? const Color(0xFF17181B)
                          : const Color(0xFF6F737B),
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
