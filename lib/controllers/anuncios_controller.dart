import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/anuncio_turma_model.dart';
import '../models/announcement.dart';
import '../session/session.dart'; // Apenas para `Session.currentStudent`

class AnunciosController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Announcement>> getAnunciosGlobais() async {
    final snapshot = await _firestore
        .collection('announcements')
        .where('recipient', isEqualTo: 'todos')
        .get();

    return snapshot.docs
        .map((doc) => Announcement.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<AnuncioTurma>> getAnunciosTurma() async {
  final aluno = Session.currentStudent;
  if (aluno == null) return [];

  // Buscar o curso do aluno
  final courseSnapshot = await _firestore
      .collection('courses')
      .where('name', isEqualTo: aluno.courseId)
      .limit(1)
      .get();

  if (courseSnapshot.docs.isEmpty) return [];

  final courseDoc = courseSnapshot.docs.first;

  // Buscar todas as disciplinas do ano do aluno
  final subjectsSnapshot = await courseDoc.reference
      .collection('subjects')
      .where('courseYear', isEqualTo: aluno.year)
      .get();

  final subjectNames = subjectsSnapshot.docs
      .map((doc) => doc['name']?.toString() ?? '')
      .where((name) => name.isNotEmpty)
      .toSet(); // Usamos Set para busca mais rápida

  if (subjectNames.isEmpty) return [];

  // Buscar todos os anúncios_turma
  final anunciosSnapshot = await _firestore
      .collection('anuncios_turma')
      .get();

  // Filtrar apenas os que pertencem às disciplinas do aluno
  return anunciosSnapshot.docs
      .where((doc) => subjectNames.contains(doc['disciplina']))
      .map((doc) => AnuncioTurma.fromMap(doc.data(), doc.id))
      .toList();
}



  Future<List<dynamic>> getTodosAnuncios() async {
    final globais = await getAnunciosGlobais();
    final turma = await getAnunciosTurma();
    return [...globais, ...turma];
  }
}
