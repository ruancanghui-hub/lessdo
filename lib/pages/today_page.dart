import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_item.dart';
import '../controllers/app_controller.dart';
import '../widgets/lessdo_top_bar.dart';
import '../widgets/quick_add.dart';
import '../widgets/section_label.dart';
import '../widgets/task_row.dart';
import 'task_editor_sheet.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({
    super.key,
    required this.store,
    required this.onOpenLists,
    required this.onStartFocus,
  });

  final AppController store;
  final VoidCallback onOpenLists;
  final ValueChanged<String?> onStartFocus;

  @override
  Widget build(BuildContext context) {
    final today = store.todayTasks;
    final overdue = store.overdueTasks;
    final nextReminder = today
        .where((task) => task.reminderAt != null)
        .cast<TaskItem?>()
        .firstOrNull;
    final openCount = store.tasks.where((task) => !task.completed).length;

    return Column(
      children: [
        LessDoTopBar(title: 'Today', onLeading: onOpenLists),
        SizedBox(
          height: 67,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 9),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEE, MMM d').format(DateTime.now()),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$openCount things left',
                      style: const TextStyle(
                        color: Color(0xFF9699A1),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(CupertinoIcons.calendar, size: 23),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
            children: [
              if (overdue.isNotEmpty) ...[
                const SectionLabel(
                  icon: CupertinoIcons.clock,
                  label: 'Overdue',
                  color: Color(0xFFEE5358),
                ),
                for (final task in overdue)
                  TaskRow(
                    task: task,
                    list: store.listById(task.listId),
                    onToggle: () => store.toggleTask(task.id),
                    onOpen: () =>
                        showTaskEditor(context, store: store, taskId: task.id),
                  ),
              ],
              if (nextReminder != null)
                _ReminderBanner(
                  task: nextReminder,
                  onTap: () => showTaskEditor(
                    context,
                    store: store,
                    taskId: nextReminder.id,
                  ),
                ),
              SectionLabel(
                icon: CupertinoIcons.sun_max,
                label: 'Today',
                color: const Color(0xFFDF9C00),
                count: today.length,
                bottomBorder: true,
              ),
              for (final task in today)
                TaskRow(
                  task: task,
                  list: store.listById(task.listId),
                  onToggle: () => store.toggleTask(task.id),
                  onOpen: () =>
                      showTaskEditor(context, store: store, taskId: task.id),
                ),
              _FocusEntry(
                onTap: () {
                  final preferred = today
                      .where((task) => task.title == 'Finish PRD draft')
                      .firstOrNull;
                  onStartFocus(preferred?.id ?? today.firstOrNull?.id);
                },
              ),
              if (store.tasks.any((task) => task.completed))
                _CompletedTasks(store: store),
            ],
          ),
        ),
        QuickAdd(onSubmit: (text) => store.addTask(text: text)),
      ],
    );
  }
}

class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({required this.task, required this.onTap});

  final TaskItem task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFF),
            border: Border.all(color: const Color(0xFFC7D8F9)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.calendar,
                size: 27,
                color: Color(0xFF2D76EF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NEXT REMINDER',
                      style: TextStyle(
                        color: Color(0xFF696B73),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${task.title} at ${DateFormat.jm().format(task.reminderAtLocal!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Today',
                style: TextStyle(color: Color(0xFF2D76EF), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusEntry extends StatelessWidget {
  const _FocusEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF56BA73),
              ),
              child: const Icon(
                CupertinoIcons.timer,
                color: Colors.white,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Focus time',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Start a 25-minute session',
                    style: TextStyle(color: Color(0xFF7D7F87), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: Color(0xFFBBBCC2),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedTasks extends StatelessWidget {
  const _CompletedTasks({required this.store});

  final AppController store;

  @override
  Widget build(BuildContext context) {
    final completed = store.tasks
        .where((task) => task.completed)
        .take(3)
        .toList();
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completed · ${store.tasks.where((task) => task.completed).length}',
            style: const TextStyle(
              color: Color(0xFF777981),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final task in completed)
            TextButton.icon(
              onPressed: () => store.toggleTask(task.id),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9A9DA5),
                padding: EdgeInsets.zero,
                minimumSize: const Size.fromHeight(40),
                alignment: Alignment.centerLeft,
              ),
              icon: const Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: Color(0xFF64AC7E),
                size: 22,
              ),
              label: Text(
                task.title,
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              ),
            ),
        ],
      ),
    );
  }
}

extension _IterableTaskExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
