import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nota_model.dart';
import '../models/tarefa_model.dart';
import '../models/teste_model.dart';

class NotaController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Buscar todas as notas de uma disciplina para um aluno específico
  Future<List<NotaModel>> getNotasByDisciplinaAndAluno(
      String disciplinaId, String alunoId) async {
    try {
      print(
          'Buscando notas para alunoId: $alunoId, disciplinaId: $disciplinaId');
      final querySnapshot = await _firestore
          .collection('notas')
          .where('disciplinaId', isEqualTo: disciplinaId)
          .where('alunoId', isEqualTo: alunoId)
          .get();

      print('Notas encontradas: ${querySnapshot.docs.length}');

      List<NotaModel> notas = [];
      for (var doc in querySnapshot.docs) {
        try {
          final nota = NotaModel.fromMap(doc.data(), doc.id);
          notas.add(nota);
        } catch (e) {
          print('Erro ao processar nota ${doc.id}: $e');
          print('Dados da nota problemática: ${doc.data()}');
          // Continuar com as outras notas em vez de falhar completamente
        }
      }

      print('Notas processadas com sucesso: ${notas.length}');
      return notas;
    } catch (e) {
      print('Erro ao buscar notas: $e');
      return [];
    }
  }

  // Buscar uma tarefa pelo ID
  Future<TarefaModel?> getTarefaById(String tarefaId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tarefas')
          .doc(tarefaId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id; // <- atribuir o id manualmente
        print('Tarefa encontrada: ${data['titulo']}');
        return TarefaModel.fromMap(data);
      }

      return null;
    } catch (e) {
      print('Erro ao buscar tarefa $tarefaId: $e');
      return null;
    }
  }

  // Buscar um teste pelo ID
  Future<TesteModel?> getTesteById(String testeId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('testes')
          .doc(testeId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id; // <- atribuir o id manualmente
        print('Teste encontrado: ${data['nome']}');
        return TesteModel.fromMap(data);
      }

      return null;
    } catch (e) {
      print('Erro ao buscar teste $testeId: $e');
      return null;
    }
  }

  // Buscar tarefas com nome e nota
  Future<List<Map<String, dynamic>>> getTarefasComNotas(
      String disciplinaId, String alunoId) async {
    try {
      List<NotaModel> notas =
          await getNotasByDisciplinaAndAluno(disciplinaId, alunoId);
      List<Map<String, dynamic>> resultados = [];

      for (var nota
          in notas.where((n) => n.tipo == 'tarefa' && n.tarefaId != null)) {
        try {
          TarefaModel? tarefa = await getTarefaById(nota.tarefaId!);
          if (tarefa != null) {
            resultados.add({
              'titulo': tarefa.titulo,
              'nota': nota.nota,
            });
          }
        } catch (e) {
          print('Erro ao processar tarefa ${nota.tarefaId}: $e');
        }
      }
      print('Tarefas com notas encontradas: ${resultados.length}');
      return resultados;
    } catch (e) {
      print('Erro ao buscar tarefas com notas: $e');
      return [];
    }
  }

  // Buscar testes com nome e nota
  Future<List<Map<String, dynamic>>> getTestesComNotas(
      String disciplinaId, String alunoId) async {
    try {
      List<NotaModel> notas =
          await getNotasByDisciplinaAndAluno(disciplinaId, alunoId);
      List<Map<String, dynamic>> resultados = [];

      for (var nota
          in notas.where((n) => n.tipo == 'teste' && n.testeId != null)) {
        try {
          TesteModel? teste = await getTesteById(nota.testeId!);
          if (teste != null) {
            resultados.add({
              'nome': teste.nome,
              'nota': nota.nota,
            });
          }
        } catch (e) {
          print('Erro ao processar teste ${nota.testeId}: $e');
        }
      }
      print('Testes com notas encontrados: ${resultados.length}');
      return resultados;
    } catch (e) {
      print('Erro ao buscar testes com notas: $e');
      return [];
    }
  }
}
