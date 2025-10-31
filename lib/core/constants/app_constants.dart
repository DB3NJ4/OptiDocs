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
}
