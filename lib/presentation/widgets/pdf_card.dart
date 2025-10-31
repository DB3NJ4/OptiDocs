import 'package:flutter/material.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../data/models/pdf_model.dart';
import '../../core/theme/colors.dart';

class PDFCard extends StatelessWidget {
  final PDFModel pdf;
  final VoidCallback onDelete;

  const PDFCard({
    super.key,
    required this.pdf,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
        title: Text(
          pdf.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tamaño: ${_formatFileSize(pdf.size)}'),
            Text('Subido: ${_formatDate(pdf.uploadDate)}'),
            const SizedBox(height: 4),
            _buildUrlStatus(),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.primary),
              onPressed: () => _openPDFWithOptions(context),
              tooltip: 'Opciones del PDF',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: onDelete,
              tooltip: 'Eliminar PDF',
            ),
          ],
        ),
        onTap: () => _openPDFWithOptions(context),
      ),
    );
  }

  Widget _buildUrlStatus() {
    return const Row(
      children: [
        Icon(Icons.check_circle, size: 12, color: Colors.green),
        SizedBox(width: 4),
        Text(
          'Listo para descargar ✓',
          style: TextStyle(fontSize: 10, color: Colors.green),
        ),
      ],
    );
  }

  void _openPDFWithOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf,
                      size: 24, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pdf.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatFileSize(pdf.size),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Opción 1: DESCARGAR PDF
            ListTile(
              leading: const Icon(Icons.download, color: AppColors.primary),
              title: const Text('Descargar PDF'),
              subtitle: const Text('Guardar en la carpeta de Descargas'),
              onTap: () {
                Navigator.pop(context);
                _downloadPDF(context);
              },
            ),

            // Opción 2: Abrir en navegador externo
            ListTile(
              leading: const Icon(Icons.public, color: AppColors.primary),
              title: const Text('Abrir en Navegador'),
              subtitle: const Text('Ver online en tu navegador'),
              onTap: () {
                Navigator.pop(context);
                _openInExternalBrowser(context);
              },
            ),

            // Opción 3: Ver URL
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.primary),
              title: const Text('Compartir URL'),
              subtitle: const Text('Copiar enlace del PDF'),
              onTap: () {
                Navigator.pop(context);
                _showUrlDialog(context);
              },
            ),

            // Cancelar
            ListTile(
              leading: const Icon(Icons.cancel, color: AppColors.error),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MÉTODO MEJORADO PARA SOLICITAR TODOS LOS PERMISOS NECESARIOS
  Future<void> _downloadPDF(BuildContext context) async {
    try {
      print('📥 Iniciando descarga: ${pdf.name}');

      // Mostrar indicador de progreso
      final scaffold = ScaffoldMessenger.of(context);
      final snackBarController = scaffold.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Solicitando permisos y descargando "${pdf.name}"...',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 30),
        ),
      );

      // ✅ SOLICITAR PERMISOS ESPECÍFICOS PARA ANDROID
      if (Platform.isAndroid) {
        bool hasPermissions = await _requestAllStoragePermissions();
        if (!hasPermissions) {
          snackBarController.close();
          _showPermissionError(context);
          return;
        }
      }

      // Obtener directorio
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        throw Exception('No se pudo acceder al almacenamiento');
      }

      // Crear archivo
      final safeFileName = _sanitizeFileName(pdf.name);
      final file = File('${directory.path}/$safeFileName');

      // Verificar si el archivo ya existe
      if (await file.exists()) {
        snackBarController.close();
        _showFileExistsDialog(context, file, safeFileName);
        return;
      }

      // Descargar el PDF
      print('💾 Descargando a: ${file.path}');

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(pdf.url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Error HTTP ${response.statusCode}');
      }

      // Guardar archivo
      final bytes = await response.fold<List<int>>(
        <int>[],
        (previous, element) => previous..addAll(element),
      );

      await file.writeAsBytes(bytes);
      httpClient.close();

      // Mostrar éxito
      snackBarController.close();
      _showDownloadSuccess(context, file.path, safeFileName);

      print('✅ PDF descargado exitosamente: ${file.path}');
    } catch (e) {
      print('❌ Error descargando PDF: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorDialog(context, 'Error al descargar: $e');
    }
  }

  // ✅ MÉTODO QUE SOLICITA TODOS LOS PERMISOS DE ALMACENAMIENTO
  Future<bool> _requestAllStoragePermissions() async {
    try {
      print('🔐 Solicitando todos los permisos de almacenamiento...');

      // Para Android 13+ (API 33+)
      if (await Permission.storage.isGranted) {
        print('✅ Permisos de almacenamiento ya concedidos');
        return true;
      }

      // Solicitar permisos de almacenamiento
      PermissionStatus storageStatus = await Permission.storage.request();
      print('📦 Resultado permisos storage: $storageStatus');

      // Para Android 11+, solicitar manage external storage
      PermissionStatus manageStorageStatus =
          await Permission.manageExternalStorage.request();
      print('💾 Resultado permisos manage external: $manageStorageStatus');

      // Verificar si al menos storage está concedido
      if (storageStatus.isGranted) {
        print('✅ Permisos de almacenamiento concedidos');
        return true;
      }

      if (storageStatus.isPermanentlyDenied ||
          manageStorageStatus.isPermanentlyDenied) {
        print('🚫 Permisos denegados permanentemente');
        return false;
      }

      return storageStatus.isGranted;
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      return false;
    }
  }

  // ✅ MÉTODO PARA OBTENER DIRECTORIO DE DESCARGA
  Future<Directory?> _getDownloadDirectory() async {
    try {
      // Intentar obtener el directorio de Downloads
      Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        print('📁 Directorio de descargas: ${downloadsDir.path}');
        final appDir = Directory('${downloadsDir.path}/OptiDocs');
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        return appDir;
      }

      // Fallback: directorio de documentos de la app
      Directory documentsDir = await getApplicationDocumentsDirectory();
      print('📁 Directorio de documentos: ${documentsDir.path}');
      final appDir = Directory('${documentsDir.path}/OptiDocs');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      return appDir;
    } catch (e) {
      print('❌ Error obteniendo directorio: $e');
      return null;
    }
  }

  // ✅ DIÁLOGO PARA ARCHIVO EXISTENTE
  void _showFileExistsDialog(BuildContext context, File file, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivo Existente'),
        content: Text('"$fileName" ya existe. ¿Quieres reemplazarlo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _forceDownload(context, file);
            },
            child: const Text('Reemplazar'),
          ),
        ],
      ),
    );
  }

  // ✅ DESCARGA FORZADA
  Future<void> _forceDownload(BuildContext context, File file) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reemplazando "${pdf.name}"...'),
          backgroundColor: AppColors.primary,
        ),
      );

      if (await file.exists()) {
        await file.delete();
      }

      await Future.delayed(const Duration(milliseconds: 500));
      _downloadPDF(context);
    } catch (e) {
      _showErrorDialog(context, 'Error al reemplazar archivo: $e');
    }
  }

  // ✅ MOSTRAR ÉXITO DE DESCARGA
  void _showDownloadSuccess(
      BuildContext context, String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Descarga Exitosa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"$fileName" se ha descargado correctamente.'),
            const SizedBox(height: 8),
            Text(
              'Ubicación:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            Text(
              filePath,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openFileLocation(filePath);
            },
            child: const Text('Abrir ubicación'),
          ),
        ],
      ),
    );
  }

  // ✅ ABRIR UBICACIÓN DEL ARCHIVO
  void _openFileLocation(String filePath) async {
    try {
      final directory = Directory(filePath).parent;
      if (await directory.exists()) {
        final uri = 'file://${directory.path}';
        if (await canLaunchUrl(Uri.parse(uri))) {
          await launchUrl(Uri.parse(uri));
        } else {
          print('❌ No se puede abrir la ubicación del archivo');
        }
      }
    } catch (e) {
      print('❌ No se pudo abrir la ubicación: $e');
    }
  }

  // ✅ MOSTRAR ERROR DE PERMISOS
  void _showPermissionError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos de Almacenamiento Requeridos'),
        content: const Text(
          'Para descargar PDFs, OptiDocs necesita acceso a archivos y documentos.\n\n'
          'Por favor, permite el acceso al almacenamiento cuando se solicite. '
          'Si los permisos fueron denegados, puedes habilitarlos manualmente en la configuración de la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  // ✅ SANITIZAR NOMBRE DE ARCHIVO
  String _sanitizeFileName(String name) {
    var sanitized = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    if (!sanitized.toLowerCase().endsWith('.pdf')) {
      sanitized += '.pdf';
    }
    return sanitized;
  }

  // ✅ ABRIR EN NAVEGADOR EXTERNO
  Future<void> _openInExternalBrowser(BuildContext context) async {
    try {
      print('🌐 Abriendo en navegador externo: ${pdf.name}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Abriendo "${pdf.name}" en el navegador...'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );

      final uri = Uri.parse(pdf.url);
      final success =
          await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!success) {
        throw Exception('No se pudo abrir el navegador');
      }

      print('✅ PDF abierto en navegador externo');
    } catch (e) {
      print('❌ Error abriendo en navegador: $e');
      _showErrorDialog(context, 'No se pudo abrir el navegador: $e');
    }
  }

  // ✅ MOSTRAR URL
  void _showUrlDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL del PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Puedes copiar esta URL:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                pdf.url,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $error'),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
