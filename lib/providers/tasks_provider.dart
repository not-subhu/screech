import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/task.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import 'wallet_provider.dart';

class TasksNotifier extends StateNotifier<List<Task>> {
  TasksNotifier(this.ref) : super([]) {
    _load();
  }

  final Ref ref;
  final Isar _isar = DbService.instance;

  Future<void> _load() async {
    final tasks = await _isar.tasks.where().sortByCreatedAtDesc().findAll();
    state = tasks;
  }

  Future<void> addTask({
    required String title,
    String? notes,
    DateTime? dueAt,
    TaskPriority priority = TaskPriority.medium,
    bool createdByAi = false,
  }) async {
    final coinValue = _coinValueForPriority(priority);
    final task = Task()
      ..title = title
      ..notes = notes
      ..dueAt = dueAt
      ..priority = priority
      ..coinValue = coinValue
      ..createdByAi = createdByAi;

    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });

    if (dueAt != null && dueAt.isAfter(DateTime.now())) {
      final notifId = task.id.remitNotificationId();
      task.notificationId = notifId;
      await _isar.writeTxn(() async {
        await _isar.tasks.put(task);
      });
      await NotificationService.scheduleReminder(
        id: notifId,
        title: 'Quest due soon ⏳',
        body: title,
        scheduledTime: dueAt,
      );
    }

    await _load();
  }

  Future<void> completeTask(Task task) async {
    if (task.isCompleted) return;
    task.isCompleted = true;
    task.completedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });

    if (task.notificationId != null) {
      await NotificationService.cancel(task.notificationId!);
    }

    await ref.read(walletProvider.notifier).earn(
          task.coinValue,
          'Completed: ${task.title}',
        );

    await _load();
  }

  Future<void> uncompleteTask(Task task) async {
    if (!task.isCompleted) return;
    task.isCompleted = false;
    task.completedAt = null;
    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });
    await _load();
  }

  Future<void> deleteTask(Task task) async {
    if (task.notificationId != null) {
      await NotificationService.cancel(task.notificationId!);
    }
    await _isar.writeTxn(() async {
      await _isar.tasks.delete(task.id);
    });
    await _load();
  }

  static int _coinValueForPriority(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return 5;
      case TaskPriority.medium:
        return 10;
      case TaskPriority.high:
        return 18;
      case TaskPriority.urgent:
        return 28;
    }
  }
}

extension on Id {
  /// Derives a stable, small notification id from an Isar auto-increment id.
  /// Isar ids are 64-bit; local notification ids must fit in 32-bit, so we
  /// fold it down deterministically.
  int remitNotificationId() => (this % 2147483647).toInt();
}

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  return TasksNotifier(ref);
});

final pendingTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final pending = tasks.where((t) => !t.isCompleted).toList();
  pending.sort((a, b) {
    if (a.dueAt == null && b.dueAt == null) return 0;
    if (a.dueAt == null) return 1;
    if (b.dueAt == null) return -1;
    return a.dueAt!.compareTo(b.dueAt!);
  });
  return pending;
});

final completedTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider);
  return tasks.where((t) => t.isCompleted).toList();
});
