class Comment {
  final String id;
  final String commentText;
  final DateTime createdAt;
  final String userId;

  Comment({
    required this.id,
    required this.commentText,
    required this.createdAt,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'comment_text': commentText,
    'created_at': createdAt.toIso8601String(),
    'user_id': userId,
  };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'],
    commentText: json['comment_text'],
    createdAt: DateTime.parse(json['created_at']),
    userId: json['user_id'],
  );
}
