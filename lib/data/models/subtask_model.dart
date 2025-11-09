class Subtask {
  final String id;
  final String parentTaskId;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdDate;
  final DateTime? dueDate;
  final String? assignedUserId;
  final String ownerId;
  final String priority;
  final int? estimatedMinutes;
  final int orderIndex;

  Subtask({
    required this.id,
    required this.parentTaskId,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.createdDate,
    this.dueDate,
    this.assignedUserId,
    required this.ownerId,
    this.priority = 'medium',
    this.estimatedMinutes,
    this.orderIndex = 0,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'],
      parentTaskId: json['parent_task_id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['is_completed'] ?? false,
      createdDate: DateTime.parse(json['created_date']),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      assignedUserId: json['assigned_user_id'],
      ownerId: json['owner_id'],
      priority: json['priority'] ?? 'medium',
      estimatedMinutes: json['estimated_minutes'],
      orderIndex: json['order_index'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_task_id': parentTaskId,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'created_date': createdDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'assigned_user_id': assignedUserId,
      'owner_id': ownerId,
      'priority': priority,
      'estimated_minutes': estimatedMinutes,
      'order_index': orderIndex,
    };
  }

  Subtask copyWith({
    String? id,
    String? parentTaskId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdDate,
    DateTime? dueDate,
    String? assignedUserId,
    String? ownerId,
    String? priority,
    int? estimatedMinutes,
    int? orderIndex,
  }) {
    return Subtask(
      id: id ?? this.id,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdDate: createdDate ?? this.createdDate,
      dueDate: dueDate ?? this.dueDate,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      ownerId: ownerId ?? this.ownerId,
      priority: priority ?? this.priority,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
