import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../data/task_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/task_list.dart';
import '../widgets/lessdo_top_bar.dart';
import '../widgets/quick_add.dart';
import '../widgets/task_row.dart';
import 'new_list_sheet.dart';
import 'task_editor_sheet.dart';

class ListDetailPage extends StatelessWidget {
  const ListDetailPage({super.key, required this.store, required this.listId});

  final AppController store;
  final String listId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final list = store.listById(listId);
        final tasks = store.tasksForList(listId);
        final open = tasks.where((task) => !task.completed).toList();
        final completed = tasks.where((task) => task.completed).toList();

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                LessDoTopBar(
                  title: list.name,
                  leadingIcon: CupertinoIcons.chevron_left,
                  onLeading: () => Navigator.of(context).pop(),
                  moreKey: const Key('list-menu'),
                  onMore: list.id == 'inbox'
                      ? null
                      : () => _showListActions(context, list),
                ),
                _ListHeader(
                  list: list,
                  remaining: open.length,
                  onShare: () => store.shareList(list),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                    children: [
                      if (open.isEmpty)
                        const _EmptyList()
                      else
                        for (final task in open)
                          TaskRow(
                            task: task,
                            list: list,
                            grocery: list.kind == ListKind.grocery,
                            onToggle: () => store.toggleTask(task.id),
                            onOpen: () => showTaskEditor(
                              context,
                              store: store,
                              taskId: task.id,
                            ),
                          ),
                      if (completed.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Completed · ${completed.length}',
                          style: const TextStyle(
                            color: Color(0xFF777981),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        for (final task in completed)
                          TaskRow(
                            task: task,
                            list: list,
                            grocery: list.kind == ListKind.grocery,
                            onToggle: () => store.toggleTask(task.id),
                            onOpen: () => showTaskEditor(
                              context,
                              store: store,
                              taskId: task.id,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                QuickAdd(
                  grocery: list.kind == ListKind.grocery,
                  onSubmit: (text) async {
                    await store.addTask(text: text, listId: list.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showListActions(BuildContext context, TaskList list) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<_ListAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.pencil),
              title: Text(l10n.editList),
              onTap: () => Navigator.of(sheetContext).pop(_ListAction.edit),
            ),
            ListTile(
              leading: Icon(
                CupertinoIcons.trash,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                l10n.deleteList,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => Navigator.of(sheetContext).pop(_ListAction.delete),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == _ListAction.edit) {
      await showNewListSheet(context, store: store, existing: list);
      return;
    }
    await _confirmDelete(context, list);
  }

  Future<void> _confirmDelete(BuildContext context, TaskList list) async {
    final l10n = AppLocalizations.of(context);
    final strategy = await showDialog<ListDeletionStrategy>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteList),
        content: Text(l10n.deleteListQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(ListDeletionStrategy.moveToInbox),
            child: Text(l10n.moveTasksToInbox),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(ListDeletionStrategy.deleteTasks),
            child: Text(
              l10n.deleteTasks,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (strategy == null || !context.mounted) return;
    await store.deleteList(list.id, strategy);
    if (context.mounted) Navigator.of(context).pop();
  }
}

enum _ListAction { edit, delete }

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.list,
    required this.remaining,
    required this.onShare,
  });

  final TaskList list;
  final int remaining;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: list.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              list.kind == ListKind.grocery
                  ? CupertinoIcons.cart
                  : CupertinoIcons.list_bullet,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$remaining remaining',
                  style: const TextStyle(
                    color: Color(0xFF8D9098),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onShare,
            icon: const Icon(CupertinoIcons.share, size: 23),
          ),
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 250,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.check_mark_circled,
            color: Color(0xFF57AD74),
            size: 42,
          ),
          SizedBox(height: 8),
          Text(
            'Everything is done',
            style: TextStyle(
              color: Color(0xFF4E5057),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Add another item whenever you need it.',
            style: TextStyle(color: Color(0xFF94979F), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
