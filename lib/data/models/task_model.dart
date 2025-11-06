class Task {
  final String id;
  final String title;
  final DateTime date;
  final String time;
  final bool isCompleted;
  final String? assignedUserId;

  Task({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.isCompleted = false,
    this.assignedUserId,
  });

  Task copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? time,
    bool? isCompleted,
    String? assignedUserId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
      assignedUserId: assignedUserId ?? this.assignedUserId,
    );
  }
}

