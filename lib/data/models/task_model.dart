class Task {
  final String id;
  final String title;
  final DateTime date;
  final String time;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.isCompleted = false,
  });

  Task copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? time,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

