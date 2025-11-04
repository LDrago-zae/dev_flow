import 'package:flutter/material.dart';

class Project {
  final String title;
  final String description;
  final String deadline;
  final double progress;
  final Color cardColor;
  final String category;

  Project({
    required this.title,
    required this.description,
    required this.deadline,
    required this.progress,
    required this.cardColor,
    required this.category,
  });

  Project copyWith({
    String? title,
    String? description,
    String? deadline,
    double? progress,
    Color? cardColor,
    String? category,
  }) {
    return Project(
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      progress: progress ?? this.progress,
      cardColor: cardColor ?? this.cardColor,
      category: category ?? this.category,
    );
  }
}
