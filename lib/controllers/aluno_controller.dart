import 'package:campus_link/models/student_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


Future<String?> obterAlunoIdPorEmail(String userEmail) async {
  final firestore = FirebaseFirestore.instance;

  final snapshot = await firestore
      .collection('students')
      .where('userId', isEqualTo: userEmail)
      .get();

  if (snapshot.docs.isNotEmpty) {
    return snapshot.docs.first.id;
  }

  return null; // Caso não encontre
}

Future<void> atualizarDadosParciais(Student aluno) async {
  await FirebaseFirestore.instance
      .collection('students')
      .doc(aluno.id)
      .update({
        'morada': aluno.morada,
        'distrito': aluno.distrito,
        'codigoPostal': aluno.codigoPostal,
        'profissao': aluno.profissao,
      });
}

Future<void> atualizarSenha(String alunoId, String novaSenha) async {
  await FirebaseFirestore.instance
      .collection('students')
      .doc(alunoId)
      .update({
        'password': novaSenha,
      });
}
