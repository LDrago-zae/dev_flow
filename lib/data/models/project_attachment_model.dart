class ProjectAttachment {
  final String id;
  final String projectId;
  final String fileName;
  final String filePath;
  final int? fileSize;
  final String? fileType;
  final String uploadedBy;
  final DateTime createdAt;

  ProjectAttachment({
    required this.id,
    required this.projectId,
    required this.fileName,
    required this.filePath,
    this.fileSize,
    this.fileType,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory ProjectAttachment.fromJson(Map<String, dynamic> json) {
    return ProjectAttachment(
      id: json['id'],
      projectId: json['project_id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      fileSize: json['file_size'] as int?,
      fileType: json['file_type'] as String?,
      uploadedBy: json['uploaded_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'file_type': fileType,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedSize {
    if (fileSize == null) return 'Unknown size';

    final kb = fileSize! / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }

    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
  }
}
