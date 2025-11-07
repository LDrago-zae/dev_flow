class Attachment {
  final String id;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final DateTime uploadedAt;
  final String userId;

  Attachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.uploadedAt,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'file_name': fileName,
    'file_url': fileUrl,
    'file_type': fileType,
    'uploaded_at': uploadedAt.toIso8601String(),
    'user_id': userId,
  };

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    id: json['id'],
    fileName: json['file_name'],
    fileUrl: json['file_url'],
    fileType: json['file_type'],
    uploadedAt: DateTime.parse(json['uploaded_at']),
    userId: json['user_id'],
  );
}
