import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';
import '../models/assignment_data.dart';
import 'dart:convert';
import 'dart:typed_data';

Future<int> contarTrabalhosDoAluno(String nomeCurso, int anoAluno) async {
  final firestore = FirebaseFirestore.instance;
  print('Contando trabalhos do curso: $nomeCurso, ano: $anoAluno');

  // Passo 1: Buscar curso pelo nome
  final cursosSnap = await firestore.collection('courses').get();
  final cursoDoc = cursosSnap.docs.firstWhere(
    (doc) =>
        (doc.data()['name'] as String).toLowerCase() == nomeCurso.toLowerCase(),
    orElse: () => throw Exception('Curso não encontrado'),
  );
  final courseId = cursoDoc.id;

  // Passo 2: Buscar subjects do curso com o mesmo ano
  final subjectsSnap = await firestore
      .collection('courses')
      .doc(courseId)
      .collection('subjects')
      .get();

  final listaSubjectIds = subjectsSnap.docs
      .where((doc) => doc['courseYear'] == anoAluno)
      .map((doc) => doc.id)
      .toList();

  if (listaSubjectIds.isEmpty) {
    print('Nenhuma disciplina encontrada para o ano $anoAluno');
    return 0;
  }

  print('Subjects encontradas: $listaSubjectIds');

  // Passo 3: Buscar todas as tarefas
  final tarefasSnap = await firestore.collection('tarefas').get();
  final agora = DateTime.now();

  // Passo 4: Filtrar tarefas pelas disciplinas do ano e data futura
  final tarefasValidas = tarefasSnap.docs.where((doc) {
    final disciplinaId = doc['disciplinaId'];
    final dataLimiteStr = doc['dataLimite'] ?? '';
    final horaLimiteStr = doc['horaLimite'] ?? '';

    // Tentar fazer parse da data limite
    DateTime? dataLimite = DateTime.tryParse(dataLimiteStr);

    // Se temos hora limite, combinar com a data
    if (dataLimite != null && horaLimiteStr.isNotEmpty) {
      try {
        final horaPartes = horaLimiteStr.split(':');
        if (horaPartes.length >= 2) {
          final hora = int.parse(horaPartes[0]);
          final minuto = int.parse(horaPartes[1]);
          final segundo = horaPartes.length > 2 ? int.parse(horaPartes[2]) : 0;

          dataLimite = DateTime(
            dataLimite.year,
            dataLimite.month,
            dataLimite.day,
            hora,
            minuto,
            segundo,
          );
        }
      } catch (e) {
        // Usar apenas a data se houver erro no parse da hora
      }
    }

    // Se não conseguir fazer parse da data, excluir a tarefa
    if (dataLimite == null) {
      return false;
    }

    bool isValidTime = dataLimite.isAfter(agora);

    // Se a tarefa for do dia de hoje mas com hora 00:00:00 e sem horaLimite,
    // considerar válida até o final do dia
    final isToday = dataLimite.year == agora.year &&
        dataLimite.month == agora.month &&
        dataLimite.day == agora.day;

    if (isToday &&
        dataLimite.hour == 0 &&
        dataLimite.minute == 0 &&
        dataLimite.second == 0 &&
        horaLimiteStr.isEmpty) {
      final endOfDay = DateTime(
          dataLimite.year, dataLimite.month, dataLimite.day, 23, 59, 59);
      isValidTime = endOfDay.isAfter(agora);
    }

    // Verificar se a disciplina está na lista do ano e se a data ainda não passou
    return listaSubjectIds.contains(disciplinaId) && isValidTime;
  }).toList();

  print('Tarefas válidas encontradas: ${tarefasValidas.length}');
  return tarefasValidas.length;
}

