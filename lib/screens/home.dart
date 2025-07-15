import 'package:campus_link/screens/login.dart';
import 'package:campus_link/screens/assignment_detail_page.dart';
import 'package:campus_link/screens/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/notification_badge.dart';
import '../models/stat_data.dart';
import '../widgets/class_card.dart';
import '../session/session.dart';
import '../services/fcm_service.dart';
import '../models/student_model.dart';
import '../utils/string_utils.dart';
import '../widgets/assignment_card.dart';
import '../controllers/tarefas_controller.dart';
import '../models/assignment_data.dart';

import '../models/horario_model.dart';
import '../controllers/horario_controller.dart'; // onde estiver a função buscarAulasDeHoje

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  late Student student;

  @override
  void initState() {
    super.initState();
    student = Session.currentStudent!;
  }

  String calcularDuracao(String inicio, String fim) {
    try {
      final format = RegExp(r'(\d+):(\d+)');
      final matchInicio = format.firstMatch(inicio);
      final matchFim = format.firstMatch(fim);

      if (matchInicio == null || matchFim == null) return '';

      final inicioHora = int.parse(matchInicio.group(1)!);
      final inicioMin = int.parse(matchInicio.group(2)!);
      final fimHora = int.parse(matchFim.group(1)!);
      final fimMin = int.parse(matchFim.group(2)!);

      final duracaoMin =
          (fimHora * 60 + fimMin) - (inicioHora * 60 + inicioMin);
      final horas = duracaoMin ~/ 60;
      final minutos = duracaoMin % 60;

      return '${horas > 0 ? '${horas}h ' : ''}${minutos}m';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeSwitcher = Provider.of<ThemeSwitcher>(context);
    final isDarkMode = themeSwitcher.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[200],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 4.0),
            child: NotificationBadge(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                );
              },
              child: Icon(
                Icons.notifications,
                color: isDarkMode ? Colors.white : Colors.black,
                size: 30,
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, isDarkMode),
      body: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Image.asset(
                'assets/logo.webp',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.3,
                  children: StatData.generateStatCards(),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: isDarkMode ? Colors.black : Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Trabalhos",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: FutureBuilder<List<AssignmentData>>(
                      future: buscarTrabalhosDoAluno(student),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return const Center(
                              child: Text("Erro ao carregar trabalhos HOME"));
                        }

                        final assignments = snapshot.data ?? [];

                        final half = (assignments.length / 2).ceil();
                        final firstHalf = assignments.take(half);
                        final secondHalf = assignments.skip(half);

                        List<Widget> buildRow(List<AssignmentData> data) {
                          return data.map((assignment) {
                            return SizedBox(
                              width: MediaQuery.of(context).size.width / 2 - 24,
                              child: AssignmentCard(
                                subject: assignment.subject,
                                date: assignment.dueDate,
                                subjectType: assignment.type,
                                isUrgent: !assignment.completed,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AssignmentDetailPage(assignment: {
                                        "subject": assignment.subject,
                                        "type": assignment.type,
                                        "dueDate": assignment.dueDate,
                                        "daysRemaining":
                                            assignment.daysRemaining,
                                        "completed": assignment.completed,
                                        "createdDate": assignment.createdDate,
                                        "assignmentType":
                                            assignment.assignmentType,
                                        "descricao": assignment.descricao,
                                        "id": assignment.id,
                                        "ficheiros": assignment.ficheiros,
                                      }),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList();
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 6.0,
                                children: buildRow(firstHalf.toList()),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 6.0,
                                children: buildRow(secondHalf.toList()),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Aulas de Hoje",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FutureBuilder<List<Aula>>(
                      future: buscarAulasDeHoje(student),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return const Center(
                              child: Text("Erro ao carregar aulas de hoje"));
                        }

                        final aulas = snapshot.data ?? [];

                        if (aulas.isEmpty) {
                          return const Center(child: Text("Não há aulas hoje"));
                        }

                        return ListView.builder(
                          itemCount: aulas.length,
                          itemBuilder: (context, index) {
                            final aula = aulas[index];
                            final horaInicio = aula.horaInicio;
                            final horaFim = aula.horaFim;

                            // Calcular duração
                            final duracao =
                                calcularDuracao(horaInicio, horaFim);

                            return Column(
                              children: [
                                ClassCard(
                                  className: aula.disciplina,
                                  time: "$horaInicio - $horaFim",
                                  duration: duracao,
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, bool isDarkMode) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
            ),
            accountName: Text(
              student.nome,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            accountEmail: Text(
              student.userId,
              style: TextStyle(
                  color:
                      isDarkMode ? Colors.grey[300] : const Color(0xFF525151)),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(student.nome.initials),
            ),
          ),
          ..._buildDrawerItems(isDarkMode),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems(bool isDarkMode) {
    final List<Map<String, dynamic>> pages = [
      {'title': "Disciplinas", 'route': '/course_page'},
      {'title': "Horário", 'route': '/schedule'},
      {'title': "Presenças", 'route': '/presences'},
      {'title': "Trabalhos", 'route': '/assigments_page'},
      {'title': "Testes", 'route': '/exames_testes'},
      {'title': "Notas", 'route': '/grades_page'},
      {'title': "Conversas", 'route': '/message'},
      {'title': "Anúncios", 'route': '/announcement_page'},
      {'title': "Perfil", 'route': '/profile_page'},
    ];

    return [
      for (var item in pages)
        ListTile(
          title: Text(item['title'],
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          trailing: Icon(Icons.arrow_forward,
              color: isDarkMode ? Colors.white : Colors.black),
          onTap: () {
            Navigator.of(context).pushReplacementNamed(item['route']);
          },
        ),
      ListTile(
        title: const Text("Terminar Sessão"),
        trailing: const Icon(Icons.arrow_back),
        onTap: () async {
          // Limpa o token FCM do Firestore
          await FCMService.clearFCMToken();

          await Session.clearSession(); // limpa a sessão e notificações

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => Login()),
            (route) => false, // remove todas as rotas anteriores
          );
        },
      ),
      const Divider(),
      ListTile(
        title: Text("Alternar Tema",
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        trailing: Icon(Icons.brightness_6,
            color: isDarkMode ? Colors.white : Colors.black),
        onTap: () {
          Provider.of<ThemeSwitcher>(context, listen: false)
              .toggleTheme(!isDarkMode);
        },
      ),
    ];
  }
}
