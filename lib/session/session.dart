import '../models/student_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static Student? currentStudent;
  static final Set<String> readNotifications = <String>{};
  static const String _readNotificationsKey = 'read_notifications';

  // Inicializar sessão - carregar notificações lidas
  static Future<void> initializeSession() async {
    print('🔍 Inicializando sessão...');
    await _loadReadNotifications();
  }

  // Carregar notificações lidas do SharedPreferences
  static Future<void> _loadReadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotificationsList =
          prefs.getStringList(_readNotificationsKey) ?? [];
      readNotifications.clear();
      readNotifications.addAll(readNotificationsList);
      print(
          '📱 Carregadas ${readNotifications.length} notificações lidas do storage local');
    } catch (e) {
      print('❌ Erro ao carregar notificações lidas: $e');
    }
  }

  // Salvar notificações lidas no SharedPreferences
  static Future<void> _saveReadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _readNotificationsKey, readNotifications.toList());
      print(
          '💾 Salvas ${readNotifications.length} notificações lidas no storage local');
    } catch (e) {
      print('❌ Erro ao salvar notificações lidas: $e');
    }
  }

  // Método para limpar a sessão (quando o usuário faz logout)
  static Future<void> clearSession() async {
    currentStudent = null;
    readNotifications.clear();

    // Limpar do SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_readNotificationsKey);
      print('🗑️ Sessão e notificações lidas limpas do storage local');
    } catch (e) {
      print('❌ Erro ao limpar sessão do storage local: $e');
    }
  }

  // Métodos para gerenciar notificações lidas
  static Future<void> markNotificationAsRead(String notificationId) async {
    print('🔵 markNotificationAsRead chamado para: $notificationId');

    readNotifications.add(notificationId);
    await _saveReadNotifications();
    print('✅ Notificação marcada como lida: $notificationId');
    print('📋 Total de notificações lidas agora: ${readNotifications.length}');
  }

  static bool isNotificationRead(String notificationId) {
    final isRead = readNotifications.contains(notificationId);
    print('🔍 Verificando se notificação $notificationId está lida: $isRead');
    return isRead;
  }

  static Future<void> markAllNotificationsAsRead(
      List<String> notificationIds) async {
    readNotifications.addAll(notificationIds);
    await _saveReadNotifications();
    print('✅ ${notificationIds.length} notificações marcadas como lidas');
  }
}
