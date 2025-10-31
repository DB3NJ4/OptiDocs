import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/pdf_model.dart';

class PDFProvider with ChangeNotifier {
  List<PDFModel> _pdfs = [];
  bool _isLoading = false;
  String? _error;

  List<PDFModel> get pdfs => _pdfs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ CARGAR PDFs (con reglas públicas)
  Future<void> loadPDFs() async {
    try {
      print('🔄 Cargando PDFs con reglas públicas...');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final snapshot = await FirebaseFirestore.instance
          .collection('pdfs')
          .where('userId', isEqualTo: user.uid)
          .orderBy('uploadDate', descending: true)
          .get();

      _pdfs = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final pdf = PDFModel.fromMap({...data, 'id': doc.id});

        // ✅ DEBUG: Ver información de cada PDF
        print('📄 PDF: ${pdf.name}');
        print('   🔗 URL: ${pdf.url}');
        print('   📏 Tamaño: ${pdf.size} bytes');

        return pdf;
      }).toList();

      print('✅ PDFs cargados: ${_pdfs.length}');
      _error = null;
    } catch (e) {
      print('❌ Error cargando PDFs: $e');
      _error = 'Error al cargar PDFs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ SUBIR PDF (con reglas públicas)
  Future<void> uploadPDF(PlatformFile file) async {
    try {
      print('🔼 Subiendo PDF: ${file.name}');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      if (file.bytes == null) {
        throw Exception('No se pudieron leer los datos del archivo');
      }

      // Crear nombre único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.uid}_${timestamp}_${file.name}';

      print('📤 Subiendo a Storage: $fileName');

      // ✅ SUBIR CON REGLAS PÚBLICAS
      final ref = FirebaseStorage.instance.ref().child('pdfs/$fileName');

      final uploadTask = ref.putData(
        file.bytes!,
        SettableMetadata(contentType: 'application/pdf'),
      );

      final snapshot = await uploadTask;

      // ✅ OBTENER URL PÚBLICA
      final String downloadUrl = await ref.getDownloadURL();

      print('✅ Archivo subido exitosamente');
      print('🔗 URL pública: $downloadUrl');

      // Guardar en Firestore
      final pdfData = {
        'name': file.name,
        'url': downloadUrl,
        'userId': user.uid,
        'uploadDate': Timestamp.now(),
        'size': file.size,
        'fileName': fileName,
      };

      final docRef =
          await FirebaseFirestore.instance.collection('pdfs').add(pdfData);

      // Agregar a lista local
      final newPDF = PDFModel(
        id: docRef.id,
        name: file.name,
        url: downloadUrl,
        uploadDate: DateTime.now(),
        size: file.size,
        userId: user.uid,
      );

      _pdfs.insert(0, newPDF);
      _error = null;

      print('🎉 PDF subido exitosamente: ${file.name}');
      notifyListeners();
    } catch (e) {
      print('❌ Error subiendo PDF: $e');
      _error = 'Error al subir PDF: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ ELIMINAR PDF
  Future<void> deletePDF(PDFModel pdf) async {
    try {
      print('🗑️ Eliminando PDF: ${pdf.name}');
      _isLoading = true;
      notifyListeners();

      // Eliminar de Firestore
      await FirebaseFirestore.instance.collection('pdfs').doc(pdf.id).delete();

      // Eliminar de Storage
      try {
        final ref = FirebaseStorage.instance.ref().child('pdfs/${pdf.name}');
        await ref.delete();
        print('✅ Eliminado de Storage');
      } catch (e) {
        print('⚠️ No se pudo eliminar de Storage: $e');
      }

      _pdfs.removeWhere((p) => p.id == pdf.id);
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar PDF: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
