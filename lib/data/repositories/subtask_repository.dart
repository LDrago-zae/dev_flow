import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subtask_model.dart';

class SubtaskRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Subtask>> getSubtasks(String parentTaskId) async {
    try {
      if (kDebugMode) {
        print('📥 Fetching subtasks for task: $parentTaskId');
      }
      final response = await _supabase
          .from('subtasks')
          .select('*')
          .eq('parent_task_id', parentTaskId)
          .order('order_index', ascending: true);

      final subtasks = (response as List)
          .map((json) => Subtask.fromJson(json))
          .toList();

      if (kDebugMode) {
        print('✅ Found ${subtasks.length} subtasks');
      }

      return subtasks;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch subtasks: $e');
      }
      throw Exception('Failed to fetch subtasks: $e');
    }
  }

  Future<Subtask> createSubtask(Subtask subtask) async {
    try {
      if (kDebugMode) {
        print('📤 Creating subtask in SUBTASKS table: ${subtask.title}');
        print('   Parent task ID: ${subtask.parentTaskId}');
        print('   Data: ${subtask.toJson()}');
      }

      final response = await _supabase
          .from('subtasks')
          .insert(subtask.toJson())
          .select()
          .single();

      if (kDebugMode) {
        print('✅ Subtask created successfully in SUBTASKS table');
        print('   Response: $response');
      }

      return Subtask.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to create subtask: $e');
      }
      throw Exception('Failed to create subtask: $e');
    }
  }

  Future<void> updateSubtask(Subtask subtask) async {
    try {
      if (kDebugMode) {
        print('📝 Updating subtask in SUBTASKS table: ${subtask.id}');
      }

      await _supabase
          .from('subtasks')
          .update(subtask.toJson())
          .eq('id', subtask.id);

      if (kDebugMode) {
        print('✅ Subtask updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update subtask: $e');
      }
      throw Exception('Failed to update subtask: $e');
    }
  }

  Future<void> deleteSubtask(String subtaskId) async {
    try {
      if (kDebugMode) {
        print('🗑️ Deleting subtask from SUBTASKS table: $subtaskId');
      }

      await _supabase.from('subtasks').delete().eq('id', subtaskId);

      if (kDebugMode) {
        print('✅ Subtask deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to delete subtask: $e');
      }
      throw Exception('Failed to delete subtask: $e');
    }
  }

  Future<void> toggleSubtaskCompletion(
    String subtaskId,
    bool isCompleted,
  ) async {
    try {
      if (kDebugMode) {
        print(
          '🔄 Toggling subtask completion in SUBTASKS table: $subtaskId -> $isCompleted',
        );
      }

      await _supabase
          .from('subtasks')
          .update({'is_completed': isCompleted})
          .eq('id', subtaskId);

      if (kDebugMode) {
        print('✅ Subtask completion toggled successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to toggle subtask: $e');
      }
      throw Exception('Failed to toggle subtask: $e');
    }
  }

  Stream<List<Subtask>> watchSubtasks(String parentTaskId) {
    if (kDebugMode) {
      print(
        '👀 Setting up real-time watch for subtasks of task: $parentTaskId',
      );
    }

    return _supabase
        .from('subtasks')
        .stream(primaryKey: ['id'])
        .eq('parent_task_id', parentTaskId)
        .order('order_index')
        .map((data) {
          if (kDebugMode) {
            print('📡 Received real-time update: ${data.length} subtasks');
          }
          return data.map((json) => Subtask.fromJson(json)).toList();
        });
  }
}
