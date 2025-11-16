import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_attachment_model.dart';

class ProjectAttachmentsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'DevFlow';
  static const String _attachmentsFolder = 'project_attachments';

  /// Get all attachments for a project
  Future<List<Map<String, dynamic>>> getProjectAttachments(
    String projectId,
  ) async {
    print('📎 Fetching attachments for project: $projectId');

    final response = await _supabase
        .from('project_attachments')
        .select('''
          *,
          profiles!project_attachments_uploaded_by_fkey (
            id,
            name,
            email
          )
        ''')
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    print('📎 Found ${response.length} attachments');

    return response.map<Map<String, dynamic>>((item) {
      return {
        'id': item['id'],
        'project_id': item['project_id'],
        'file_name': item['file_name'],
        'file_path': item['file_path'],
        'file_size': item['file_size'],
        'file_type': _detectFileType(item['file_name']),
        'uploaded_by': item['uploaded_by'],
        'uploader_name': item['profiles']?['name'] ?? 'Unknown',
        'uploader_email': item['profiles']?['email'] ?? '',
        'created_at': item['created_at'],
      };
    }).toList();
  }

  /// Upload a file attachment to a project
  Future<ProjectAttachment> uploadAttachment({
    required String projectId,
    required File file,
    required String fileName,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    print('📎 Uploading attachment: $fileName');

    // Generate unique file path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last;
    final uniqueFileName = '${timestamp}_$fileName';
    final filePath = '$_attachmentsFolder/$projectId/$uniqueFileName';

    // Upload to Supabase Storage
    print('📎 Uploading to storage: $filePath');
    await _supabase.storage
        .from(_bucketName)
        .upload(filePath, file, fileOptions: const FileOptions(upsert: false));

    // Get file size
    final fileSize = await file.length();

    // Create database record
    print('📎 Creating database record');
    final response = await _supabase
        .from('project_attachments')
        .insert({
          'project_id': projectId,
          'file_name': fileName,
          'file_path': filePath,
          'file_size': fileSize,
          'file_type': _detectFileType(fileName),
          'uploaded_by': userId,
        })
        .select()
        .single();

    print('📎 Upload successful: ${response['id']}');
    return ProjectAttachment.fromJson(response);
  }

  /// Delete an attachment
  Future<void> deleteAttachment(String attachmentId) async {
    print('📎 Deleting attachment: $attachmentId');

    // Get attachment info first
    final attachment = await _supabase
        .from('project_attachments')
        .select('file_path')
        .eq('id', attachmentId)
        .single();

    final filePath = attachment['file_path'] as String;

    // Delete from storage
    print('📎 Deleting from storage: $filePath');
    await _supabase.storage.from(_bucketName).remove([filePath]);

    // Delete from database
    print('📎 Deleting from database');
    await _supabase.from('project_attachments').delete().eq('id', attachmentId);

    print('📎 Deletion successful');
  }

  /// Get public URL for an attachment
  Future<String> getAttachmentUrl(String filePath) async {
    print('📎 Getting URL for: $filePath');

    final url = _supabase.storage.from(_bucketName).getPublicUrl(filePath);

    print('📎 URL: $url');
    return url;
  }

  /// Detect file type from filename
  String _detectFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (['pdf'].contains(extension)) {
      return 'pdf';
    } else if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'svg',
    ].contains(extension)) {
      return 'image';
    } else if (['doc', 'docx', 'txt', 'rtf'].contains(extension)) {
      return 'document';
    } else if (['xls', 'xlsx', 'csv'].contains(extension)) {
      return 'spreadsheet';
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(extension)) {
      return 'archive';
    } else if (['mp4', 'avi', 'mov', 'wmv'].contains(extension)) {
      return 'video';
    } else if (['mp3', 'wav', 'ogg', 'flac'].contains(extension)) {
      return 'audio';
    } else {
      return 'other';
    }
  }
}
