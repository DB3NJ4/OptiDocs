import 'package:flutter/material.dart';
import '../../data/models/pdf_model.dart';
import '../../core/utils/file_utils.dart';

class PDFCard extends StatelessWidget {
  final PDFModel pdf;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PDFCard({
    super.key,
    required this.pdf,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
        title: Text(
          pdf.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tamaño: ${FileUtils.formatFileSize(pdf.size)}'),
            Text('Subido: ${_formatDate(pdf.uploadDate)}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
