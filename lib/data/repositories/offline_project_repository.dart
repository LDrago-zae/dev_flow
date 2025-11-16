import 'package:dev_flow/data/local/local_db.dart';
import 'package:dev_flow/data/models/pending_change.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/repositories/project_repository.dart';
import 'package:uuid/uuid.dart';

/// Offline-first wrapper around [ProjectRepository].
///
/// - Always writes to local SQLite first.
/// - Records changes in a sync queue when offline.
/// - Best-effort remote write; on failure, local data still exists and will
///   be pushed later by [SyncService].
class OfflineProjectRepository {
  final ProjectRepository _remote;
  final LocalDatabase _local;

  OfflineProjectRepository({ProjectRepository? remote, LocalDatabase? local})
    : _remote = remote ?? ProjectRepository(),
      _local = local ?? LocalDatabase.instance;

  /// Get all projects for a user.
  ///
  /// Tries Supabase first; on failure falls back to local cache.
  Future<List<Project>> getProjects(String userId) async {
    final localProjects = await _local.getProjects(userId);

    try {
      final remoteProjects = await _remote.getProjects(userId);
      // Keep local cache in sync when online
      await _local.replaceAllProjectsForUser(userId, remoteProjects);
      return remoteProjects;
    } catch (_) {
      // Offline or server error – use cached projects
      return localProjects;
    }
  }

  Future<Project> getProjectById(String projectId) async {
    // Try remote first for the most up-to-date project
    try {
      final remote = await _remote.getProjectById(projectId);
      await _local.upsertProject(remote, SyncStatus.synced);
      return remote;
    } catch (_) {
      // Fallback to local cache if available
      final local = await _local.getProjectById(projectId);
      if (local == null) rethrow;
      return local;
    }
  }

  Future<Project> createProject(Project project) async {
    final uuid = const Uuid();
    final localProject = project.id.isEmpty
        ? project.copyWith(id: uuid.v4())
        : project;

    // 1) Save locally and add to pending changes
    await _local.upsertProject(localProject, SyncStatus.pendingCreate);
    await _local.insertPendingChange(
      PendingChange(
        id: uuid.v4(),
        entityType: EntityType.project,
        operation: OperationType.create,
        entityId: localProject.id,
        payloadJson: localProject.toJson(),
        createdAt: DateTime.now(),
      ),
    );

    // 2) Best-effort remote insert
    try {
      final created = await _remote.createProject(localProject);
      await _local.upsertProject(created, SyncStatus.synced);
      await _local.deletePendingChangesForEntity(
        EntityType.project,
        created.id,
      );
      return created;
    } catch (_) {
      // Remains pending; will be synced later
      return localProject;
    }
  }

  Future<void> updateProject(Project project) async {
    // 1) Update local and queue change
    await _local.upsertProject(project, SyncStatus.pendingUpdate);
    await _local.insertPendingChange(
      PendingChange(
        id: const Uuid().v4(),
        entityType: EntityType.project,
        operation: OperationType.update,
        entityId: project.id,
        payloadJson: project.toJson(),
        createdAt: DateTime.now(),
      ),
    );

    // 2) Best-effort remote update
    try {
      await _remote.updateProject(project);
      await _local.upsertProject(project, SyncStatus.synced);
      await _local.deletePendingChangesForEntity(
        EntityType.project,
        project.id,
      );
    } catch (_) {
      // Keep local pending; sync later
    }
  }

  Future<void> deleteProject(String projectId) async {
    // 1) Delete locally and queue change
    await _local.deleteProject(projectId);
    await _local.insertPendingChange(
      PendingChange(
        id: const Uuid().v4(),
        entityType: EntityType.project,
        operation: OperationType.delete,
        entityId: projectId,
        payloadJson: {'id': projectId},
        createdAt: DateTime.now(),
      ),
    );

    // 2) Best-effort remote delete
    try {
      await _remote.deleteProject(projectId);
      await _local.deletePendingChangesForEntity(EntityType.project, projectId);
    } catch (_) {
      // Keep pending delete; sync later
    }
  }
}
