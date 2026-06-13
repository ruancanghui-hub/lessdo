import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/task_item.dart';
import '../controllers/app_controller.dart';

Future<void> showTaskEditor(
  BuildContext context, {
  required AppController store,
  required String taskId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TaskEditorSheet(store: store, taskId: taskId),
  );
}

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({required this.store, required this.taskId});

  final AppController store;
  final String taskId;

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  late TaskItem _draft;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  final _subtaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = widget.store.taskById(widget.taskId);
    _titleController = TextEditingController(text: _draft.title);
    _notesController = TextEditingController(text: _draft.notes);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.store.saveTask(
      _draft.copyWith(
        title: _titleController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 520,
        maxHeight: MediaQuery.sizeOf(context).height * 0.93,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD8D9DD),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const Expanded(
                  child: Text(
                    'Task details',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                22,
                0,
                22,
                30 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                _SelectRow<String>(
                  icon: CupertinoIcons.list_bullet,
                  label: 'List',
                  value: _draft.listId,
                  items: {
                    for (final list in widget.store.lists) list.id: list.name,
                  },
                  onChanged: (value) =>
                      setState(() => _draft = _draft.copyWith(listId: value)),
                ),
                _ActionRow(
                  icon: CupertinoIcons.calendar,
                  label: 'Date',
                  value: _draft.dueAt == null
                      ? 'None'
                      : DateFormat.MMMd().format(_draft.dueAtLocal!),
                  onTap: _pickDueDate,
                ),
                _ActionRow(
                  icon: CupertinoIcons.bell,
                  label: 'Reminder',
                  value: _draft.reminderAt == null
                      ? 'None'
                      : DateFormat.jm().format(_draft.reminderAtLocal!),
                  onTap: _pickReminder,
                ),
                _SelectRow<RepeatRule>(
                  icon: CupertinoIcons.repeat,
                  label: 'Repeat',
                  value: _draft.repeatRule,
                  items: const {
                    RepeatRule.none: 'None',
                    RepeatRule.daily: 'Daily',
                    RepeatRule.weekly: 'Weekly',
                    RepeatRule.monthly: 'Monthly',
                  },
                  onChanged: (value) => setState(
                    () => _draft = _draft.copyWith(repeatRule: value),
                  ),
                ),
                _SelectRow<TaskPriority>(
                  icon: CupertinoIcons.sparkles,
                  label: 'Priority',
                  value: _draft.priority,
                  items: const {
                    TaskPriority.low: 'Low',
                    TaskPriority.normal: 'Normal',
                    TaskPriority.high: 'High',
                  },
                  onChanged: (value) =>
                      setState(() => _draft = _draft.copyWith(priority: value)),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Notes',
                  style: TextStyle(color: Color(0xFF74767D), fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add a note…',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Subtasks',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                for (final subtask in _draft.subtasks)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _draft = _draft.copyWith(
                          subtasks: [
                            for (final item in _draft.subtasks)
                              if (item.id == subtask.id)
                                item.copyWith(completed: !item.completed)
                              else
                                item,
                          ],
                        );
                      });
                    },
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: subtask.completed
                                  ? const Color(0xFF50A86E)
                                  : null,
                              border: Border.all(
                                color: subtask.completed
                                    ? const Color(0xFF50A86E)
                                    : const Color(0xFFB8BBC2),
                                width: 1.5,
                              ),
                            ),
                            child: subtask.completed
                                ? const Icon(
                                    CupertinoIcons.check_mark,
                                    size: 13,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              subtask.title,
                              style: TextStyle(
                                decoration: subtask.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: subtask.completed
                                    ? const Color(0xFF9A9CA3)
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.add,
                      color: Color(0xFF2E7BF6),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        onSubmitted: (_) => _addSubtask(),
                        decoration: const InputDecoration(
                          hintText: 'Add subtask',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _addSubtask,
                      child: const Text(
                        'Add',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await widget.store.deleteTask(_draft.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFFFFF2F2),
                    foregroundColor: const Color(0xFFDC4E54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.trash, size: 20),
                  label: const Text('Delete task'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _draft = _draft.copyWith(
        subtasks: [
          ..._draft.subtasks,
          SubTask(id: const Uuid().v4(), title: title),
        ],
      );
      _subtaskController.clear();
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _draft.dueAtLocal ?? DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      final current = _draft.dueAtLocal;
      _draft = _draft.copyWith(
        dueAt: DateTime(
          picked.year,
          picked.month,
          picked.day,
          current?.hour ?? 18,
          current?.minute ?? 0,
        ),
      );
    });
  }

  Future<void> _pickReminder() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _draft.reminderAtLocal ?? _draft.dueAtLocal ?? DateTime.now(),
      ),
    );
    if (time == null) return;
    final date = _draft.dueAtLocal ?? DateTime.now();
    setState(() {
      _draft = _draft.copyWith(
        dueAt: date,
        reminderAt: DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    });
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 25, child: Icon(icon, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            Text(
              value,
              style: const TextStyle(color: Color(0xFF7D8088), fontSize: 13),
            ),
            const SizedBox(width: 7),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: Color(0xFFB5B7BE),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectRow<T> extends StatelessWidget {
  const _SelectRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 25, child: Icon(icon, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox.shrink(),
            style: const TextStyle(color: Color(0xFF565960), fontSize: 13),
            items: [
              for (final item in items.entries)
                DropdownMenuItem<T>(value: item.key, child: Text(item.value)),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}
