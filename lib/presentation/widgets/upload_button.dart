import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/pdf_provider.dart';
import '../../core/theme/colors.dart';

class UploadButton extends StatelessWidget {
  const UploadButton({super.key});

  void _pickAndUploadFile(BuildContext context) async {
    final pdfProvider = Provider.of<PDFProvider>(context, listen: false);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // ✅ IMPORTANTE para web
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;

        if (file.bytes != null) {
          await pdfProvider.uploadPDF(file);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ "${file.name}" subido exitosamente'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception('No se pudieron leer los datos del archivo');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir archivo: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _pickAndUploadFile(context), // ✅ Nombre corregido
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.add,
        size: 28,
      ),
    );
  }
}
