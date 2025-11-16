import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for downloading and opening files in native viewers
class FileViewerService {
  final Dio _dio = Dio();

  /// Download and open a file from a URL
  ///
  /// This method:
  /// 1. Downloads the file to a temporary directory
  /// 2. Opens it with the appropriate native app (gallery, PDF viewer, etc.)
  Future<OpenResult> downloadAndOpenFile({
    required String url,
    required String fileName,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      // Request storage permission on Android
      if (!kIsWeb && Platform.isAndroid) {
        final status = await _requestStoragePermission();
        if (!status) {
          return OpenResult(
            type: ResultType.permissionDenied,
            message: 'Storage permission denied',
          );
        }
      }

      // Get temporary directory to save the file
      final directory = await _getDownloadDirectory();
      final filePath = '${directory.path}/$fileName';

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        print('📁 File already exists at: $filePath');
        return await OpenFile.open(filePath);
      }

      // Download the file with progress tracking
      print('📥 Downloading file: $fileName');
      await _dio.download(url, filePath, onReceiveProgress: onProgress);

      print('✅ Download complete: $filePath');

      // Open the file with native viewer
      return await OpenFile.open(filePath);
    } catch (e) {
      print('❌ Error opening file: $e');
      return OpenResult(
        type: ResultType.error,
        message: 'Failed to open file: $e',
      );
    }
  }

  /// Get the appropriate directory for downloads
  Future<Directory> _getDownloadDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Web platform not supported');
    }

    if (Platform.isAndroid) {
      // For Android, use external storage if available, otherwise use app directory
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        // Create a DevFlow folder in the Downloads-like area
        final devFlowDir = Directory('${directory.path}/DevFlow');
        if (!await devFlowDir.exists()) {
          await devFlowDir.create(recursive: true);
        }
        return devFlowDir;
      }
    }

    // For iOS or fallback, use application documents directory
    return await getApplicationDocumentsDirectory();
  }

  /// Request storage permission for Android
  Future<bool> _requestStoragePermission() async {
    if (kIsWeb || !Platform.isAndroid) {
      return true;
    }

    // For Android 13+ (API 33+), we need different permissions
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();

      // Android 13+ doesn't require WRITE_EXTERNAL_STORAGE
      if (androidInfo >= 33) {
        return true;
      }

      // For older Android versions
      final status = await Permission.storage.status;
      if (status.isGranted) {
        return true;
      }

      final result = await Permission.storage.request();
      return result.isGranted;
    }

    return true;
  }

  /// Get Android version (API level)
  Future<int> _getAndroidVersion() async {
    // This is a simplified version - in production, use device_info_plus
    // For now, assume modern Android
    return 33;
  }

  /// Preview an image in a full-screen viewer (optional enhancement)
  /// For now, we'll just use the system's default image viewer
  Future<OpenResult> openImage(String url, String fileName) async {
    return await downloadAndOpenFile(url: url, fileName: fileName);
  }

  /// Open a PDF with the system's PDF viewer
  Future<OpenResult> openPDF(String url, String fileName) async {
    return await downloadAndOpenFile(url: url, fileName: fileName);
  }

  /// Open a document with the system's document viewer
  Future<OpenResult> openDocument(String url, String fileName) async {
    return await downloadAndOpenFile(url: url, fileName: fileName);
  }

  /// Get MIME type from file extension
  String getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';

      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';

      // Archives
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';

      // Video
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';

      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';

      default:
        return 'application/octet-stream';
    }
  }

  /// Clear cached downloaded files
  Future<void> clearCache() async {
    try {
      final directory = await _getDownloadDirectory();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        await directory.create();
      }
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }
}
