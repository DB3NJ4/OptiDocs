import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../data/models/pdf_model.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<PDFModel> uploadPDF(PlatformFile file) async {
    try {
      print('🔄 Iniciando subida de PDF: ${file.name}');

      // Subir archivo a Storage
      final Reference ref = _storage.ref().child(
          '${AppConstants.pdfStoragePath}/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      final UploadTask uploadTask = ref.putData(file.bytes!);

      print('📤 Subiendo archivo a Storage...');
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadURL = await snapshot.ref.getDownloadURL();
      print('✅ Archivo subido. URL: $downloadURL');

      // Crear modelo PDF
      final pdf = PDFModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: file.name,
        url: downloadURL,
        uploadDate: DateTime.now(),
        size: file.size,
      );

      // Guardar en Firestore
      print('💾 Guardando metadata en Firestore...');
      await _firestore
          .collection(AppConstants.pdfsCollection)
          .doc(pdf.id)
          .set(pdf.toMap());
      print('✅ Metadata guardada en Firestore');

      return pdf;
    } catch (e) {
      print('❌ Error al subir PDF: $e');
      throw Exception('Error al subir PDF: $e');
    }
  }

  Stream<List<PDFModel>> getPDFs() {
    print('📡 Suscribiéndose a PDFs de Firestore...');
    return _firestore
        .collection(AppConstants.pdfsCollection)
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📄 PDFs recibidos: ${snapshot.docs.length} documentos');
      return snapshot.docs.map((doc) => PDFModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> deletePDF(PDFModel pdf) async {
    try {
      print('🗑️ Eliminando PDF: ${pdf.name}');

      // Eliminar de Storage
      final Reference ref = _storage.refFromURL(pdf.url);
      await ref.delete();
      print('✅ PDF eliminado de Storage');

      // Eliminar de Firestore
      await _firestore
          .collection(AppConstants.pdfsCollection)
          .doc(pdf.id)
          .delete();
      print('✅ PDF eliminado de Firestore');
    } catch (e) {
      print('❌ Error al eliminar PDF: $e');
      throw Exception('Error al eliminar PDF: $e');
    }
  }
}
