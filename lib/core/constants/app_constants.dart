class AppConstants {
  static const String appName = 'OptiDocs';
  static const String appVersion = '1.0.0';

  // Storage
  static const String pdfStoragePath = 'pdfs';
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const List<String> allowedExtensions = ['pdf'];

  // Collections
  static const String pdfsCollection = 'pdfs';
  static const String usersCollection = 'users';

  // Mensajes
  static const String uploadSuccess = 'PDF subido exitosamente';
  static const String uploadError = 'Error al subir PDF';
  static const String deleteSuccess = 'PDF eliminado exitosamente';
  static const String deleteError = 'Error al eliminar PDF';
}
