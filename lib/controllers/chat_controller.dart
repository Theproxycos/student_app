import 'package:campus_link/models/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session/session.dart';

class SelectableUser {
  final String id;
  final String name;
  final String type; // 'student' ou 'professor'

  SelectableUser({required this.id, required this.name, required this.type});
}

Future<int> contarConversasDoUsuario() async {
  final firestore = FirebaseFirestore.instance;
  final userId = Session.currentStudent!.id; // ou currentStudent!.userId

  final snapshot = await firestore
      .collection('chats')
      .where('participants', arrayContains: userId)
      .get();

  return snapshot.docs.length;
}


Future<List<Map<String, dynamic>>> getAllProfessoresEAlunos() async {
  print("ENTREI NO GET ALL PROFESSORES E ALUNOS");
  try {
    final firestore = FirebaseFirestore.instance;
    final currentUserId = Session.currentStudent!.id;
    
    print("ID DO UTILIZADOR ATUAL: $currentUserId");
    // Buscar todos os alunos
    final alunosSnap = await firestore.collection('students').get();
    final alunos = alunosSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['nome'] ?? 'Aluno',
        'type': 'Estudante',
      };
    }).toList();

    // Buscar todos os professores
    final professoresSnap = await firestore.collection('professores').get();
    final professores = professoresSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['nome'] ?? 'Professor',
        'type': 'Professor',
      };
    }).toList();

    // Buscar todos os chats onde o utilizador atual participa
    final chatsSnap = await firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    // Extrair todos os IDs dos outros participantes
    final Set<String> idsComConversa = {};
    for (final doc in chatsSnap.docs) {
      final List<dynamic> participants = doc['participants'];
      for (final id in participants) {
        if (id != currentUserId) {
          idsComConversa.add(id); // aqui já está com #
        }
      }
    }

    print("IDs com quem já tenho conversa: $idsComConversa");

    // Filtrar a lista de usuários
    final todosUsuarios = [...alunos, ...professores].where((user) {
      return user['id'] != currentUserId && user['id'] != currentUserId;
    }).toList();
    final filtrados = todosUsuarios.where((user) {
      print("Verificando usuário: ${user['id']} - ${user['name']}");
      
      return !idsComConversa.contains(user['id']);
    }).toList();
  print("Filtrados: $filtrados");
  
    return filtrados;
  } catch (e) {
    print('ERRO AO CARREGAR USUÁRIOS: $e');
    return [];
  }
}




 Future<Chat> createOrGetChat(String userId1, String userId2) async {
  final chatsRef = FirebaseFirestore.instance.collection('chats');

  // Verifica se já existe
  final query = await chatsRef
      .where('participants', arrayContains: userId1)
      .get();

  for (var doc in query.docs) {
    final participants = List<String>.from(doc['participants']);
    if (participants.contains(userId2)) {
      return Chat.fromDocument(doc, userId1);
    }
  }

  // Obtém nomes
  Future<String?> getNome(String id) async {
    final student = await FirebaseFirestore.instance.collection('students').doc(id).get();
    if (student.exists) return student.data()?['nome'];

    final prof = await FirebaseFirestore.instance.collection('professores').doc(id).get();
    if (prof.exists) return prof.data()?['nome'];

    return null;
  }

  final name1 = await getNome(userId1) ?? 'Utilizador';
  final name2 = await getNome(userId2) ?? 'Utilizador';

  // Cria novo chat com campo `users`
  final newDoc = await chatsRef.add({
    'participants': [userId1, userId2],
    'timestamp': Timestamp.now(),
    'users': {
      userId1: {'name': name1},
      userId2: {'name': name2},
    }
  });

  final newSnapshot = await newDoc.get();
  return Chat.fromDocument(newSnapshot, userId1);
}


