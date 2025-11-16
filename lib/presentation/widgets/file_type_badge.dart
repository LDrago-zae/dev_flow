import 'package:flutter/material.dart';

/// A widget that displays a file type badge with an icon and color
class FileTypeBadge extends StatelessWidget {
  final String fileType;
  final double size;

  const FileTypeBadge({super.key, required this.fileType, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final fileInfo = _getFileInfo(fileType);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fileInfo.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(size * 0.15),
      ),
      child: Icon(fileInfo.icon, color: fileInfo.color, size: size * 0.5),
    );
  }

  _FileInfo _getFileInfo(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return _FileInfo(
          icon: Icons.picture_as_pdf,
          color: const Color(0xFFE53935), // Red
        );
      case 'image':
        return _FileInfo(
          icon: Icons.image,
          color: const Color(0xFF43A047), // Green
        );
      case 'document':
        return _FileInfo(
          icon: Icons.description,
          color: const Color(0xFF1E88E5), // Blue
        );
      case 'spreadsheet':
        return _FileInfo(
          icon: Icons.table_chart,
          color: const Color(0xFF00897B), // Teal
        );
      case 'archive':
        return _FileInfo(
          icon: Icons.folder_zip,
          color: const Color(0xFFFB8C00), // Orange
        );
      case 'video':
        return _FileInfo(
          icon: Icons.videocam,
          color: const Color(0xFF8E24AA), // Purple
        );
      case 'audio':
        return _FileInfo(
          icon: Icons.music_note,
          color: const Color(0xFFD81B60), // Pink
        );
      default:
        return _FileInfo(
          icon: Icons.insert_drive_file,
          color: const Color(0xFF757575), // Grey
        );
    }
  }
}

class _FileInfo {
  final IconData icon;
  final Color color;

  _FileInfo({required this.icon, required this.color});
}

/// Extension on String to get file type from extension
extension FileTypeExtension on String {
  String get fileType {
    final extension = split('.').last.toLowerCase();

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
    } else if (['mp4', 'avi', 'mov', 'wmv', 'mkv'].contains(extension)) {
      return 'video';
    } else if (['mp3', 'wav', 'ogg', 'flac', 'aac'].contains(extension)) {
      return 'audio';
    } else {
      return 'other';
    }
  }

  bool get isImage => fileType == 'image';
  bool get isPDF => fileType == 'pdf';
  bool get isDocument => fileType == 'document';
  bool get isVideo => fileType == 'video';
  bool get isAudio => fileType == 'audio';
}
