import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'dart:io';

class ProjectMembersRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all members of a project
  Future<List<Map<String, dynamic>>> getProjectMembers(String projectId) async {
    print('👥 Fetching members for project: $projectId');

    final response = await _supabase
        .from('project_members')
        .select('*, profiles!project_members_user_id_fkey(*)')
        .eq('project_id', projectId)
        .order('added_at', ascending: true);

    print('👥 Found ${response.length} members');

    return response.map((item) {
      final profile = item['profiles'];
      return {
        'user_id': item['user_id'],
        'role': item['role'],
        'added_at': item['added_at'],
        'name': profile['name'] ?? 'Unknown',
        'email': profile['email'] ?? '',
        'avatar_url': profile['avatar_url'],
      };
    }).toList();
  }

  /// Add a member to a project
  Future<void> addMember({
    required String projectId,
    required String userId,
    String role = 'member',
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    print('👥 Adding member $userId to project $projectId with role $role');

    await _supabase.from('project_members').insert({
      'project_id': projectId,
      'user_id': userId,
      'role': role,
      'added_by': currentUserId,
    });

    print('👥 Member added successfully');
  }

  /// Remove a member from a project
  Future<void> removeMember({
    required String projectId,
    required String userId,
  }) async {
    print('👥 Removing member $userId from project $projectId');

    await _supabase
        .from('project_members')
        .delete()
        .eq('project_id', projectId)
        .eq('user_id', userId);

    print('👥 Member removed successfully');
  }

  /// Update member role
  Future<void> updateMemberRole({
    required String projectId,
    required String userId,
    required String role,
  }) async {
    print('👥 Updating role for member $userId to $role');

    await _supabase
        .from('project_members')
        .update({'role': role})
        .eq('project_id', projectId)
        .eq('user_id', userId);

    print('👥 Member role updated successfully');
  }

  /// Check if user is a member of a project
  Future<bool> isMember(String projectId, String userId) async {
    final response = await _supabase
        .from('project_members')
        .select('id')
        .eq('project_id', projectId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  /// Get member count for a project
  Future<int> getMemberCount(String projectId) async {
    final response = await _supabase
        .from('project_members')
        .select('id')
        .eq('project_id', projectId);

    return response.length;
  }
}

class ProjectAttachmentsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all attachments for a project
  Future<List<Map<String, dynamic>>> getProjectAttachments(
    String projectId,
  ) async {
    print('📎 Fetching attachments for project: $projectId');

    final response = await _supabase
        .from('project_attachments')
        .select('*, profiles!project_attachments_uploaded_by_fkey(*)')
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    print('📎 Found ${response.length} attachments');

    return response.map((item) {
      final profile = item['profiles'];
      return {
        'id': item['id'],
        'file_name': item['file_name'],
        'file_path': item['file_path'],
        'file_size': item['file_size'],
        'file_type': item['file_type'],
        'description': item['description'],
        'created_at': item['created_at'],
        'uploaded_by': item['uploaded_by'],
        'uploader_name': profile['name'] ?? 'Unknown',
        'uploader_email': profile['email'] ?? '',
      };
    }).toList();
  }

  /// Upload attachment to Supabase Storage and create database entry
  Future<String> uploadAttachment({
    required String projectId,
    required File file,
    required String fileName,
    String? description,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    print('📎 Uploading attachment: $fileName');

    // Generate unique file path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last;
    final storagePath = 'projects/$projectId/$timestamp.$extension';

    // Upload to Supabase Storage
    await _supabase.storage
        .from('DevFlow')
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    print('📎 File uploaded to storage: $storagePath');

    // Get file size
    final fileSize = await file.length();

    // Determine file type
    String fileType = 'other';
    if (extension.toLowerCase() == 'pdf') {
      fileType = 'pdf';
    } else if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
    ].contains(extension.toLowerCase())) {
      fileType = 'image';
    } else if (['doc', 'docx'].contains(extension.toLowerCase())) {
      fileType = 'document';
    } else if (['xls', 'xlsx'].contains(extension.toLowerCase())) {
      fileType = 'spreadsheet';
    }

    // Create database entry
    final response = await _supabase
        .from('project_attachments')
        .insert({
          'project_id': projectId,
          'file_name': fileName,
          'file_path': storagePath,
          'file_size': fileSize,
          'file_type': fileType,
          'description': description,
          'uploaded_by': currentUserId,
        })
        .select()
        .single();

    print('📎 Attachment created in database');

    return response['id'];
  }

  /// Delete attachment
  Future<void> deleteAttachment(String attachmentId) async {
    print('📎 Deleting attachment: $attachmentId');

    // Get file path first
    final attachment = await _supabase
        .from('project_attachments')
        .select('file_path')
        .eq('id', attachmentId)
        .single();

    final filePath = attachment['file_path'];

    // Delete from storage
    await _supabase.storage.from('DevFlow').remove([filePath]);

    // Delete from database
    await _supabase.from('project_attachments').delete().eq('id', attachmentId);

    print('📎 Attachment deleted successfully');
  }

  /// Get download URL for attachment
  Future<String> getAttachmentUrl(String filePath) async {
    final url = _supabase.storage.from('DevFlow').getPublicUrl(filePath);
    return url;
  }

  /// Get attachment count for a project
  Future<int> getAttachmentCount(String projectId) async {
    final response = await _supabase
        .from('project_attachments')
        .select('id')
        .eq('project_id', projectId);

    return response.length;
  }
}
