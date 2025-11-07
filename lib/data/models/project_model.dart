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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline,
      'created_date': createdDate.toIso8601String(),
      'progress': progress,
      'card_color': cardColor.value.toString(),
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
      cardColor: Color(int.parse(json['card_color'])),
      category: json['category'],
      priority: ProjectPriority.values.byName(json['priority']),
      status: ProjectStatus.values.byName(json['status']),
      imagePath: json['image_path'],
      assignedUserId: json['assigned_user_id'],
      userId: json['owner_id'],
      tags: List<String>.from(json['tags'] ?? []),
      budget: json['budget'] != null
          ? (json['budget'] as num).toDouble()
          : null,
      estimatedHours: json['estimated_hours'],
      tasks: tasks ?? [],
    );
  }

  int get completedTasksCount => tasks.where((task) => task.isCompleted).length;
  int get totalTasksCount => tasks.length;
}
