import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/task_list.dart';
import '../controllers/app_controller.dart';
import '../widgets/lessdo_top_bar.dart';
import 'list_detail_page.dart';
import 'new_list_sheet.dart';

class ListsPage extends StatelessWidget {
  const ListsPage({super.key, required this.store});

  final AppController store;

  @override
  Widget build(BuildContext context) {
    final openCount = store.tasks.where((task) => !task.completed).length;
    final completedCount = store.tasks.where((task) => task.completed).length;

    return Column(
      children: [
        LessDoTopBar(
          title: 'Lists',
          onAdd: () => showNewListSheet(context, store: store),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(label: 'All tasks', value: openCount),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Completed',
                      value: completedCount,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Column(
                  children: [
                    for (final list in store.lists)
                      _ListRow(
                        list: list,
                        count: store
                            .tasksForList(list.id)
                            .where((task) => !task.completed)
                            .length,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ListDetailPage(store: store, listId: list.id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFF),
                  border: Border.all(color: const Color(0xFFD9E5F7)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      CupertinoIcons.share,
                      size: 25,
                      color: Color(0xFF2E7BF6),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share a list',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Plan groceries or trips together.',
                            style: TextStyle(
                              color: Color(0xFF7E828A),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: Color(0xFFB5B8BF),
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
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        border: Border.all(color: const Color(0xFFE1E3E7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF858891), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.list,
    required this.count,
    required this.onTap,
  });

  final TaskList list;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: list.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                list.kind == ListKind.grocery
                    ? CupertinoIcons.cart
                    : CupertinoIcons.list_bullet,
                color: list.color,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    list.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count ${count == 1 ? "task" : "tasks"}',
                    style: const TextStyle(
                      color: Color(0xFF90939B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: list.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: Color(0xFFB5B8BF),
            ),
          ],
        ),
      ),
    );
  }
}
