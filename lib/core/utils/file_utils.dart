import 'dart:math';
import 'package:file_picker/file_picker.dart';
import '../constants/app_constants.dart'; // ← Esta línea ya debería estar

class FileUtils {
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  static String getFileName(String path) {
    return path.split('/').last;
  }

  static bool isValidPDF(PlatformFile file) {
    return file.extension == 'pdf' && file.size <= AppConstants.maxFileSize;
  }

  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }
}
