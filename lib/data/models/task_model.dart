import 'package:dev_flow/data/models/attachment_model.dart';
import 'package:dev_flow/data/models/comment_model.dart';

class Task {
  final String id;
  final String title;
  final DateTime date;
  final String time;
  final bool isCompleted;
  final bool completed; // New field for Supabase
  final DateTime? completedAt; // New field for Supabase
  final String? assignedUserId;
  final String? projectId;
  final String userId;
  final String? priority; // 'high', 'medium', 'low'
  final DateTime? reminderAt;
  final bool isRecurring;
  final String? recurrencePattern;
  final String? description;
  final String? category; // For quick todos
  final String? parentTaskId; // For sub-tasks
  final List<String> dependencyIds; // IDs of tasks this depends on
  final int? estimatedMinutes;
  final List<Attachment> attachments;
  final List<Comment> comments;

  Task({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.isCompleted = false,
    bool? completed,
    this.completedAt,
    this.assignedUserId,
    this.projectId,
    required this.userId,
    this.priority,
    this.reminderAt,
    this.isRecurring = false,
    this.recurrencePattern,
    this.description,
    this.category,
    this.parentTaskId,
    this.dependencyIds = const [],
    this.estimatedMinutes,
    this.attachments = const [],
    this.comments = const [],
  }) : completed = completed ?? isCompleted;

  Task copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? time,
    bool? isCompleted,
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? assignedUserId,
    String? projectId,
    String? userId,
    String? priority,
    DateTime? reminderAt,
    bool? isRecurring,
    String? recurrencePattern,
    String? description,
    String? category,
    String? parentTaskId,
    List<String>? dependencyIds,
    int? estimatedMinutes,
    List<Attachment>? attachments,
    List<Comment>? comments,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
      completed: completed ?? this.completed,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      assignedUserId: assignedUserId ?? this.assignedUserId,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      priority: priority ?? this.priority,
      reminderAt: reminderAt ?? this.reminderAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      description: description ?? this.description,
      category: category ?? this.category,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      dependencyIds: dependencyIds ?? this.dependencyIds,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      attachments: attachments ?? this.attachments,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'time': time,
      'is_completed': isCompleted,
      'completed': completed,
      'completed_at': completedAt?.toIso8601String(),
      'assigned_user_id': assignedUserId,
      'project_id': projectId,
      'owner_id': userId,
      'priority': priority,
      'reminder_at': reminderAt?.toIso8601String(),
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
      'description': description,
      'category': category,
      'parent_task_id': parentTaskId,
      'estimated_minutes': estimatedMinutes,
    };
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    List<Attachment>? attachments,
    List<Comment>? comments,
    List<String>? dependencyIds,
  }) {
    // Handle both old and new completion fields with proper null safety
    final bool completedValue =
        (json['completed'] as bool?) ??
        (json['is_completed'] as bool?) ??
        false;

    return Task(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      isCompleted: completedValue,
      completed: completedValue,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      assignedUserId: json['assigned_user_id'],
      projectId: json['project_id'],
      userId: json['owner_id'],
      priority: json['priority'],
      reminderAt: json['reminder_at'] != null
          ? DateTime.parse(json['reminder_at'])
          : null,
      isRecurring: json['is_recurring'] ?? false,
      recurrencePattern: json['recurrence_pattern'],
      description: json['description'],
      category: json['category'],
      parentTaskId: json['parent_task_id'],
      dependencyIds: dependencyIds ?? [],
      estimatedMinutes: json['estimated_minutes'],
      attachments: attachments ?? [],
      comments: comments ?? [],
    );
  }
}
