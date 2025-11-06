import 'package:flutter/material.dart';
import 'task_model.dart';

enum ProjectPriority { high, medium, low }
enum ProjectStatus { ongoing, completed, onHold }

class Project {
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

  Project({
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
  });

  Project copyWith({
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
  }) {
    return Project(
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
    );
  }

  int get completedTasksCount => tasks.where((task) => task.isCompleted).length;
  int get totalTasksCount => tasks.length;
}
