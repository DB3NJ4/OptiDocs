import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/pdf_provider.dart';
import '../../core/utils/file_utils.dart';
import '../../core/constants/app_constants.dart';

class UploadButton extends StatelessWidget {
  const UploadButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _pickAndUploadPDF(context),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }

  Future<void> _pickAndUploadPDF(BuildContext context) async {
    final pdfProvider = Provider.of<PDFProvider>(context, listen: false);

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.allowedExtensions,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;

        if (!FileUtils.isValidPDF(file)) {
          _showErrorDialog(context,
              'Archivo no válido. Asegúrate de que sea un PDF y no exceda los 50MB.');
          return;
        }

        await pdfProvider.uploadPDF(file);

        if (pdfProvider.error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF "${file.name}" subido exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog(context, 'Error al subir PDF: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