Future<List<AssignmentData>> buscarTrabalhosDoAluno(Student student) async {
  final firestore = FirebaseFirestore.instance;

  // Buscar o ID do curso
  final cursosSnap = await firestore.collection('courses').get();
  final cursoDoc = cursosSnap.docs.firstWhere(
    (doc) =>
        (doc.data()['name'] as String).toLowerCase() ==
        student.courseId.toLowerCase(),
    orElse: () => throw Exception('Curso não encontrado'),
  );
  final courseId = cursoDoc.id;

  // Buscar disciplinas do ano do aluno
  final subjectsSnap = await firestore
      .collection('courses')
      .doc(courseId)
      .collection('subjects')
      .where('courseYear', isEqualTo: student.year)
      .get();

  final subjectDocs = subjectsSnap.docs;
  final subjectIds = subjectDocs.map((doc) => doc.id).toList();

  // Criar mapa ID -> Nome da disciplina
  final Map<String, String> subjectNames = {
    for (var doc in subjectDocs) doc.id: doc.data()['name'] ?? 'Disciplina'
  };

  if (subjectIds.isEmpty) return [];

  // Buscar tarefas
  final tarefasSnap = await firestore.collection('tarefas').get();

  final now = DateTime.now();
  final DateFormat formatter = DateFormat('dd/MM/yyyy');

  print('🔍 Data/hora atual para filtro: $now');
  print('📋 Total de tarefas encontradas: ${tarefasSnap.docs.length}');
  print('🎓 Disciplinas válidas do aluno: $subjectIds');

  final tarefasFiltradas = tarefasSnap.docs.where((doc) {
    final data = doc.data();
    final disciplinaId = data['disciplinaId'];
    final dataLimiteStr = data['dataLimite'] ?? '';
    final horaLimiteStr = data['horaLimite'] ?? '';

    // Tentar fazer parse da data limite
    DateTime? dataLimite = DateTime.tryParse(dataLimiteStr);

    // Se temos hora limite, combinar com a data
    if (dataLimite != null && horaLimiteStr.isNotEmpty) {
      try {
        // Parse da hora no formato HH:mm ou HH:mm:ss
        final horaPartes = horaLimiteStr.split(':');
        if (horaPartes.length >= 2) {
          final hora = int.parse(horaPartes[0]);
          final minuto = int.parse(horaPartes[1]);
          final segundo = horaPartes.length > 2 ? int.parse(horaPartes[2]) : 0;

          // Combinar data + hora
          dataLimite = DateTime(
            dataLimite.year,
            dataLimite.month,
            dataLimite.day,
            hora,
            minuto,
            segundo,
          );
        }
      } catch (e) {
        print(
            '⚠️ Erro ao fazer parse da hora: $horaLimiteStr para tarefa ${doc.id}');
      }
    }

    // Se não conseguir fazer parse da data, excluir a tarefa
    if (dataLimite == null) {
      print('❌ Tarefa ${doc.id} excluída: data inválida ($dataLimiteStr)');
      return false;
    }

    final hasValidSubject = subjectIds.contains(disciplinaId);

    // Se a tarefa for do dia de hoje mas com hora 00:00:00 e sem horaLimite,
    // considerar válida até o final do dia
    final isToday = dataLimite.year == now.year &&
        dataLimite.month == now.month &&
        dataLimite.day == now.day;

    bool isValidTime = dataLimite.isAfter(now);
    if (isToday &&
        dataLimite.hour == 0 &&
        dataLimite.minute == 0 &&
        dataLimite.second == 0 &&
        horaLimiteStr.isEmpty) {
      // Para tarefas de hoje sem hora específica, considerar válidas até 23:59:59
      final endOfDay = DateTime(
          dataLimite.year, dataLimite.month, dataLimite.day, 23, 59, 59);
      isValidTime = endOfDay.isAfter(now);
    }

    if (isToday) {
      print('🔍 Tarefa de HOJE - ID: ${doc.id}');
      print('   DataLimite: $dataLimiteStr');
      print('   HoraLimite: $horaLimiteStr');
      print('   DateTime final: $dataLimite');
      print('   Agora: $now');
      print('   isValidTime: $isValidTime');
      print('   hasValidSubject: $hasValidSubject (disciplina: $disciplinaId)');
      print('   Incluída: ${hasValidSubject && isValidTime}');
    }

    // Verificar se a disciplina está na lista do aluno e se a data ainda não passou
    return hasValidSubject && isValidTime;
  });

  final tarefasComDatas = tarefasFiltradas.map((doc) {
    final data = doc.data();
    final dataLimiteStr = data['dataLimite'] ?? '';
    final horaLimiteStr = data['horaLimite'] ?? '';

    // Reconstruir a data limite combinada (mesmo código usado no filtro)
    DateTime? dataLimite = DateTime.tryParse(dataLimiteStr);

    if (dataLimite != null && horaLimiteStr.isNotEmpty) {
      try {
        final horaPartes = horaLimiteStr.split(':');
        if (horaPartes.length >= 2) {
          final hora = int.parse(horaPartes[0]);
          final minuto = int.parse(horaPartes[1]);
          final segundo = horaPartes.length > 2 ? int.parse(horaPartes[2]) : 0;

          dataLimite = DateTime(
            dataLimite.year,
            dataLimite.month,
            dataLimite.day,
            hora,
            minuto,
            segundo,
          );
        }
      } catch (e) {
        // Usar apenas a data se houver erro no parse da hora
      }
    }

    // Fallback para data atual se não conseguir fazer parse
    dataLimite ??= now;

    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final dataLimiteSemHora =
        DateTime(dataLimite.year, dataLimite.month, dataLimite.day);

    final diasRestantes = dataLimiteSemHora.difference(hojeSemHora).inDays;

    final entregasRaw = data['entregas'];
    bool entregue = false;

    if (entregasRaw is List) {
      entregue = entregasRaw.any((e) => e is Map && e['alunoId'] == student.id);
    }

    final disciplinaId = data['disciplinaId'] ?? 'Desconhecida';
    final nomeDisciplina = subjectNames[disciplinaId] ?? disciplinaId;
    final tituloTarefa =
        data['titulo'] ?? 'Trabalho Prático'; // Usar título da tarefa

    // Extrair ficheiros do professor
    final ficheirosRaw = data['ficheiros'];
    List<Map<String, dynamic>> ficheiros = [];

    if (ficheirosRaw is List) {
      ficheiros = ficheirosRaw.map((ficheiro) {
        if (ficheiro is Map<String, dynamic>) {
          return ficheiro;
        }
        return <String, dynamic>{};
      }).toList();
    }

    // Formatar data para exibição (só a data, sem hora)
    final displayDate = formatter
        .format(DateTime(dataLimite.year, dataLimite.month, dataLimite.day));

    return {
      'assignment': AssignmentData(
        subject: nomeDisciplina,
        type:
            tituloTarefa, // Usar o título da tarefa em vez de "Trabalho Prático"
        dueDate: displayDate,
        daysRemaining: '$diasRestantes dias',
        completed: entregue,
        createdDate: formatter
            .format(DateTime.tryParse(data['dataPublicacao'] ?? '') ?? now),
        assignmentType: 'Document',
        descricao: data['descricao'] ?? 'Descrição não disponível',
        id: doc.id, // Adicionando o ID da tarefa
        ficheiros: ficheiros,
      ),
      'dataLimite': dataLimite, // Data limite completa com hora para ordenação
    };
  }).toList();

  // Ordenar por data de entrega (mais próximas primeiro)
  tarefasComDatas.sort((a, b) =>
      (a['dataLimite'] as DateTime).compareTo(b['dataLimite'] as DateTime));

  print('✅ Total de tarefas válidas após filtro: ${tarefasComDatas.length}');

  // Retornar apenas os objetos AssignmentData ordenados
  return tarefasComDatas
      .map((item) => item['assignment'] as AssignmentData)
      .toList();
}

