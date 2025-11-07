import 'package:dev_flow/data/models/comment_model.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class RealtimeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream controllers for different data types
  final StreamController<Task> _taskUpdates =
      StreamController<Task>.broadcast();
  final StreamController<Project> _projectUpdates =
      StreamController<Project>.broadcast();
  final StreamController<Comment> _commentUpdates =
      StreamController<Comment>.broadcast();

  // Public streams
  Stream<Task> get taskUpdates => _taskUpdates.stream;
  Stream<Project> get projectUpdates => _projectUpdates.stream;
  Stream<Comment> get commentUpdates => _commentUpdates.stream;

  // Active channels (for cleanup)
  final Map<String, RealtimeChannel> _activeChannels = {};

  /// Subscribe to real-time updates for user's tasks (including quick todos)
  void subscribeToUserTasks(String userId) {
    final channelName = 'user_tasks_$userId';

    // Clean up existing subscription if any
    _unsubscribeChannel(channelName);

    final channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tasks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'owner_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              if (payload.eventType == PostgresChangeEvent.insert ||
                  payload.eventType == PostgresChangeEvent.update) {
                final task = Task.fromJson(payload.newRecord);
                _taskUpdates.add(task);
              }
            } catch (e) {
              print('Error processing task update: $e');
            }
          },
        );

    _activeChannels[channelName] = channel;
    channel.subscribe();
  }

  /// Subscribe to real-time updates for a specific project's tasks
  void subscribeToProjectTasks(String projectId) {
    final channelName = 'project_tasks_$projectId';

    _unsubscribeChannel(channelName);

    final channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tasks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'project_id',
            value: projectId,
          ),
          callback: (payload) {
            try {
              if (payload.eventType == PostgresChangeEvent.insert ||
                  payload.eventType == PostgresChangeEvent.update) {
                final task = Task.fromJson(payload.newRecord);
                _taskUpdates.add(task);
              }
            } catch (e) {
              print('Error processing project task update: $e');
            }
          },
        );

    _activeChannels[channelName] = channel;
    channel.subscribe();
  }

  /// Subscribe to real-time updates for user's projects
  void subscribeToUserProjects(String userId) {
    final channelName = 'user_projects_$userId';

    _unsubscribeChannel(channelName);

    final channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'projects',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'owner_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              if (payload.eventType == PostgresChangeEvent.insert ||
                  payload.eventType == PostgresChangeEvent.update) {
                final project = Project.fromJson(payload.newRecord);
                _projectUpdates.add(project);
              }
            } catch (e) {
              print('Error processing project update: $e');
            }
          },
        );

    _activeChannels[channelName] = channel;
    channel.subscribe();
  }

  /// Subscribe to real-time updates for a specific task's comments
  void subscribeToTaskComments(String taskId) {
    final channelName = 'task_comments_$taskId';

    _unsubscribeChannel(channelName);

    final channel = _supabase.channel(channelName);
    channel
        .onPostgresChanges(
          callback: (payload) {
            try {
              if (payload.eventType == PostgresChangeEvent.insert ||
                  payload.eventType == PostgresChangeEvent.update) {
                final comment = Comment.fromJson(payload.newRecord);
                _commentUpdates.add(comment);
              }
            } catch (e) {
              print('Error processing comment update: $e');
            }
          },
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'task_id',
            value: taskId,
          ),
        )
        .subscribe();

    _activeChannels[channelName] = channel;
  }

  /// Unsubscribe from a specific channel
  void _unsubscribeChannel(String channelName) {
    final existingChannel = _activeChannels[channelName];

    if (existingChannel != null) {
      _supabase.removeChannel(existingChannel);
      _activeChannels.remove(channelName);
    }
  }

  /// Unsubscribe from all channels and clean up
  void dispose() {
    // Remove all channels
    for (final channel in _activeChannels.values) {
      _supabase.removeChannel(channel);
    }
    _activeChannels.clear();

    // Close stream controllers
    _taskUpdates.close();
    _projectUpdates.close();
    _commentUpdates.close();
  }
}
