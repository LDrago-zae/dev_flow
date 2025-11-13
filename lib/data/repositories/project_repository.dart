import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';

class ProjectRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Project>> getProjects(String userId) async {
    final response = await _supabase
        .from('projects')
        .select('*')
        .eq('owner_id', userId)
        .order('created_date', ascending: false);

    print('DEBUG: Projects from DB: ${response.length}');
    for (var json in response) {
      print(
        'DEBUG: Project ${json['title']} - image_path: ${json['image_path']}, assigned_user_id: ${json['assigned_user_id']}',
      );
    }

    return await Future.wait(
      response.map((json) async {
        final tasks = await getProjectTasks(json['id']);
        return Project.fromJson(json, tasks: tasks);
      }),
    );
  }

  Future<Project> getProjectById(String projectId) async {
    final response = await _supabase
        .from('projects')
        .select('*')
        .eq('id', projectId)
        .single();

    print(
      'DEBUG: Fetched project ${response['title']} - image_path: ${response['image_path']}, assigned_user_id: ${response['assigned_user_id']}',
    );

    final tasks = await getProjectTasks(projectId);
    return Project.fromJson(response, tasks: tasks);
  }

  Future<List<Task>> getProjectTasks(String projectId) async {
    final response = await _supabase
        .from('tasks')
        .select('*')
        .eq('project_id', projectId);
    return response.map((json) => Task.fromJson(json)).toList();
  }

  Future<Project> createProject(Project project) async {
    final json = project.toJson();
    final response = await _supabase
        .from('projects')
        .insert(json)
        .select()
        .single();
    return Project.fromJson(response);
  }

  Future<void> updateProject(Project project) async {
    final json = project.toJson();
    await _supabase.from('projects').update(json).eq('id', project.id);
  }

  Future<void> deleteProject(String projectId) async {
    await _supabase.from('projects').delete().eq('id', projectId);
  }
}
