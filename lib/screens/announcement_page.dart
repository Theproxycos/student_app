import 'package:campus_link/screens/home.dart';
import 'package:flutter/material.dart';
import '../controllers/anuncios_controller.dart';
import '../controllers/announcements_read_controller.dart';
import '../models/announcement.dart';
import '../session/session.dart';
import 'announcement_detail_page.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final AnunciosController _controller = AnunciosController();
  final AnnouncementReadController _readController = AnnouncementReadController();
  late Future<Map<String, dynamic>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _announcementsFuture = _loadAnunciosComLeitura();
  }

  Future<Map<String, dynamic>> _loadAnunciosComLeitura() async {
    final student = Session.currentStudent;
    if (student == null) return {'anuncios': [], 'lidos': <String>{}};

    final anuncios = await _controller.getTodosAnuncios();
    final lidos = await _readController.getReadAnnouncementIds(student.id);

    return {
      'anuncios': anuncios,
      'lidos': lidos,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anúncios'),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back),
         onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _announcementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar anúncios.'));
          }

          final data = snapshot.data!;
          final List<dynamic> announcements = data['anuncios'];
          final Set<String> lidos = data['lidos'];

          if (announcements.isEmpty) {
            return const Center(child: Text('Nenhum anúncio disponível.'));
          }

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final ann = announcements[index];
              final bool isGlobal = ann is Announcement;
              final bool isUnread = !lidos.contains(ann.id);

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isUnread)
                            const Icon(Icons.circle, color: Colors.green, size: 12),
                          if (isUnread) const SizedBox(width: 6),
                          Chip(
                            label: Text(
                              isGlobal ? 'Geral' : 'Turma',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: isGlobal ? Colors.blue : Colors.orange,
                            labelStyle: const TextStyle(color: Colors.white),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isGlobal ? ann.title : ann.titulo,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isGlobal ? ann.message : ann.descricao),
                      const SizedBox(height: 4),
                      ...List<Map<String, dynamic>>.from(
                        isGlobal ? ann.files : [ann.ficheiro],
                      ).map((file) => Text(
                        '📄 ${file['name'] ?? file['nome'] ?? 'Sem nome'}',
                      )),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final student = Session.currentStudent;
                    if (student != null) {
                      await _readController.markAnnouncementAsRead(student.id, ann.id);
                    }

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnouncementDetailPage(anuncio: ann),
                      ),
                    );

                    // Recarrega para atualizar a bolinha verde
                    setState(() {
                      _announcementsFuture = _loadAnunciosComLeitura();
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
