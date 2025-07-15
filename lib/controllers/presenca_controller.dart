import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/aluno_controller.dart';
import '../models/presenca_model.dart';
import '../session/session.dart';

class PresencaController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Buscar todas as presenças do aluno logado
  Future<List<PresencaModel>> buscarPresencasDoAlunoLogado() async {
    try {
      // Verificar se há usuário logado na sessão
      if (Session.currentStudent == null) {
        print('❌ Nenhum usuário logado na sessão');
        return [];
      }

      String alunoId = Session.currentStudent!.id; // Document ID do student

      print(
          '🔍 Buscando presenças para aluno: ${Session.currentStudent!.nome}');
      print('   📚 Document ID (alunoId): $alunoId');
      print('   📧 UserID (email): ${Session.currentStudent!.userId}');

      // Buscar presenças do aluno na collection 'presencas'
      // O alunoId nas presenças deve corresponder ao document ID do student
      QuerySnapshot presencasQuery = await _firestore
          .collection('presencas')
          .where('alunoId', isEqualTo: alunoId)
          .orderBy('dataAula', descending: true)
          .get();

      print('📋 Query executada: presencas.where("alunoId", "==", "$alunoId")');
      print('📊 Documentos encontrados: ${presencasQuery.docs.length}');

      List<PresencaModel> presencas = [];

      for (var doc in presencasQuery.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print(
            '   📄 Documento presença: ${doc.id} - alunoId: ${data['alunoId']}');
        PresencaModel presenca = PresencaModel.fromFirestore(data, doc.id);
        presencas.add(presenca);
      }

      print('✅ Total de presenças encontradas: ${presencas.length}');

      return presencas;
    } catch (e) {
      print('❌ Erro ao buscar presenças: $e');
      return [];
    }
  }

  // Buscar presenças agrupadas por disciplina
  Future<Map<String, List<PresencaModel>>>
      buscarPresencasPorDisciplina() async {
    try {
      List<PresencaModel> todasPresencas = await buscarPresencasDoAlunoLogado();

      Map<String, List<PresencaModel>> presencasPorDisciplina = {};

      for (PresencaModel presenca in todasPresencas) {
        String disciplina = presenca.disciplinaNome;

        if (!presencasPorDisciplina.containsKey(disciplina)) {
          presencasPorDisciplina[disciplina] = [];
        }

        presencasPorDisciplina[disciplina]!.add(presenca);
      }

      // Ordenar presenças dentro de cada disciplina por data
      presencasPorDisciplina.forEach((disciplina, presencas) {
        presencas.sort((a, b) => b.dataAula.compareTo(a.dataAula));
      });

      print(
          '✅ Presenças agrupadas por ${presencasPorDisciplina.length} disciplinas');

      return presencasPorDisciplina;
    } catch (e) {
      print('❌ Erro ao agrupar presenças por disciplina: $e');
      return {};
    }
  }

  // Calcular estatísticas de presença para uma disciplina
  Map<String, dynamic> calcularEstatisticasDisciplina(
      List<PresencaModel> presencas) {
    int totalAulas = presencas.length;
    int aulasPresentes = presencas.where((p) => p.presente).length;
    int aulasFaltou = totalAulas - aulasPresentes;
    double percentualPresenca =
        totalAulas > 0 ? (aulasPresentes / totalAulas) * 100 : 0.0;

    String corStatus;
    String statusTexto;

    if (percentualPresenca >= 75) {
      corStatus = 'green';
      statusTexto = 'Bom';
    } else if (percentualPresenca >= 50) {
      corStatus = 'orange';
      statusTexto = 'Regular';
    } else {
      corStatus = 'red';
      statusTexto = 'Baixo';
    }

    return {
      'totalAulas': totalAulas,
      'aulasPresentes': aulasPresentes,
      'aulasFaltou': aulasFaltou,
      'percentualPresenca': percentualPresenca.round(),
      'corStatus': corStatus,
      'statusTexto': statusTexto,
    };
  }

  // Método de debug para verificar todas as presenças disponíveis
  Future<void> debugPresencasDisponiveis() async {
    try {
      print('🔍 DEBUG: Verificando todas as presenças disponíveis...');

      QuerySnapshot todasPresencas = await _firestore
          .collection('presencas')
          .limit(10) // Limitar para não sobrecarregar
          .get();

      print(
          '📊 Total de documentos na collection presencas: ${todasPresencas.docs.length}');

      Set<String> alunosIds = {};

      for (var doc in todasPresencas.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String alunoId = data['alunoId'] ?? 'N/A';
        String disciplina = data['disciplinaNome'] ?? 'N/A';

        alunosIds.add(alunoId);
        print('   📄 Doc: ${doc.id}');
        print('      AlunoId: $alunoId');
        print('      Disciplina: $disciplina');
        print('   ---');
      }

      print('👥 AlunoIds únicos encontrados: ${alunosIds.toList()}');

      if (Session.currentStudent != null) {
        String currentAlunoId = Session.currentStudent!.id;
        print('🔍 Aluno atual: $currentAlunoId');
        print('❓ Existe nas presenças? ${alunosIds.contains(currentAlunoId)}');
      }
    } catch (e) {
      print('❌ Erro no debug: $e');
    }
  }
}

// Função legacy para compatibilidade
Future<double> calcularPercentagemPresencasPorEmail(String userEmail) async {
  final alunoId = await obterAlunoIdPorEmail(userEmail);

  if (alunoId == null) return 0.0;

  final firestore = FirebaseFirestore.instance;

  final snapshot = await firestore
      .collection('presencas')
      .where('alunoId', isEqualTo: alunoId)
      .get();

  final totalAulas = snapshot.docs.length;

  if (totalAulas == 0) return 0.0;

  final totalPresentes = snapshot.docs.where((doc) {
    return doc['presente'] == true;
  }).length;

  return (totalPresentes / totalAulas) * 100;
}
