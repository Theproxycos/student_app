import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/notification_controller.dart';
import '../controllers/tarefas_controller.dart';
import '../models/notification_model.dart';
import '../widgets/theme_switcher.dart';
import '../screens/assignment_detail_page.dart';
import '../session/session.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationController _controller = NotificationController();
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _controller.getAllNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar notificações: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeSwitcher = Provider.of<ThemeSwitcher>(context);
    final isDarkMode = themeSwitcher.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[200],
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? _buildEmptyState(isDarkMode)
                : _buildNotificationsList(isDarkMode),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Não há notificações',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quando houver novidades, elas aparecerão aqui',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification, isDarkMode);
      },
    );
  }

  Widget _buildNotificationCard(
      NotificationModel notification, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleNotificationTap(notification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification.type, isDarkMode),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type, bool isDarkMode) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'tarefa':
        iconData = Icons.assignment;
        iconColor = Colors.orange;
        break;
      case 'teste':
        iconData = Icons.quiz;
        iconColor = Colors.red;
        break;
      case 'exame':
        iconData = Icons.school;
        iconColor = Colors.red;
        break;
      case 'material':
        iconData = Icons.folder;
        iconColor = Colors.purple;
        break;
      case 'anuncio':
        iconData = Icons.campaign;
        iconColor = Colors.blue;
        break;
      case 'chat':
        iconData = Icons.message;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        size: 24,
        color: iconColor,
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) async {
    print('🔵 Clicou na notificação: ${notification.id}');

    // Navegar baseado no tipo
    switch (notification.type) {
      case 'tarefa':
        _navigateToAssignment(notification);
        break;
      case 'teste':
      case 'exame':
        _navigateToTest(notification);
        break;
      case 'material':
        _navigateToMaterial(notification);
        break;
      case 'anuncio':
        _navigateToAnnouncement(notification);
        break;
      case 'chat':
        _navigateToChat(notification);
        break;
    }
  }

  void _navigateToAssignment(NotificationModel notification) async {
    print('🔍 _navigateToAssignment chamado');

    try {
      // Extrair o ID da tarefa da notificação
      final assignmentId = notification.data?['assignmentId'];
      if (assignmentId == null) {
        throw Exception('ID da tarefa não encontrado na notificação');
      }

      print('🔍 Buscando dados da tarefa: $assignmentId');

      // Buscar todas as tarefas do aluno logado
      final student = Session.currentStudent!;
      final allAssignments = await buscarTrabalhosDoAluno(student);

      // Encontrar a tarefa específica pelo ID
      final assignment = allAssignments.firstWhere(
        (task) => task.id == assignmentId,
        orElse: () => throw Exception('Tarefa não encontrada'),
      );

      // Converter AssignmentData para Map que a página espera
      final assignmentData = {
        'id': assignment.id,
        'subject': assignment.subject,
        'type': assignment.type,
        'dueDate': assignment.dueDate,
        'daysRemaining': assignment.daysRemaining,
        'completed': assignment.completed,
        'createdDate': assignment.createdDate,
        'assignmentType': assignment.assignmentType,
        'descricao': assignment.descricao,
        'ficheiros': assignment.ficheiros,
      };

      print('✅ Navegando para AssignmentDetailPage com dados: $assignmentData');

      // Navegar para a página de detalhes da tarefa
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AssignmentDetailPage(
            assignment: assignmentData,
          ),
        ),
      );
    } catch (e) {
      print('❌ Erro ao navegar para detalhes da tarefa: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir detalhes da tarefa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToTest(NotificationModel notification) {
    // Navegar para página de testes/exames
    Navigator.of(context).pushNamed('/exames_testes');
  }

  void _navigateToAnnouncement(NotificationModel notification) {
    // Navegar para página de anúncios
    Navigator.of(context).pushNamed('/announcement_page');
  }

  void _navigateToChat(NotificationModel notification) {
    // Navegar para página de mensagens
    Navigator.of(context).pushNamed('/message');
  }

  void _navigateToMaterial(NotificationModel notification) {
    // Navegar para página de materiais/disciplina
    if (notification.data != null && notification.data!['materialId'] != null) {
      // Se temos o ID do material, navegar diretamente para course_detail_page
      Navigator.of(context).pushNamed('/course_detail_page');
    } else {
      // Senão, navegar para a página geral de disciplinas
      Navigator.of(context).pushNamed('/course_page');
    }
  }
}
