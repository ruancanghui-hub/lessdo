import '../models/active_focus_session.dart';
import '../models/focus_session.dart';
import '../models/task_item.dart';
import '../models/task_list.dart';

enum ListDeletionStrategy { moveToInbox, deleteTasks }

class RepositorySnapshot {
  RepositorySnapshot({
    required Iterable<TaskList> lists,
    required Iterable<TaskItem> tasks,
  }) : lists = List.unmodifiable(lists),
       tasks = List.unmodifiable(tasks);

  final List<TaskList> lists;
  final List<TaskItem> tasks;
}

abstract interface class TaskRepository {
  Future<RepositorySnapshot> loadSnapshot();

  Future<List<TaskList>> loadLists();

  Future<List<TaskItem>> loadTasks();

  Future<List<FocusSession>> loadFocusHistory();

  Future<ActiveFocusSession?> loadActiveFocus();

  Future<void> saveTask(TaskItem task);

  Future<void> deleteTask(String taskId);

  Future<void> saveList(TaskList list);

  Future<RepositorySnapshot> deleteList(
    String listId,
    ListDeletionStrategy strategy,
  );

  Future<void> saveActiveFocus(ActiveFocusSession? session);

  Future<void> completeFocus(FocusSession history, {String? completedTaskId});
}
