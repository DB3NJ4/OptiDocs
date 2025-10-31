import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/pdf_model.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/file_utils.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Subir PDF a Storage y guardar metadata en Firestore
  Future<PDFModel> uploadPDF(PlatformFile file) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      print('🔄 Iniciando subida de PDF: ${file.name}');
      print('🔍 User ID: ${user.uid}');

      // Validar tipo y tamaño de archivo
      if (!FileUtils.isValidPDF(file)) {
        throw Exception(
            'Archivo no válido. Debe ser PDF y menor a ${AppConstants.maxFileSize ~/ (1024 * 1024)}MB');
      }

      // Crear nombre de archivo seguro con user ID
      final fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${_sanitizeFileName(file.name)}';
      final Reference ref =
          _storage.ref().child('${AppConstants.pdfStoragePath}/$fileName');

      // Subir archivo a Storage
      final UploadTask uploadTask = ref.putData(
        file.bytes!,
        SettableMetadata(contentType: 'application/pdf'),
      );

      print('📤 Subiendo archivo a Storage...');
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadURL = await snapshot.ref.getDownloadURL();
      print('✅ Archivo subido. URL: $downloadURL');

      // Crear modelo PDF con user ID
      final pdf = PDFModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: file.name,
        url: downloadURL,
        uploadDate: DateTime.now(),
        size: file.size,
        userId: user.uid,
      );

      // Guardar metadata en Firestore
      print('💾 Guardando metadata en Firestore...');
      print('🔍 Datos a guardar: ${pdf.toMap()}');

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

  // Obtener stream de PDFs del usuario actual
  Stream<List<PDFModel>> getPDFs() {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ Usuario no autenticado, retornando lista vacía');
      return Stream.value([]);
    }

    print('📡 Suscribiéndose a PDFs del usuario: ${user.uid}');

    return _firestore
        .collection(AppConstants.pdfsCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📄 PDFs recibidos: ${snapshot.docs.length} documentos');

      // Debug: imprimir cada documento
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print(
            '📋 Documento: ${doc.id} - ${data['name']} - userId: ${data['userId']}');
      }

      return snapshot.docs
          .map((doc) {
            try {
              return PDFModel.fromMap(doc.data());
            } catch (e) {
              print('❌ Error parseando documento ${doc.id}: $e');
              print('📄 Datos del documento: ${doc.data()}');
              return null;
            }
          })
          .where((pdf) => pdf != null)
          .cast<PDFModel>()
          .toList();
    });
  }

  // Eliminar PDF de Storage y Firestore
  Future<void> deletePDF(PDFModel pdf) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Verificar que el PDF pertenece al usuario actual
      if (pdf.userId != user.uid) {
        throw Exception('No tienes permisos para eliminar este PDF');
      }

      print('🗑️ Eliminando PDF: ${pdf.name}');
      print('🔍 User ID del PDF: ${pdf.userId}');
      print('🔍 User ID actual: ${user.uid}');

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

  // Descargar PDF (para uso futuro)
  Future<String> downloadPDF(PDFModel pdf) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Verificar que el PDF pertenece al usuario actual
      if (pdf.userId != user.uid) {
        throw Exception('No tienes permisos para descargar este PDF');
      }

      print('📥 Descargando PDF: ${pdf.name}');
      final Reference ref = _storage.refFromURL(pdf.url);
      final String downloadURL = await ref.getDownloadURL();

      print('✅ PDF listo para descargar');
      return downloadURL;
    } catch (e) {
      print('❌ Error al descargar PDF: $e');
      throw Exception('Error al descargar PDF: $e');
    }
  }

  // Obtener información del archivo
  Future<FullMetadata> getFileMetadata(PDFModel pdf) async {
    try {
      final Reference ref = _storage.refFromURL(pdf.url);
      return await ref.getMetadata();
    } catch (e) {
      print('❌ Error obteniendo metadata: $e');
      throw Exception('Error obteniendo metadata del archivo');
    }
  }

  // Método para debug de Firestore
  Future<void> debugFirestoreData() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ Usuario no autenticado para debug');
      return;
    }

    print('🛠️ === INICIANDO DEBUG FIRESTORE ===');
    print('🛠️ User ID: ${user.uid}');

    try {
      // Consultar TODOS los documentos sin filtro
      final allSnapshot =
          await _firestore.collection(AppConstants.pdfsCollection).get();

      print(
          '🛠️ Total documentos en colección "pdfs": ${allSnapshot.docs.length}');

      if (allSnapshot.docs.isEmpty) {
        print('🛠️ ❌ La colección "pdfs" está VACÍA');
        return;
      }

      // Mostrar todos los documentos
      for (var doc in allSnapshot.docs) {
        final data = doc.data();
        print('🛠️ 📄 Documento ID: ${doc.id}');
        print('🛠️   - userId: ${data['userId']}');
        print('🛠️   - name: ${data['name']}');
        print('🛠️   - uploadDate: ${data['uploadDate']}');
        print('🛠️   - size: ${data['size']}');
        print('🛠️   - url: ${data['url']?.substring(0, 50)}...');
        print('🛠️   ---');
      }

      // Consultar documentos del usuario específico
      final userSnapshot = await _firestore
          .collection(AppConstants.pdfsCollection)
          .where('userId', isEqualTo: user.uid)
          .get();

      print('🛠️ Documentos del usuario actual: ${userSnapshot.docs.length}');

      for (var doc in userSnapshot.docs) {
        print('🛠️ ✅ Documento del usuario: ${doc.id} - ${doc.data()['name']}');
      }
    } catch (e) {
      print('🛠️ ❌ Error en debug: $e');
    }

    print('🛠️ === FIN DEBUG FIRESTORE ===');
  }

  // Sanitizar nombres de archivo
  String _sanitizeFileName(String fileName) {
    // Remover caracteres especiales y reemplazar por _
    return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  // Verificar si el usuario puede acceder al PDF
  bool canUserAccessPDF(PDFModel pdf) {
    final user = _auth.currentUser;
    return user != null && pdf.userId == user.uid;
  }

  // Obtener estadísticas del usuario
  Future<Map<String, dynamic>> getUserStats() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      final snapshot = await _firestore
          .collection(AppConstants.pdfsCollection)
          .where('userId', isEqualTo: user.uid)
          .get();

      final totalFiles = snapshot.docs.length;
      final totalSize = snapshot.docs.fold<int>(0, (sum, doc) {
        final size = doc.data()['size'] ?? 0;
        return sum + (size is int ? size : int.tryParse(size.toString()) ?? 0);
      });

      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'totalSizeFormatted': FileUtils.formatFileSize(totalSize),
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      throw Exception('Error obteniendo estadísticas del usuario');
    }
  }
}
