import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exame_model.dart';
import '../models/teste_model.dart';
import '../session/session.dart';

class ExamesTestesController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Buscar todos os exames do aluno logado
  Future<List<ExameModel>> buscarExamesDoAlunoLogado() async {
    try {
      // Verificar se há usuário logado na sessão
      if (Session.currentStudent == null) {
        print('❌ Nenhum usuário logado na sessão');
        return [];
      }

      String courseId = Session.currentStudent!.courseId;
      int year = Session.currentStudent!.year;

      print('🔍 Buscando exames para aluno: ${Session.currentStudent!.nome}');
      print('   📚 CourseId: "$courseId"');
      print('   📅 Year: $year');

      // Primeiro, buscar o curso no Firestore
      print('🔍 Buscando curso com name igual a: "$courseId"');
      QuerySnapshot coursesQuery = await _firestore
          .collection('courses')
          .where('name', isEqualTo: courseId)
          .get();

      print(
          '📊 Cursos encontrados com name="$courseId": ${coursesQuery.docs.length}');

      if (coursesQuery.docs.isEmpty) {
        print('❌ Curso não encontrado: $courseId');
        return [];
      }

      String courseDocId = coursesQuery.docs.first.id;

      // Buscar disciplinas do ano do aluno
      QuerySnapshot subjectsQuery = await _firestore
          .collection('courses')
          .doc(courseDocId)
          .collection('subjects')
          .where('courseYear', isEqualTo: year)
          .get();

      List<String> subjectIds =
          subjectsQuery.docs.map((doc) => doc.id).toList();
      Map<String, String> subjectNames = {};

      for (var doc in subjectsQuery.docs) {
        var data = doc.data() as Map<String, dynamic>;
        subjectNames[doc.id] = data['name'] ?? doc.id;
      }

      if (subjectIds.isEmpty) {
        print('❌ Nenhuma disciplina encontrada para o ano $year');
        return [];
      }

      // Buscar exames para as disciplinas do aluno
      List<ExameModel> exames = [];

      for (String subjectId in subjectIds) {
        print('🔍 Buscando exames para subjectId: $subjectId');

        QuerySnapshot examesQuery = await _firestore
            .collection('exam_schedules')
            .where('subjectId', isEqualTo: subjectId)
            .get();

        print(
            '   📊 Exames encontrados para $subjectId: ${examesQuery.docs.length}');

        for (var doc in examesQuery.docs) {
          var data = doc.data() as Map<String, dynamic>;

          // A estrutura dos dados usa campos flattened como "exams.Época Normal"
          // em vez de um objeto aninhado "exams"

          // Época Normal
          if (data['exams.Época Normal'] != null) {
            DateTime dataEpocaNormal;
            try {
              // Tentar primeiro como string ISO
              if (data['exams.Época Normal'] is String) {
                dataEpocaNormal = DateTime.parse(data['exams.Época Normal']);
              } else if (data['exams.Época Normal'] is Timestamp) {
                dataEpocaNormal =
                    (data['exams.Época Normal'] as Timestamp).toDate();
              } else {
                // Fallback para milliseconds
                dataEpocaNormal = DateTime.fromMillisecondsSinceEpoch(
                    int.parse(data['exams.Época Normal'].toString()));
              }

              // Remover a hora, manter apenas a data
              dataEpocaNormal = DateTime(dataEpocaNormal.year,
                  dataEpocaNormal.month, dataEpocaNormal.day);

              exames.add(ExameModel(
                id: '${doc.id}_normal',
                subjectId: subjectId,
                disciplinaNome: subjectNames[subjectId] ?? subjectId,
                professorId: data['professorId'] ?? '',
                tipo: 'Época Normal',
                dataHora: dataEpocaNormal,
              ));
            } catch (e) {
              print(
                  '⚠️ Erro ao converter data Época Normal: ${data['exams.Época Normal']} - $e');
            }
          }

          // Época Especial
          if (data['exams.Época Especial'] != null) {
            DateTime dataEpocaEspecial;
            try {
              // Tentar primeiro como string ISO
              if (data['exams.Época Especial'] is String) {
                dataEpocaEspecial =
                    DateTime.parse(data['exams.Época Especial']);
              } else if (data['exams.Época Especial'] is Timestamp) {
                dataEpocaEspecial =
                    (data['exams.Época Especial'] as Timestamp).toDate();
              } else {
                // Fallback para milliseconds
                dataEpocaEspecial = DateTime.fromMillisecondsSinceEpoch(
                    int.parse(data['exams.Época Especial'].toString()));
              }

              // Remover a hora, manter apenas a data
              dataEpocaEspecial = DateTime(dataEpocaEspecial.year,
                  dataEpocaEspecial.month, dataEpocaEspecial.day);

              exames.add(ExameModel(
                id: '${doc.id}_especial',
                subjectId: subjectId,
                disciplinaNome: subjectNames[subjectId] ?? subjectId,
                professorId: data['professorId'] ?? '',
                tipo: 'Época Especial',
                dataHora: dataEpocaEspecial,
              ));
            } catch (e) {
              print(
                  '⚠️ Erro ao converter data Época Especial: ${data['exams.Época Especial']} - $e');
            }
          }

          // Recurso
          if (data['exams.Recurso'] != null) {
            DateTime dataRecurso;
            try {
              // Tentar primeiro como string ISO
              if (data['exams.Recurso'] is String) {
                dataRecurso = DateTime.parse(data['exams.Recurso']);
              } else if (data['exams.Recurso'] is Timestamp) {
                dataRecurso = (data['exams.Recurso'] as Timestamp).toDate();
              } else {
                // Fallback para milliseconds
                dataRecurso = DateTime.fromMillisecondsSinceEpoch(
                    int.parse(data['exams.Recurso'].toString()));
              }

              // Remover a hora, manter apenas a data
              dataRecurso = DateTime(
                  dataRecurso.year, dataRecurso.month, dataRecurso.day);

              exames.add(ExameModel(
                id: '${doc.id}_recurso',
                subjectId: subjectId,
                disciplinaNome: subjectNames[subjectId] ?? subjectId,
                professorId: data['professorId'] ?? '',
                tipo: 'Recurso',
                dataHora: dataRecurso,
              ));
            } catch (e) {
              print(
                  '⚠️ Erro ao converter data Recurso: ${data['exams.Recurso']} - $e');
            }
          }
        }
      }

      print('✅ Total de exames encontrados: ${exames.length}');
      return exames;
    } catch (e) {
      print('❌ Erro ao buscar exames: $e');
      return [];
    }
  }

  // Buscar todos os testes do aluno logado
  Future<List<TesteModel>> buscarTestesDoAlunoLogado() async {
    try {
      // Verificar se há usuário logado na sessão
      if (Session.currentStudent == null) {
        print('❌ Nenhum usuário logado na sessão');
        return [];
      }

      String courseId = Session.currentStudent!.courseId;
      int year = Session.currentStudent!.year;

      print('🔍 Buscando testes para aluno: ${Session.currentStudent!.nome}');
      print('   📚 CourseId: "$courseId"');
      print('   📅 Year: $year');

      // Primeiro, buscar o curso no Firestore
      QuerySnapshot coursesQuery = await _firestore
          .collection('courses')
          .where('name', isEqualTo: courseId)
          .get();

      if (coursesQuery.docs.isEmpty) {
        print('❌ Curso não encontrado: $courseId');
        return [];
      }

      String courseDocId = coursesQuery.docs.first.id;

      // Buscar disciplinas do ano do aluno
      QuerySnapshot subjectsQuery = await _firestore
          .collection('courses')
          .doc(courseDocId)
          .collection('subjects')
          .where('courseYear', isEqualTo: year)
          .get();

      List<String> subjectIds =
          subjectsQuery.docs.map((doc) => doc.id).toList();

      if (subjectIds.isEmpty) {
        print('❌ Nenhuma disciplina encontrada para o ano $year');
        return [];
      }

      print('🔍 SubjectIds para buscar testes: $subjectIds');

      // Buscar testes para as disciplinas do aluno
      QuerySnapshot testesQuery = await _firestore
          .collection('testes')
          .where('disciplinaId', whereIn: subjectIds)
          .orderBy('dataHora', descending: true)
          .get();

      print(
          '📊 Total de testes encontrados na query: ${testesQuery.docs.length}');

      List<TesteModel> testes = [];
      for (var doc in testesQuery.docs) {
        try {
          var data = doc.data() as Map<String, dynamic>;
          TesteModel teste = TesteModel.fromMap(data);
          testes.add(teste);
        } catch (e) {
          print('   ❌ Erro ao criar TesteModel do doc ${doc.id}: $e');
        }
      }

      print('✅ Total de testes encontrados: ${testes.length}');
      return testes;
    } catch (e) {
      print('❌ Erro ao buscar testes: $e');
      return [];
    }
  }

  // Buscar exames agrupados por disciplina
  Future<Map<String, List<ExameModel>>> buscarExamesPorDisciplina() async {
    try {
      List<ExameModel> todosExames = await buscarExamesDoAlunoLogado();

      Map<String, List<ExameModel>> examesPorDisciplina = {};

      for (ExameModel exame in todosExames) {
        String disciplina = exame.disciplinaNome;

        if (!examesPorDisciplina.containsKey(disciplina)) {
          examesPorDisciplina[disciplina] = [];
        }

        examesPorDisciplina[disciplina]!.add(exame);
      }

      // Ordenar exames por data dentro de cada disciplina
      examesPorDisciplina.forEach((disciplina, exames) {
        exames.sort((a, b) => a.dataHora.compareTo(b.dataHora));
      });

      print(
          '✅ Exames agrupados por disciplina: ${examesPorDisciplina.keys.length} disciplinas');
      return examesPorDisciplina;
    } catch (e) {
      print('❌ Erro ao agrupar exames por disciplina: $e');
      return {};
    }
  }

  // Buscar testes agrupados por disciplina
  Future<Map<String, List<TesteModel>>> buscarTestesPorDisciplina() async {
    try {
      List<TesteModel> todosTestes = await buscarTestesDoAlunoLogado();

      Map<String, List<TesteModel>> testesPorDisciplina = {};

      for (TesteModel teste in todosTestes) {
        // Buscar nome da disciplina usando o ID
        String disciplinaNome = await _obterNomeDisciplina(teste.disciplinaId);

        if (!testesPorDisciplina.containsKey(disciplinaNome)) {
          testesPorDisciplina[disciplinaNome] = [];
        }

        testesPorDisciplina[disciplinaNome]!.add(teste);
      }

      // Ordenar testes por data dentro de cada disciplina
      testesPorDisciplina.forEach((disciplina, testes) {
        testes.sort((a, b) => a.dataHora.compareTo(b.dataHora));
      });

      print(
          '✅ Testes agrupados por disciplina: ${testesPorDisciplina.keys.length} disciplinas');
      return testesPorDisciplina;
    } catch (e) {
      print('❌ Erro ao agrupar testes por disciplina: $e');
      return {};
    }
  }

  // Método auxiliar para obter nome da disciplina
  Future<String> _obterNomeDisciplina(String disciplinaId) async {
    try {
      // Buscar em todas as coleções de disciplinas
      QuerySnapshot coursesQuery = await _firestore.collection('courses').get();

      for (var courseDoc in coursesQuery.docs) {
        DocumentSnapshot disciplinaDoc = await courseDoc.reference
            .collection('subjects')
            .doc(disciplinaId)
            .get();

        if (disciplinaDoc.exists) {
          var data = disciplinaDoc.data() as Map<String, dynamic>;
          return data['name'] ?? disciplinaId;
        }
      }

      return disciplinaId; // Retorna o ID se não encontrar o nome
    } catch (e) {
      print('❌ Erro ao obter nome da disciplina: $e');
      return disciplinaId;
    }
  }

  // Calcular estatísticas de exames por disciplina
  Map<String, dynamic> calcularEstatisticasExamesDisciplina(
      List<ExameModel> exames) {
    int totalExames = exames.length;
    int examesRealizados = exames.where((e) => e.jaPasso).length;
    int examesPendentes = totalExames - examesRealizados;

    int epocaNormal = exames.where((e) => e.tipo == 'Época Normal').length;
    int epocaEspecial = exames.where((e) => e.tipo == 'Época Especial').length;
    int recurso = exames.where((e) => e.tipo == 'Recurso').length;

    return {
      'totalExames': totalExames,
      'examesRealizados': examesRealizados,
      'examesPendentes': examesPendentes,
      'epocaNormal': epocaNormal,
      'epocaEspecial': epocaEspecial,
      'recurso': recurso,
    };
  }

  // Calcular estatísticas de testes por disciplina
  Map<String, dynamic> calcularEstatisticasTestesDisciplina(
      List<TesteModel> testes) {
    int totalTestes = testes.length;
    int testesRealizados =
        testes.where((t) => t.dataHora.isBefore(DateTime.now())).length;
    int testesPendentes = totalTestes - testesRealizados;

    return {
      'totalTestes': totalTestes,
      'testesRealizados': testesRealizados,
      'testesPendentes': testesPendentes,
    };
  }

  // Método de debug para verificar exames disponíveis
  Future<void> debugExamesDisponiveis() async {
    try {
      print('🔍 DEBUG: Verificando todos os exames disponíveis...');

      // Debug do aluno atual
      if (Session.currentStudent != null) {
        print('👤 Aluno atual: ${Session.currentStudent!.nome}');
        print('   📚 CourseId: ${Session.currentStudent!.courseId}');
        print('   📅 Year: ${Session.currentStudent!.year}');

        // Buscar disciplinas do aluno
        QuerySnapshot coursesQuery = await _firestore
            .collection('courses')
            .where('name', isEqualTo: Session.currentStudent!.courseId)
            .get();

        if (coursesQuery.docs.isNotEmpty) {
          String courseDocId = coursesQuery.docs.first.id;
          print('   🏫 CourseDocId: $courseDocId');

          QuerySnapshot subjectsQuery = await _firestore
              .collection('courses')
              .doc(courseDocId)
              .collection('subjects')
              .where('courseYear', isEqualTo: Session.currentStudent!.year)
              .get();

          print('   📋 Disciplinas do aluno:');
          for (var doc in subjectsQuery.docs) {
            var data = doc.data() as Map<String, dynamic>;
            print('      - ${doc.id}: ${data['name']}');
          }
        }
      }

      QuerySnapshot todosExames =
          await _firestore.collection('exam_schedules').limit(20).get();

      print(
          '📊 Total de documentos na collection exam_schedules: ${todosExames.docs.length}');

      for (var doc in todosExames.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print('   📄 Doc: ${doc.id}');
        print('      SubjectId: ${data['subjectId']}');
        print('      CourseId: ${data['courseId']}');
        print('      Época Normal: ${data['exams.Época Normal']}');
        print('      Época Especial: ${data['exams.Época Especial']}');
        print('      Recurso: ${data['exams.Recurso']}');
        print('   ---');
      }
    } catch (e) {
      print('❌ Erro no debug: $e');
    }
  }

  // Método de debug para verificar testes disponíveis
  Future<void> debugTestesDisponiveis() async {
    try {
      print('🔍 DEBUG: Verificando todos os testes disponíveis...');

      // Verificar na collection testes_aluno
      QuerySnapshot testesAluno =
          await _firestore.collection('testes_aluno').limit(20).get();

      print(
          '📊 Total de documentos na collection testes_aluno: ${testesAluno.docs.length}');

      for (var doc in testesAluno.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print('   📄 Doc: ${doc.id}');
        print('      disciplinaId: ${data['disciplinaId']}');
        print('      dataHora: ${data['dataHora']}');
        print('      All fields: $data');
        print('   ---');
      }

      // Verificar também na collection original 'testes'
      print('🔍 Verificando também na collection original "testes"...');
      QuerySnapshot testesOriginal =
          await _firestore.collection('testes').limit(20).get();

      print(
          '📊 Total de documentos na collection testes: ${testesOriginal.docs.length}');

      for (var doc in testesOriginal.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print('   📄 Doc: ${doc.id}');
        print('      disciplinaId: ${data['disciplinaId']}');
        print('      dataHora: ${data['dataHora']}');
        print('      All fields: $data');
        print('   ---');
      }
    } catch (e) {
      print('❌ Erro no debug de testes: $e');
    }
  }

  // Método para forçar debug de testes (para teste manual)
  Future<void> debugTestesForced() async {
    print('🔍 FORÇANDO DEBUG DE TESTES...');
    await debugTestesDisponiveis();
  }

  // Método simplificado para testar busca de testes
  Future<void> testarBuscaTestes() async {
    try {
      print('🧪 TESTE SIMPLIFICADO DE BUSCA DE TESTES...');

      // Buscar diretamente por subjectIds conhecidos
      List<String> subjectIds = [
        '2kPAAvsCOin2CufxJ6nm',
        'S4UbgZS9H4jwpQfGflv7'
      ];

      print('🔍 Testando busca com subjectIds: $subjectIds');

      // Testar collection testes_aluno
      print('📋 Testando collection testes_aluno...');
      QuerySnapshot testesAluno = await _firestore
          .collection('testes_aluno')
          .where('disciplinaId', whereIn: subjectIds)
          .get();

      print('   Resultados: ${testesAluno.docs.length} documentos');

      // Testar collection testes
      print('📋 Testando collection testes...');
      QuerySnapshot testes = await _firestore
          .collection('testes')
          .where('disciplinaId', whereIn: subjectIds)
          .get();

      print('   Resultados: ${testes.docs.length} documentos');

      // Testar sem filtro (todos os testes)
      print('📋 Testando busca geral na collection testes_aluno...');
      QuerySnapshot todosTestesAluno =
          await _firestore.collection('testes_aluno').limit(5).get();

      print('   Total geral: ${todosTestesAluno.docs.length} documentos');

      print('📋 Testando busca geral na collection testes...');
      QuerySnapshot todosTestes =
          await _firestore.collection('testes').limit(5).get();

      print('   Total geral: ${todosTestes.docs.length} documentos');
    } catch (e) {
      print('❌ Erro no teste: $e');
    }
  }
}
