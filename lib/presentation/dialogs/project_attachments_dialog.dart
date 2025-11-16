import 'package:flutter/material.dart';
import 'package:dev_flow/data/repositories/project_attachments_repository.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dev_flow/services/file_viewer_service.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:dev_flow/presentation/widgets/animated_fade_slide.dart';

class ProjectAttachmentsDialog extends StatefulWidget {
  final String projectId;
  final VoidCallback onAttachmentsChanged;

  const ProjectAttachmentsDialog({
    super.key,
    required this.projectId,
    required this.onAttachmentsChanged,
  });

  @override
  State<ProjectAttachmentsDialog> createState() =>
      _ProjectAttachmentsDialogState();
}

class _ProjectAttachmentsDialogState extends State<ProjectAttachmentsDialog> {
  final ProjectAttachmentsRepository _attachmentsRepository =
      ProjectAttachmentsRepository();
  final FileViewerService _fileViewerService = FileViewerService();
  List<Map<String, dynamic>> _attachments = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _downloadingFileId;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    setState(() => _isLoading = true);

    try {
      final attachments = await _attachmentsRepository.getProjectAttachments(
        widget.projectId,
      );
      setState(() {
        _attachments = attachments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading attachments: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      setState(() => _isUploading = true);

      await _attachmentsRepository.uploadAttachment(
        projectId: widget.projectId,
        file: File(file.path!),
        fileName: file.name,
      );

      widget.onAttachmentsChanged();
      await _loadAttachments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteAttachment(String attachmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'Delete Attachment',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this attachment?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _attachmentsRepository.deleteAttachment(attachmentId);
      widget.onAttachmentsChanged();
      await _loadAttachments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attachment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete attachment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAttachment(Map<String, dynamic> attachment) async {
    setState(() {
      _downloadingFileId = attachment['id'];
      _downloadProgress = 0.0;
    });

    try {
      final url = await _attachmentsRepository.getAttachmentUrl(
        attachment['file_path'],
      );
      final fileName = attachment['file_name'] as String;

      // Use FileViewerService to download and open the file
      final result = await _fileViewerService.downloadAndOpenFile(
        url: url,
        fileName: fileName,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadingFileId = null;
          _downloadProgress = 0.0;
        });

        // Handle different result types
        if (result.type == ResultType.done) {
          // File opened successfully
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File opened successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        } else if (result.type == ResultType.noAppToOpen) {
          // No app available to open this file type
          _showNoAppDialog(fileName);
        } else if (result.type == ResultType.permissionDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission required to open files'),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (result.type == ResultType.fileNotFound) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // Other errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadingFileId = null;
          _downloadProgress = 0.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNoAppDialog(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    final suggestedApps = _getSuggestedApps(extension);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'No App Available',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No app found to open "$fileName".',
              style: const TextStyle(color: Colors.white70),
            ),
            if (suggestedApps.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Suggested apps:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...suggestedApps.map(
                (app) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '• $app',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<String> _getSuggestedApps(String extension) {
    switch (extension) {
      case 'pdf':
        return ['Adobe Acrobat Reader', 'Google PDF Viewer', 'Foxit PDF'];
      case 'doc':
      case 'docx':
        return ['Microsoft Word', 'Google Docs', 'WPS Office'];
      case 'xls':
      case 'xlsx':
        return ['Microsoft Excel', 'Google Sheets', 'WPS Office'];
      case 'ppt':
      case 'pptx':
        return ['Microsoft PowerPoint', 'Google Slides', 'WPS Office'];
      case 'zip':
      case 'rar':
      case '7z':
        return ['ZArchiver', 'RAR', 'WinZip'];
      case 'mp4':
      case 'avi':
      case 'mov':
        return ['VLC', 'MX Player', 'Google Photos'];
      case 'mp3':
      case 'wav':
      case 'ogg':
        return ['VLC', 'Google Play Music', 'Spotify'];
      default:
        return ['Google Files', 'File Manager'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          AnimatedFadeSlide(
            delay: 0.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attachments',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_attachments.length} file${_attachments.length != 1 ? 's' : ''}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _isUploading ? null : _pickAndUploadFile,
                      style: IconButton.styleFrom(
                        backgroundColor: DarkThemeColors.primary100,
                        padding: const EdgeInsets.all(8),
                      ),
                      iconSize: 20,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload_file, color: Colors.white),
                      tooltip: 'Upload Attachment',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      iconSize: 20,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Attachments list
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DarkThemeColors.primary100,
                      ),
                    )
                  : _attachments.isEmpty
                  ? AnimatedFadeSlide(
                      delay: 0.2,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No attachments yet',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upload files, PDFs, images and more',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _attachments.length,
                      itemBuilder: (context, index) {
                        final attachment = _attachments[index];
                        return AnimatedFadeSlide(
                          delay: 0.2 + (index * 0.1),
                          child: _buildAttachmentTile(attachment),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(Map<String, dynamic> attachment) {
    final fileType = attachment['file_type'] as String;
    final fileName = attachment['file_name'] as String;
    final fileSize = attachment['file_size'] as int?;
    final uploaderName = attachment['uploader_name'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getFileTypeColor(fileType).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileTypeIcon(fileType),
              color: _getFileTypeColor(fileType),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        uploaderName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (fileSize != null) ...[
                      Text(
                        ' • ${_formatFileSize(fileSize)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show download progress or open button
              if (_downloadingFileId == attachment['id'])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _downloadProgress,
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                        if (_downloadProgress > 0)
                          Text(
                            '${(_downloadProgress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.blue),
                  tooltip: 'Open',
                  onPressed: () => _openAttachment(attachment),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete',
                onPressed: () => _deleteAttachment(attachment['id']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'document':
        return Icons.description;
      case 'spreadsheet':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'image':
        return Colors.green;
      case 'document':
        return Colors.blue;
      case 'spreadsheet':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static Future<void> show(
    BuildContext context, {
    required String projectId,
    required VoidCallback onAttachmentsChanged,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ProjectAttachmentsDialog(
        projectId: projectId,
        onAttachmentsChanged: onAttachmentsChanged,
      ),
    );
  }
}
