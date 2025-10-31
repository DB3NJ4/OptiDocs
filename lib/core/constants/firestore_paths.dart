class FirestorePaths {
  static String pdf(String pdfId) => 'pdfs/$pdfId';
  static String user(String userId) => 'users/$userId';

  static const String pdfsCollection = 'pdfs';
  static const String usersCollection = 'users';
}
