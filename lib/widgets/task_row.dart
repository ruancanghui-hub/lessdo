import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_item.dart';
import '../models/task_list.dart';

class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    required this.list,
    required this.onToggle,
    required this.onOpen,
    this.grocery = false,
  });

  final TaskItem task;
  final TaskList list;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final bool grocery;

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(context).dividerColor;
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label:
                    '${task.completed ? "Restore" : "Complete"} ${task.title}',
                child: GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.completed ? list.color : Colors.transparent,
                      border: Border.all(
                        width: 1.6,
                        color: task.overdue
                            ? const Color(0xFFEE5358)
                            : task.completed
                            ? list.color
                            : const Color(0xFFB8BBC3),
                      ),
                    ),
                    child: task.completed
                        ? const Icon(
                            CupertinoIcons.check_mark,
                            size: 15,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          if (!task.overdue)
            Container(
              width: 3,
              height: 44,
              decoration: BoxDecoration(
                color: list.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.completed
                            ? const Color(0xFFA1A4AB)
                            : const Color(0xFF17181B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _metaText(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF92959D),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: Color(0xFFB9BBC2),
          ),
        ],
      ),
    );
  }

  String _metaText() {
    if (grocery) return task.category.isEmpty ? 'Other' : task.category;
    final reminder = task.reminderAt;
    if (reminder != null) {
      return '${DateFormat.jm().format(reminder)}  •  ${list.name}';
    }
    return list.name;
  }
}
