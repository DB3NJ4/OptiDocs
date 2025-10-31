import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import '../providers/pdf_provider.dart';
import '../widgets/pdf_card.dart';
import '../widgets/upload_button.dart';
import '../widgets/loading_indicator.dart';
import '../../data/models/pdf_model.dart'; // ← Agregar esta importación

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OptiDocs 📄'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<PDFProvider>(
        builder: (context, pdfProvider, child) {
          if (pdfProvider.isLoading && pdfProvider.pdfs.isEmpty) {
            return const LoadingIndicator();
          }

          if (pdfProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${pdfProvider.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => pdfProvider.clearError(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (pdfProvider.pdfs.isEmpty) {
            return const EmptyState();
          }

          return PDFList(pdfProvider: pdfProvider);
        },
      ),
      floatingActionButton: const UploadButton(),
    );
  }
}

class PDFList extends StatelessWidget {
  final PDFProvider pdfProvider;

  const PDFList({super.key, required this.pdfProvider});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pdfProvider.pdfs.length,
      itemBuilder: (context, index) {
        final pdf = pdfProvider.pdfs[index];
        return PDFCard(
          pdf: pdf,
          onTap: () => OpenFile.open(pdf.url),
          onDelete: () => _showDeleteDialog(context, pdfProvider, pdf),
        );
      },
    );
  }

  void _showDeleteDialog(
      BuildContext context, PDFProvider pdfProvider, PDFModel pdf) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar PDF'),
        content: Text('¿Estás seguro de eliminar "${pdf.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              pdfProvider.deletePDF(pdf);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No hay PDFs aún',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Presiona el botón + para subir tu primer PDF',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
