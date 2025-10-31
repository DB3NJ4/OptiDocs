import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/pdf_provider.dart';
import '../widgets/pdf_card.dart';
import '../widgets/loading_indicator.dart';
import '../../data/models/pdf_model.dart';
import '../../core/theme/colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserMenu(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Información del usuario
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  user?.displayName?.isNotEmpty == true
                      ? user!.displayName![0].toUpperCase()
                      : user?.email?[0].toUpperCase() ?? 'U',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                user?.displayName?.isNotEmpty == true
                    ? user!.displayName!
                    : (user?.isAnonymous == true
                        ? 'Usuario Invitado'
                        : 'Usuario'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(user?.email ?? 'Usuario anónimo'),
            ),

            const Divider(),

            // Opción de cerrar sesión
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
            ),

            // Opción de cancelar
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut(context);
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshData(BuildContext context) {
    final pdfProvider = Provider.of<PDFProvider>(context, listen: false);
    pdfProvider.loadPDFs();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lista actualizada'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _uploadFile(BuildContext context) async {
    final pdfProvider = Provider.of<PDFProvider>(context, listen: false);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
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
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OptiDocs 📄'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          // Botón de refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(context),
            tooltip: 'Actualizar lista',
          ),
          // Botón de menú de usuario
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => _showUserMenu(context),
            tooltip: 'Menú de usuario',
          ),
        ],
      ),
      body: Consumer<PDFProvider>(
        builder: (context, pdfProvider, child) {
          // Mostrar loading solo si no hay PDFs
          if (pdfProvider.isLoading && pdfProvider.pdfs.isEmpty) {
            return const LoadingIndicator();
          }

          // Mostrar error
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
                    onPressed: () => _refreshData(context),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // Mostrar estado vacío
          if (pdfProvider.pdfs.isEmpty) {
            return EmptyState(
              onRefresh: () => _refreshData(context),
              isLoading: pdfProvider.isLoading,
            );
          }

          // Mostrar lista de PDFs
          return PDFList(
            pdfProvider: pdfProvider,
            onRefresh: () => _refreshData(context),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _uploadFile(context),
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
      ),
    );
  }
}

class PDFList extends StatelessWidget {
  final PDFProvider pdfProvider;
  final VoidCallback onRefresh;

  const PDFList({
    super.key,
    required this.pdfProvider,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      backgroundColor: AppColors.primary,
      color: AppColors.onPrimary,
      child: Column(
        children: [
          // Header con información
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tus PDFs (${pdfProvider.pdfs.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Toca un PDF para abrirlo en el navegador',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Lista de PDFs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pdfProvider.pdfs.length,
              itemBuilder: (context, index) {
                final pdf = pdfProvider.pdfs[index];
                return PDFCard(
                  pdf: pdf,
                  onDelete: () => _showDeleteDialog(context, pdfProvider, pdf),
                );
              },
            ),
          ),
        ],
      ),
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
  final VoidCallback onRefresh;
  final bool isLoading;

  const EmptyState({
    super.key,
    required this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      backgroundColor: AppColors.primary,
      color: AppColors.onPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  '¡Hola${user?.displayName?.isNotEmpty == true ? ', ${user!.displayName}!' : '!'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Actualizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando PDFs...'),
        ],
      ),
    );
  }
}
