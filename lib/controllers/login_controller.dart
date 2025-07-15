import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/student_model.dart';

class LoginController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Student?> login(String email, String password) async {
    try {
      final snapshot = await _firestore
          .collection('students')
          .where('userId', isEqualTo: email)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();

      if (data['password'] == password) {
          final fcmToken = await FirebaseMessaging.instance.getToken();
            if (fcmToken != null) {
              await _firestore.collection('students').doc(doc.id).update({
                'fcmToken': fcmToken,
              });
              print('✅ Token FCM atualizado: $fcmToken');
            } else {
              print('⚠️ Não foi possível obter o token FCM');
            }
        return Student.fromMap(data, doc.id);
      } else {
        return null;
      }
    } catch (e) {
      print('Erro ao fazer login: $e');
      return null;
    }
  }
}