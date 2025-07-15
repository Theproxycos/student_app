import 'package:campus_link/models/subject_model.dart';
import 'package:campus_link/session/session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<int> contarDisciplinasDoAluno(String nomeCurso, int anoAluno) async {
  final firestore = FirebaseFirestore.instance;
  print('Contando disciplinas do curso: $nomeCurso, ano: $anoAluno');

  // Passo 1: Buscar o curso que tenha o mesmo nome (ignorando diferenças de maiúsculas/minúsculas)
  final cursosSnap = await firestore.collection('courses').get();
  final cursoDoc = cursosSnap.docs.firstWhere(
    (doc) => (doc.data()['name'] as String).toLowerCase() == nomeCurso.toLowerCase(),
    orElse: () => throw Exception('Curso não encontrado'),
  );
  final courseId = cursoDoc.id;

  // Passo 2: Buscar todas as subjects do curso
  final subjectsSnap = await firestore
      .collection('courses')
      .doc(courseId)
      .collection('subjects')
      .get();

  // Passo 3: Filtrar apenas as disciplinas cujo campo 'courseYear' seja igual ao ano do aluno
  final disciplinasDoAno = subjectsSnap.docs.where((doc) {
    // Assegura que 'courseYear' esteja armazenado como int (ou faz o cast, se necessário)
    return doc['courseYear'] == anoAluno;
  }).toList();

  print('Total de disciplinas encontradas: ${disciplinasDoAno.length}');
  return disciplinasDoAno.length;
}

Future<List<Subject>> fetchSubjects() async {
    final student = Session.currentStudent;
    if (student == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('name', isEqualTo: student.courseId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return [];

    final courseDoc = querySnapshot.docs.first;

    final subjectsSnapshot = await courseDoc.reference
        .collection('subjects')
        .where('courseYear', isEqualTo: student.year)
        .get();

    return subjectsSnapshot.docs
        .map((doc) => Subject.fromMap(doc.data(), doc.id))
        .toList();
  }