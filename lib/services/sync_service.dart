import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dev_flow/data/local/local_db.dart';
import 'package:dev_flow/data/models/pending_change.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/data/repositories/project_repository.dart';
import 'package:dev_flow/data/repositories/task_repository.dart';
import 'dart:async';

/// Background service that pushes pending local changes to Supabase
/// whenever connectivity is available.
class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  final LocalDatabase _local = LocalDatabase.instance;
  final ProjectRepository _remoteProject = ProjectRepository();
  final TaskRepository _remoteTask = TaskRepository();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;

  void start() {
    _connectivitySub ??= Connectivity().onConnectivityChanged.listen((results) {
      // connectivity_plus v6 emits a list of ConnectivityResult values.
      final online = results.any(
        (r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet,
      );

      if (online) {
        syncPendingChanges();
      }
    });
  }

  Future<void> syncPendingChanges() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final changes = await _local.getPendingChanges();
      for (final change in changes) {
        try {
          await _applyChange(change);
          await _local.deletePendingChange(change.id);
        } catch (e) {
          // Stop on first failure to avoid tight loops
          break;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _applyChange(PendingChange change) async {
    switch (change.entityType) {
      case EntityType.project:
        await _applyProjectChange(change);
        break;
      case EntityType.task:
        await _applyTaskChange(change);
        break;
    }
  }

  Future<void> _applyProjectChange(PendingChange change) async {
    final project = Project.fromJson(change.payloadJson);

    switch (change.operation) {
      case OperationType.create:
        final created = await _remoteProject.createProject(project);
        await _local.upsertProject(created, SyncStatus.synced);
        break;
      case OperationType.update:
        await _remoteProject.updateProject(project);
        await _local.upsertProject(project, SyncStatus.synced);
        break;
      case OperationType.delete:
        await _remoteProject.deleteProject(project.id);
        await _local.deleteProject(project.id);
        break;
    }
  }

  Future<void> _applyTaskChange(PendingChange change) async {
    final task = Task.fromJson(change.payloadJson);

    switch (change.operation) {
      case OperationType.create:
        final created = await _remoteTask.createTask(task);
        await _local.upsertTask(created, SyncStatus.synced);
        break;
      case OperationType.update:
        await _remoteTask.updateTask(task);
        await _local.upsertTask(task, SyncStatus.synced);
        break;
      case OperationType.delete:
        await _remoteTask.deleteTask(task.id);
        await _local.deleteTask(task.id);
        break;
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }
}
