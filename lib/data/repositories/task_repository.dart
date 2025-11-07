import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/attachment_model.dart';
import '../models/comment_model.dart';

class TaskRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Task>> getTasks(String userId, {String? projectId}) async {
    var query = _supabase.from('tasks').select('*').eq('owner_id', userId);
    if (projectId != null) {
      query = query.eq('project_id', projectId);
    } else {
      query = query.filter('project_id', 'is', null); // Quick todos
    }
    final response = await query.order('date', ascending: true);
    return await Future.wait(response.map((json) async {
      final attachments = await getTaskAttachments(json['id']);
      final comments = await getTaskComments(json['id']);
      final dependencies = await getTaskDependencies(json['id']);
      return Task.fromJson(json, attachments: attachments, comments: comments, dependencyIds: dependencies);
    }));
  }

  Future<List<Attachment>> getTaskAttachments(String taskId) async {
    final response = await _supabase.from('attachments').select('*').eq('task_id', taskId);
    return response.map((json) => Attachment.fromJson(json)).toList();
  }

  Future<List<Comment>> getTaskComments(String taskId) async {
    final response = await _supabase.from('comments').select('*').eq('task_id', taskId).order('created_at', ascending: false);
    return response.map((json) => Comment.fromJson(json)).toList();
  }

  Future<List<String>> getTaskDependencies(String taskId) async {
    final response = await _supabase.from('task_dependencies').select('depends_on_task_id').eq('task_id', taskId);
    return response.map((json) => json['depends_on_task_id'] as String).toList();
  }

  Future<Task> createTask(Task task) async {
    final json = task.toJson();
    final response = await _supabase.from('tasks').insert(json).select().single();
    return Task.fromJson(response);
  }

  Future<void> updateTask(Task task) async {
    final json = task.toJson();
    await _supabase.from('tasks').update(json).eq('id', task.id);
  }

  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }
}
