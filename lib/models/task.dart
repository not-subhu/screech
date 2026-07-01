import 'package:isar/isar.dart';

part 'task.g.dart';

enum TaskPriority { low, medium, high, urgent }

@collection
class Task {
  Id id = Isar.autoIncrement;

  late String title;

  String? notes;

  @Index()
  DateTime? dueAt;

  @enumerated
  TaskPriority priority = TaskPriority.medium;

  bool isCompleted = false;

  DateTime? completedAt;

  /// Coins awarded on completion. Scales with priority by default,
  /// but can be overridden per-task.
  int coinValue = 10;

  DateTime createdAt = DateTime.now();

  /// If this task was parsed from AI (Phase 3), tag its origin for transparency.
  bool createdByAi = false;

  /// Tracks how many "pester" notifications have fired for this task,
  /// so we can escalate tone or cap frequency.
  int pesterCount = 0;

  /// Local notification id reserved for this task's due reminder,
  /// so we can cancel/reschedule it precisely.
  int? notificationId;
}
