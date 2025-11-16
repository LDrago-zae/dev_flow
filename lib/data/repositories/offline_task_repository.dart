import 'package:dev_flow/data/local/local_db.dart';
import 'package:dev_flow/data/models/pending_change.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/data/repositories/task_repository.dart';
import 'package:uuid/uuid.dart';

/// Offline-first wrapper around [TaskRepository].
///
/// Handles both quick todos (projectId == null) and project tasks.
class OfflineTaskRepository {
  final TaskRepository _remote;
  final LocalDatabase _local;

  OfflineTaskRepository({TaskRepository? remote, LocalDatabase? local})
    : _remote = remote ?? TaskRepository(),
      _local = local ?? LocalDatabase.instance;

  Future<List<Task>> getTasks(String userId, {String? projectId}) async {
    final localTasks = await _local.getTasks(userId, projectId: projectId);

    try {
      final remoteTasks = await _remote.getTasks(userId, projectId: projectId);
      // Cache remote tasks locally as synced
      for (final task in remoteTasks) {
        await _local.upsertTask(task, SyncStatus.synced);
      }
      return remoteTasks;
    } catch (_) {
      // Offline: use local cache
      return localTasks;
    }
  }

  Future<Task> createTask(Task task) async {
    final uuid = const Uuid();
    final localTask = task.id.isEmpty ? task.copyWith(id: uuid.v4()) : task;

    await _local.upsertTask(localTask, SyncStatus.pendingCreate);
    await _local.insertPendingChange(
      PendingChange(
        id: uuid.v4(),
        entityType: EntityType.task,
        operation: OperationType.create,
        entityId: localTask.id,
        payloadJson: localTask.toJson(),
        createdAt: DateTime.now(),
      ),
    );

    try {
      final created = await _remote.createTask(localTask);
      await _local.upsertTask(created, SyncStatus.synced);
      await _local.deletePendingChangesForEntity(EntityType.task, created.id);
      return created;
    } catch (_) {
      return localTask;
    }
  }

  Future<void> updateTask(Task task) async {
    await _local.upsertTask(task, SyncStatus.pendingUpdate);
    await _local.insertPendingChange(
      PendingChange(
        id: const Uuid().v4(),
        entityType: EntityType.task,
        operation: OperationType.update,
        entityId: task.id,
        payloadJson: task.toJson(),
        createdAt: DateTime.now(),
      ),
    );

    try {
      await _remote.updateTask(task);
      await _local.upsertTask(task, SyncStatus.synced);
      await _local.deletePendingChangesForEntity(EntityType.task, task.id);
    } catch (_) {
      // keep pending
    }
  }

  Future<void> deleteTask(String taskId) async {
    await _local.deleteTask(taskId);
    await _local.insertPendingChange(
      PendingChange(
        id: const Uuid().v4(),
        entityType: EntityType.task,
        operation: OperationType.delete,
        entityId: taskId,
        payloadJson: {'id': taskId},
        createdAt: DateTime.now(),
      ),
    );

    try {
      await _remote.deleteTask(taskId);
      await _local.deletePendingChangesForEntity(EntityType.task, taskId);
    } catch (_) {
      // keep pending delete
    }
  }
}
