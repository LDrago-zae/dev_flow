import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';

class SharedItemsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get projects shared with the current user
  Future<List<Map<String, dynamic>>> getSharedProjects(String userId) async {
    print('🔍 REPO: Querying shared_projects for user: $userId');

    final response = await _supabase
        .from('shared_projects')
        .select('*, projects(*)')
        .eq('shared_with', userId)
        .order('created_at', ascending: false);

    print(
      '🔍 REPO: Raw response from shared_projects: ${response.length} items',
    );
    print('🔍 REPO: Response data: $response');

    // Fetch project tasks and emails for each shared project
    List<Map<String, dynamic>> sharedProjects = [];
    for (var item in response) {
      print('🔍 REPO: Processing item: $item');
      final project = item['projects'];
      print('🔍 REPO: Project data: $project');

      if (project != null) {
        final tasks = await _getProjectTasks(project['id']);
        final sharedByEmail =
            await getUserEmail(item['shared_by']) ?? 'Unknown';
        final sharedWithEmail =
            await getUserEmail(item['shared_with']) ?? 'Unknown';

        sharedProjects.add({
          'project': Project.fromJson({
            ...project,
            'tasks': tasks,
          }, tasks: tasks),
          'shared_by_email': sharedByEmail,
          'shared_with_email': sharedWithEmail,
          'permission': item['permission'],
          'created_at': item['created_at'],
        });

        print(
          '🔍 REPO: Added project to list. Total now: ${sharedProjects.length}',
        );
      } else {
        print('⚠️ REPO: Project is null for item');
      }
    }

    print('🔍 REPO: Returning ${sharedProjects.length} shared projects');
    return sharedProjects;
  }

  /// Get tasks shared with the current user (not part of a shared project)
  Future<List<Map<String, dynamic>>> getSharedTasks(String userId) async {
    print('🔍 REPO: Querying shared_tasks for user: $userId');

    final response = await _supabase
        .from('shared_tasks')
        .select('*, tasks(*)')
        .eq('shared_with', userId)
        .order('created_at', ascending: false);

    print('🔍 REPO: Raw response from shared_tasks: ${response.length} items');
    print('🔍 REPO: Response data: $response');

    // Fetch emails and project colors for each shared task
    List<Map<String, dynamic>> sharedTasks = [];
    for (var item in response) {
      print('🔍 REPO: Processing task item: $item');
      final task = item['tasks'];
      print('🔍 REPO: Task data: $task');
      if (task != null) {
        final sharedByEmail =
            await getUserEmail(item['shared_by']) ?? 'Unknown';
        final sharedWithEmail =
            await getUserEmail(item['shared_with']) ?? 'Unknown';
        final projectColor = await _getProjectColor(task['project_id']);

        sharedTasks.add({
          'task': Task.fromJson(task),
          'shared_by_email': sharedByEmail,
          'shared_with_email': sharedWithEmail,
          'permission': item['permission'],
          'created_at': item['created_at'],
          'project_color': projectColor,
        });

        print('🔍 REPO: Added task to list. Total now: ${sharedTasks.length}');
      } else {
        print('⚠️ REPO: Task is null for item');
      }
    }

    print('🔍 REPO: Returning ${sharedTasks.length} shared tasks');
    return sharedTasks;
  }

  /// Share a project with another user
  Future<void> shareProject({
    required String projectId,
    required String sharedWithUserId,
    String permission = 'view',
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    await _supabase.from('shared_projects').insert({
      'project_id': projectId,
      'shared_by': currentUserId,
      'shared_with': sharedWithUserId,
      'permission': permission,
    });
  }

  /// Share a task with another user
  Future<void> shareTask({
    required String taskId,
    required String sharedWithUserId,
    String permission = 'view',
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    await _supabase.from('shared_tasks').insert({
      'task_id': taskId,
      'shared_by': currentUserId,
      'shared_with': sharedWithUserId,
      'permission': permission,
    });
  }

  /// Unshare a project
  Future<void> unshareProject(String sharedProjectId) async {
    await _supabase.from('shared_projects').delete().eq('id', sharedProjectId);
  }

  /// Unshare a task
  Future<void> unshareTask(String sharedTaskId) async {
    await _supabase.from('shared_tasks').delete().eq('id', sharedTaskId);
  }

  /// Get shared by user email
  Future<String?> getUserEmail(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('email')
          .eq('id', userId)
          .maybeSingle();
      return response?['email'] as String?;
    } catch (e) {
      print('Error fetching user email: $e');
      return null;
    }
  }

  /// Get all member user IDs for a project (owner, assignee, shared users)
  Future<List<String>> getMemberUserIdsForProject(String projectId) async {
    try {
      // Fetch owner and assigned user from the project
      final project = await _supabase
          .from('projects')
          .select('owner_id, assigned_user_id')
          .eq('id', projectId)
          .maybeSingle();

      if (project == null) {
        return [];
      }

      final members = <String>{};

      final ownerId = project['owner_id'] as String?;
      final assignedUserId = project['assigned_user_id'] as String?;

      if (ownerId != null && ownerId.isNotEmpty) {
        members.add(ownerId);
      }
      if (assignedUserId != null && assignedUserId.isNotEmpty) {
        members.add(assignedUserId);
      }

      // Fetch additional members from shared_projects
      final sharedResponse = await _supabase
          .from('shared_projects')
          .select('shared_with')
          .eq('project_id', projectId);

      for (final item in sharedResponse) {
        final sharedWith = item['shared_with'] as String?;
        if (sharedWith != null && sharedWith.isNotEmpty) {
          members.add(sharedWith);
        }
      }

      return members.toList();
    } catch (e) {
      print('Error fetching project members: $e');
      return [];
    }
  }

  /// Helper to get project tasks
  Future<List<Task>> _getProjectTasks(String projectId) async {
    final response = await _supabase
        .from('tasks')
        .select('*')
        .eq('project_id', projectId);
    return response.map((json) => Task.fromJson(json)).toList();
  }

  /// Helper to get project color
  Future<Color> _getProjectColor(String? projectId) async {
    if (projectId == null) return Colors.blue;

    try {
      final project = await _supabase
          .from('projects')
          .select('card_color')
          .eq('id', projectId)
          .single();

      final colorString = project['card_color'] as String?;
      if (colorString != null) {
        return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
      }
    } catch (e) {
      // If project not found or error, return default
    }

    return Colors.blue;
  }
}