Future<bool> submeterTrabalhoDoAluno({
  required String tarefaId,
  required String alunoId,
  required String fileName,
  required Uint8List fileBytes,
}) async {
  try {
    final base64File = base64Encode(fileBytes);
    final timestamp = DateTime.now();

    final novaEntrega = {
      'alunoId': alunoId,
      'fileName': fileName,
      'base64': base64File,
      'timestamp': timestamp.toIso8601String(),
    };

    final tarefaRef =
        FirebaseFirestore.instance.collection('tarefas').doc(tarefaId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(tarefaRef);
      final data = snapshot.data();

      if (data == null) throw Exception('Tarefa não encontrada');

      final rawEntregas = data['entregas'];
      final entregas = rawEntregas is List
          ? List<Map<String, dynamic>>.from(rawEntregas)
          : <Map<String, dynamic>>[];

      // Remover submissões antigas deste aluno (se existirem)
      entregas.removeWhere((entrega) => entrega['alunoId'] == alunoId);

      // Adicionar nova submissão
      entregas.add(novaEntrega);

      transaction.update(tarefaRef, {'entregas': entregas});
    });

    return true;
  } catch (e) {
    print('Erro ao submeter trabalho: $e');
    return false;
  }
}

Future<Map<String, dynamic>?> verificarSubmissaoExistente(
    String tarefaId, String alunoId) async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Buscar a tarefa pelo ID
    final tarefaDoc = await firestore.collection('tarefas').doc(tarefaId).get();

    if (!tarefaDoc.exists) {
      return null;
    }

    final data = tarefaDoc.data()!;
    final entregasRaw = data['entregas'];

    if (entregasRaw is List) {
      // Procurar por uma entrega deste aluno
      for (final entrega in entregasRaw) {
        if (entrega is Map && entrega['alunoId'] == alunoId) {
          return {
            'fileName': entrega['fileName'],
            'timestamp': entrega['timestamp'],
            'base64': entrega['base64'],
          };
        }
      }
    }

    return null;
  } catch (e) {
    print('Erro ao verificar submissão existente: $e');
    return null;
  }
}
