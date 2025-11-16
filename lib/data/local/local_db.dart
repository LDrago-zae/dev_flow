import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/data/models/pending_change.dart';

/// Local SQLite database used for offline caching and sync queue.
class LocalDatabase {
  LocalDatabase._internal();
  static final LocalDatabase instance = LocalDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    final docsDir = await getApplicationDocumentsDirectory();
    final path = p.join(docsDir.path, 'dev_flow_local.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE local_projects ('
          'id TEXT PRIMARY KEY,'
          'data TEXT NOT NULL,'
          'sync_status TEXT NOT NULL,'
          'updated_at TEXT'
          ')',
        );

        await db.execute(
          'CREATE TABLE local_tasks ('
          'id TEXT PRIMARY KEY,'
          'data TEXT NOT NULL,'
          'sync_status TEXT NOT NULL,'
          'updated_at TEXT'
          ')',
        );

        await db.execute(
          'CREATE TABLE pending_changes ('
          'id TEXT PRIMARY KEY,'
          'entity_type TEXT NOT NULL,'
          'entity_id TEXT NOT NULL,'
          'operation TEXT NOT NULL,'
          'payload_json TEXT NOT NULL,'
          'created_at TEXT NOT NULL'
          ')',
        );
      },
    );

    return _db!;
  }

  // ---------- Projects ----------

  Future<void> upsertProject(Project project, SyncStatus status) async {
    final db = await database;
    await db.insert('local_projects', {
      'id': project.id,
      'data': jsonEncode(project.toJson()),
      'sync_status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteProject(String projectId) async {
    final db = await database;
    await db.delete('local_projects', where: 'id = ?', whereArgs: [projectId]);
  }

  Future<List<Project>> getProjects(String userId) async {
    final db = await database;
    final rows = await db.query('local_projects');

    return rows
        .map((row) {
          final data =
              jsonDecode(row['data'] as String) as Map<String, dynamic>;
          final ownerId = data['owner_id'] ?? data['user_id'];
          if (ownerId != userId) return null;
          return Project.fromJson(data);
        })
        .whereType<Project>()
        .toList();
  }

  Future<Project?> getProjectById(String projectId) async {
    final db = await database;
    final rows = await db.query(
      'local_projects',
      where: 'id = ?',
      whereArgs: [projectId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final data =
        jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
    return Project.fromJson(data);
  }

  Future<void> replaceAllProjectsForUser(
    String userId,
    List<Project> projects,
  ) async {
    final db = await database;

    await db.transaction((txn) async {
      final rows = await txn.query('local_projects');
      for (final row in rows) {
        final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
        final ownerId = data['owner_id'] ?? data['user_id'];
        if (ownerId == userId) {
          await txn.delete(
            'local_projects',
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
      }

      for (final project in projects) {
        await txn.insert('local_projects', {
          'id': project.id,
          'data': jsonEncode(project.toJson()),
          'sync_status': SyncStatus.synced.name,
          'updated_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // ---------- Tasks (Quick todos + project tasks) ----------

  Future<void> upsertTask(Task task, SyncStatus status) async {
    final db = await database;
    await db.insert('local_tasks', {
      'id': task.id,
      'data': jsonEncode(task.toJson()),
      'sync_status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTask(String taskId) async {
    final db = await database;
    await db.delete('local_tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  Future<List<Task>> getTasks(String userId, {String? projectId}) async {
    final db = await database;
    final rows = await db.query('local_tasks');

    final tasks = rows
        .map((row) {
          final data =
              jsonDecode(row['data'] as String) as Map<String, dynamic>;
          return Task.fromJson(data);
        })
        .where((task) {
          final ownerMatches = task.userId == userId;
          final projectMatches = projectId == null
              ? task.projectId == null
              : task.projectId == projectId;
          return ownerMatches && projectMatches;
        })
        .toList();

    tasks.sort((a, b) => a.date.compareTo(b.date));
    return tasks;
  }

  // ---------- Pending changes (sync queue) ----------

  Future<void> insertPendingChange(PendingChange change) async {
    final db = await database;
    await db.insert(
      'pending_changes',
      change.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PendingChange>> getPendingChanges() async {
    final db = await database;
    final rows = await db.query('pending_changes', orderBy: 'created_at ASC');
    return rows.map((row) => PendingChange.fromRow(row)).toList();
  }

  Future<void> deletePendingChange(String id) async {
    final db = await database;
    await db.delete('pending_changes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePendingChangesForEntity(
    EntityType entityType,
    String entityId,
  ) async {
    final db = await database;
    await db.delete(
      'pending_changes',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType.name, entityId],
    );
  }
}

/// Sync status for local rows
enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete }
