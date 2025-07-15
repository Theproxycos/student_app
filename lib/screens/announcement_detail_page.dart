import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../models/announcement.dart';
import '../models/anuncio_turma_model.dart';
import '../widgets/mobile_sidebar.dart';

class AnnouncementDetailPage extends StatelessWidget {
  final dynamic anuncio; // Pode ser Announcement ou AnuncioTurma

  const AnnouncementDetailPage({
    super.key,
    required this.anuncio,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGlobal = anuncio is Announcement;

    final String titulo = isGlobal ? anuncio.title : anuncio.titulo;
    final String descricao = isGlobal ? anuncio.message : anuncio.descricao;
    final List<Map<String, dynamic>> ficheiros =
        isGlobal ? anuncio.files : [anuncio.ficheiro];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do Anúncio'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              descricao,
              style: const TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 32),
            if (ficheiros.isNotEmpty) ...[
              const Text(
                "Ficheiros:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...ficheiros.map((file) {
                final String nome = file['name'] ?? file['nome'] ?? 'Sem nome';
                final String base64 =
                    file['bytesBase64'] ?? file['base64'] ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📎 $nome', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      ElevatedButton.icon(
                        onPressed: base64.isNotEmpty
                            ? () => _downloadFile(base64, nome, context)
                            : null,
                        icon: const Icon(Icons.download),
                        label: const Text("Download"),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
      floatingActionButton: const MobileSidebar(),
    );
  }

  Future<void> _downloadFile(
    String base64Content,
    String fileName,
    BuildContext context,
  ) async {
    try {
      final bytes = base64Decode(base64Content);

      // Pega pasta de Downloads ou Documents
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';

      final file = io.File(filePath);
      await file.writeAsBytes(bytes);

      // Abre o arquivo com o app padrão
      final result = await OpenFile.open(filePath);

      if (result.type == ResultType.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir o arquivo: ${result.message}')),
        );
      }
    } catch (e) {
      debugPrint("Erro ao salvar/abrir o arquivo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer download: $e')),
      );
    }
  }
}
