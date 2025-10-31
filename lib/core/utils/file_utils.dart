import 'dart:math';
import 'package:file_picker/file_picker.dart';

class FileUtils {
  static bool isValidPDF(PlatformFile file) {
    return file.extension?.toLowerCase() == 'pdf' && file.size > 0;
  }

  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  // Método adicional para validar nombre de archivo
  static String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }
}
