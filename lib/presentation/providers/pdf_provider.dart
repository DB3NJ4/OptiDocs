import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart'; // ← Agregar esta línea
import '../../services/storage_service.dart';
import '../../data/models/pdf_model.dart';

class PDFProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<PDFModel> _pdfs = [];
  bool _isLoading = false;
  String? _error;

  List<PDFModel> get pdfs => _pdfs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PDFProvider() {
    loadPDFs();
  }

  void loadPDFs() {
    _storageService.getPDFs().listen((pdfs) {
      _pdfs = pdfs;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      notifyListeners();
    });
  }

  Future<void> uploadPDF(PlatformFile file) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _storageService.uploadPDF(file);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deletePDF(PDFModel pdf) async {
    try {
      await _storageService.deletePDF(pdf);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
