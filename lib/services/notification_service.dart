import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

class NotificationService {
  static Future<void> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
  }) async {
    try {
      // ⚠️ AVISO DE SEGURANÇA:
      // Usar service account em aplicações móveis não é recomendado em produção
      // pois expõe as credenciais de administrador. Use Cloud Functions ou backend server.

      print('⚠️ Carregando service account (apenas para desenvolvimento)');

      // Ler o arquivo de service account dos assets
      final serviceAccountJson = await rootBundle.loadString(
          'assets/campus-link-def-firebase-adminsdk-fbsvc-009abb77a7.json');

      final serviceAccount = json.decode(serviceAccountJson);

      final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = await clientViaServiceAccount(credentials, scopes);

      final uri = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/${serviceAccount['project_id']}/messages:send',
      );

      final message = {
        "message": {
          "token": targetToken,
          "notification": {
            "title": title,
            "body": body,
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "type": "chat_message",
          }
        }
      };

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        print('✅ Notificação enviada com sucesso');
      } else {
        print('❌ Erro ao enviar notificação: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      client.close();
    } catch (e) {
      print('❌ Erro no serviço de notificação: $e');
    }
  }

  // Método para enviar notificação de chat
  static Future<void> sendChatNotification({
    required String receiverId,
    required String senderName,
    required String message,
  }) async {
    try {
      // Buscar o token FCM do destinatário
      final userDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(receiverId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final fcmToken = userData?['fcmToken'];

        if (fcmToken != null && fcmToken.isNotEmpty) {
          await sendPushNotification(
            targetToken: fcmToken,
            title: senderName,
            body: message,
          );
        } else {
          print('⚠️ Token FCM não encontrado para o usuário $receiverId');
        }
      }
    } catch (e) {
      print('❌ Erro ao enviar notificação de chat: $e');
    }
  }
}
