import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session/session.dart';

class FCMService {
  static FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Inicializar FCM
  static Future<void> initialize() async {
    try {
      // Solicitar permissões de notificação
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permissão de notificação concedida');

        // Obter e salvar o token FCM
        await updateFCMToken();

        // Configurar handlers
        setupMessageHandlers();
      } else {
        print('❌ Permissão de notificação negada');
      }
    } catch (e) {
      print('❌ Erro ao inicializar FCM: $e');
    }
  }

  // Atualizar token FCM do usuário
  static Future<void> updateFCMToken() async {
    try {
      final token = await messaging.getToken();
      final currentStudent = Session.currentStudent;

      if (token != null && currentStudent != null) {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(currentStudent.id)
            .update({'fcmToken': token});

        print('✅ Token FCM atualizado: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      print('❌ Erro ao atualizar token FCM: $e');
    }
  }

  // Configurar handlers de mensagens
  static void setupMessageHandlers() {
    // Mensagem recebida quando app está em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Mensagem recebida em primeiro plano:');
      print('Título: ${message.notification?.title}');
      print('Corpo: ${message.notification?.body}');
    });

    // Mensagem tocada quando app está em background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App aberto via notificação:');
      print('Dados: ${message.data}');

      _handleNotificationTap(message);
    });

    // Verificar se app foi aberto via notificação
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('📱 App iniciado via notificação');
        _handleNotificationTap(message);
      }
    });

    // Listener para mudanças no token
    messaging.onTokenRefresh.listen((newToken) {
      print('🔄 Token FCM atualizado: ${newToken.substring(0, 20)}...');
      _updateTokenInFirestore(newToken);
    });
  }

  // Tratar toque na notificação
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

    if (data['type'] == 'chat_message') {
      // Navegar para o chat específico
      print('💬 Navegar para chat');
    }
  }

  // Atualizar token no Firestore
  static Future<void> _updateTokenInFirestore(String token) async {
    try {
      final currentStudent = Session.currentStudent;

      if (currentStudent != null) {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(currentStudent.id)
            .update({'fcmToken': token});
      }
    } catch (e) {
      print('❌ Erro ao atualizar token no Firestore: $e');
    }
  }

  // Remover token ao fazer logout
  static Future<void> clearFCMToken() async {
    try {
      final currentStudent = Session.currentStudent;

      if (currentStudent != null) {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(currentStudent.id)
            .update({'fcmToken': FieldValue.delete()});

        print('✅ Token FCM removido');
      }
    } catch (e) {
      print('❌ Erro ao remover token FCM: $e');
    }
  }
}
