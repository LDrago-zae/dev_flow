import 'package:flutter/material.dart';
import 'task_model.dart';

enum ProjectPriority { high, medium, low }

enum ProjectStatus { ongoing, completed, onHold }

class Project {
  final String id;
  final String title;
  final String description;
  final String deadline;
  final DateTime createdDate;
  final double progress;
  final Color cardColor;
  final String category;
  final ProjectPriority priority;
  final ProjectStatus status;
  final String? imagePath;
  final List<Task> tasks;
  final String? assignedUserId;
  final String userId; // Owner
  final List<String> tags;
  final double? budget;
  final int? estimatedHours;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.createdDate,
    required this.progress,
    required this.cardColor,
    required this.category,
    this.priority = ProjectPriority.medium,
    this.status = ProjectStatus.ongoing,
    this.imagePath,
    this.tasks = const [],
    this.assignedUserId,
    required this.userId,
    this.tags = const [],
    this.budget,
    this.estimatedHours,
  });

  Project copyWith({
    String? id,
    String? title,
    String? description,
    String? deadline,
    DateTime? createdDate,
    double? progress,
    Color? cardColor,
    String? category,
    ProjectPriority? priority,
    ProjectStatus? status,
    String? imagePath,
    List<Task>? tasks,
    String? assignedUserId,
    String? userId,
    List<String>? tags,
    double? budget,
    int? estimatedHours,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      createdDate: createdDate ?? this.createdDate,
      progress: progress ?? this.progress,
      cardColor: cardColor ?? this.cardColor,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      tasks: tasks ?? this.tasks,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      userId: userId ?? this.userId,
      tags: tags ?? this.tags,
      budget: budget ?? this.budget,
      estimatedHours: estimatedHours ?? this.estimatedHours,
    );
  }

  // ...existing code...
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline,
      'created_date': createdDate.toIso8601String(),
      'progress': progress,
      'card_color': cardColor.value, // Changed: Remove .toString()
      'category': category,
      'priority': priority.name,
      'status': status.name,
      'image_path': imagePath,
      'assigned_user_id': assignedUserId,
      'owner_id': userId,
      'tags': tags,
      'budget': budget,
      'estimated_hours': estimatedHours,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json, {List<Task>? tasks}) {
    return Project(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      deadline: json['deadline'],
      createdDate: DateTime.parse(json['created_date']),
      progress: (json['progress'] as num).toDouble(),
      cardColor: Color(
        json['card_color'] is String
            ? int.parse(json['card_color'])
            : json['card_color'],
      ), // Changed: Handle both String and int
      category: json['category'],
      priority: json['priority'] != null
          ? ProjectPriority.values.firstWhere(
              (e) => e.name == json['priority'],
              orElse: () => ProjectPriority.medium,
            )
          : ProjectPriority.medium,
      status: json['status'] != null
          ? ProjectStatus.values.firstWhere(
              (e) => e.name == json['status'],
              orElse: () => ProjectStatus.ongoing,
            )
          : ProjectStatus.ongoing,
      imagePath: json['image_path'] as String?,
      assignedUserId: json['assigned_user_id'] as String?,
      userId: json['owner_id'] ?? json['user_id'],
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
      budget: json['budget'] != null
          ? (json['budget'] as num).toDouble()
          : null,
      estimatedHours: json['estimated_hours'] as int?,
      tasks: tasks ?? [],
    );
  }
  // ...existing code...

  int get completedTasksCount => tasks.where((task) => task.isCompleted).length;
  int get totalTasksCount => tasks.length;
}
