import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/horario_model.dart';
import '../models/student_model.dart';
import '../session/session.dart';

class HorarioController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Buscar horário do aluno logado
  Future<Horario?> buscarHorarioDoAlunoLogado() async {
    try {
      // Verificar se há usuário logado na sessão
      if (Session.currentStudent == null) {
        print('❌ Nenhum usuário logado na sessão');
        return null;
      }

      Student aluno = Session.currentStudent!;

      print('🔍 Buscando horário para usuário: ${aluno.nome}');
      print('   📚 CourseId: ${aluno.courseId}');
      print('   📅 Year: ${aluno.year}');

      // Buscar horário baseado no courseId e year do aluno da sessão
      return await buscarHorarioPorCursoEAno(aluno.courseId, aluno.year);
    } catch (e) {
      print('❌ Erro ao buscar horário do aluno logado: $e');
      return null;
    }
  }

  // Buscar horário por curso e ano específico
  Future<Horario?> buscarHorarioPorCursoEAno(String courseId, int year) async {
    try {
      print('🔍 Buscando horário:');
      print('   📚 CourseId do aluno: $courseId');
      print('   📅 Year: $year');

      // Primeira tentativa: buscar pelo courseId direto (document ID)
      DocumentSnapshot horarioDoc =
          await _firestore.collection('horarios').doc(courseId).get();

      if (horarioDoc.exists) {
        print('✅ Horário encontrado pelo courseId direto');
        return _criarHorarioFromDoc(horarioDoc, year);
      }

      print(
          '⚠️ Horário não encontrado pelo courseId direto. Buscando por nome normalizado...');

      // Segunda tentativa: normalizar o courseId e buscar
      String courseIdNormalizado = _normalizarNomeCurso(courseId);
      print('   📚 CourseId normalizado: $courseIdNormalizado');

      horarioDoc = await _firestore
          .collection('horarios')
          .doc(courseIdNormalizado)
          .get();

      if (horarioDoc.exists) {
        print('✅ Horário encontrado pelo courseId normalizado');
        return _criarHorarioFromDoc(horarioDoc, year);
      }

      print(
          '⚠️ Horário não encontrado pelo courseId normalizado. Buscando em todos os horários...');

      // Terceira tentativa: buscar em todos os horários e comparar nomes
      QuerySnapshot horariosQuery =
          await _firestore.collection('horarios').get();

      print(
          '🔍 Verificando todos os horários (${horariosQuery.docs.length} documentos)...');

      for (var horarioDocItem in horariosQuery.docs) {
        var horarioData = horarioDocItem.data() as Map<String, dynamic>;
        String horarioDocId = horarioDocItem.id;

        print('   Verificando horário: $horarioDocId');

        // Normalizar tanto o courseId quanto o document ID para comparação
        String courseIdNorm = _normalizarNomeCurso(courseId);
        String docIdNorm = _normalizarNomeCurso(horarioDocId);

        if (courseIdNorm == docIdNorm) {
          print(
              '✅ Match por normalização: $courseId → $courseIdNorm = $horarioDocId → $docIdNorm');
          return _criarHorarioFromDoc(horarioDocItem, year);
        }

        // Verificar se existe um campo courseId no horário que corresponde
        if (horarioData['courseId'] != null) {
          String horarioCourseId = horarioData['courseId'];
          String horarioCourseIdNorm = _normalizarNomeCurso(horarioCourseId);

          if (courseIdNorm == horarioCourseIdNorm) {
            print(
                '✅ Match por campo courseId normalizado: $courseId → $courseIdNorm = $horarioCourseId → $horarioCourseIdNorm');
            return _criarHorarioFromDoc(horarioDocItem, year);
          }
        }
      }

      // Quarta tentativa: buscar na collection courses pelo courseId e depois buscar horário pelo document ID do curso
      print('⚠️ Tentando buscar na collection courses...');

      QuerySnapshot coursesQuery = await _firestore
          .collection('courses')
          .where('name', isEqualTo: courseId)
          .get();

      if (coursesQuery.docs.isNotEmpty) {
        String courseDocId = coursesQuery.docs.first.id;
        print('✅ Curso encontrado na collection courses com ID: $courseDocId');

        horarioDoc =
            await _firestore.collection('horarios').doc(courseDocId).get();

        if (horarioDoc.exists) {
          print('✅ Horário encontrado pelo courseDocId da collection courses');
          return _criarHorarioFromDoc(horarioDoc, year);
        }

        // Tentar com courseDocId normalizado
        String courseDocIdNorm = _normalizarNomeCurso(courseDocId);
        horarioDoc =
            await _firestore.collection('horarios').doc(courseDocIdNorm).get();

        if (horarioDoc.exists) {
          print(
              '✅ Horário encontrado pelo courseDocId normalizado da collection courses');
          return _criarHorarioFromDoc(horarioDoc, year);
        }
      }

      print('❌ Nenhum horário encontrado para o curso: $courseId');
      return null;
    } catch (e) {
      print('❌ Erro ao buscar horário: $e');
      return null;
    }
  }

  // Método para normalizar nomes de cursos para correspondência
  String _normalizarNomeCurso(String nome) {
    return nome
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  // Método auxiliar para criar horário a partir do documento
  Horario? _criarHorarioFromDoc(DocumentSnapshot horarioDoc, int year) {
    try {
      var horarioData = horarioDoc.data() as Map<String, dynamic>;
      print('✅ Dados do horário encontrados: $horarioData');

      // Verificar se existe horário para o ano específico
      if (horarioData['aulasPorAno'] == null ||
          horarioData['aulasPorAno'][year.toString()] == null) {
        print(
            '❌ Não há aulas definidas para o ano $year no horário ${horarioDoc.id}');
        return null;
      }

      // Criar objeto Horario com as aulas do ano específico
      Horario horario = Horario.fromMap(horarioDoc.id, horarioData, year);

      print('✅ Horário carregado com sucesso!');
      print('   📊 Total de aulas: ${horario.aulas.length}');
      print('   📅 Aulas por dia: ${horario.aulasPorDia.keys.toList()}');

      return horario;
    } catch (e) {
      print('❌ Erro ao criar horário do documento: $e');
      return null;
    }
  }

  // Buscar aulas de hoje do aluno logado
  Future<List<Aula>> buscarAulasDeHoje() async {
    try {
      Horario? horario = await buscarHorarioDoAlunoLogado();

      if (horario == null) {
        return [];
      }

      DateTime hoje = DateTime.now();
      String diaSemana = _getDiaSemanaPortugues(hoje.weekday);

      return horario.aulasPorDia[diaSemana] ?? [];
    } catch (e) {
      print('❌ Erro ao buscar aulas de hoje: $e');
      return [];
    }
  }

  // Buscar aulas para um dia específico
  Future<List<Aula>> buscarAulasDoAlunoParaDia(String diaSemana) async {
    try {
      Horario? horario = await buscarHorarioDoAlunoLogado();

      if (horario == null) {
        return [];
      }

      return horario.aulasPorDia[diaSemana] ?? [];
    } catch (e) {
      print('❌ Erro ao buscar aulas do dia: $e');
      return [];
    }
  }

  // Obter próxima aula do aluno
  Future<Aula?> buscarProximaAula() async {
    try {
      Horario? horario = await buscarHorarioDoAlunoLogado();

      if (horario == null || horario.aulas.isEmpty) {
        return null;
      }

      DateTime now = DateTime.now();
      String diaAtual = _getDiaSemanaPortugues(now.weekday);
      String horaAtual =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Buscar aulas do dia atual que ainda não começaram
      List<Aula> aulasHoje = horario.aulasPorDia[diaAtual] ?? [];

      for (Aula aula in aulasHoje) {
        if (aula.horaInicio.compareTo(horaAtual) > 0) {
          return aula;
        }
      }

      return null;
    } catch (e) {
      print('❌ Erro ao buscar próxima aula: $e');
      return null;
    }
  }

  // Buscar todos os horários disponíveis (para debug/admin)
  Future<List<Horario>> buscarTodosHorarios() async {
    try {
      print('🔍 Buscando todos os horários...');

      QuerySnapshot horariosQuery =
          await _firestore.collection('horarios').get();

      List<Horario> horarios = [];

      for (var doc in horariosQuery.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Para cada curso, criar horários para cada ano disponível
        if (data['aulasPorAno'] != null) {
          Map<String, dynamic> aulasPorAno = data['aulasPorAno'];

          for (String yearStr in aulasPorAno.keys) {
            int year = int.tryParse(yearStr) ?? 1;
            Horario horario = Horario.fromMap(doc.id, data, year);
            if (horario.aulas.isNotEmpty) {
              horarios.add(horario);
            }
          }
        }
      }

      print('✅ Total de horários encontrados: ${horarios.length}');
      return horarios;
    } catch (e) {
      print('❌ Erro ao buscar todos os horários: $e');
      return [];
    }
  }

  // Converter número do dia para português
  String _getDiaSemanaPortugues(int weekday) {
    switch (weekday) {
      case 1:
        return 'Segunda';
      case 2:
        return 'Terça';
      case 3:
        return 'Quarta';
      case 4:
        return 'Quinta';
      case 5:
        return 'Sexta';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Segunda';
    }
  }
}

// Função legacy para compatibilidade (caso esteja sendo usada em outro lugar)
Future<List<Aula>> buscarAulasDeHoje(Student student) async {
  final controller = HorarioController();
  return await controller.buscarAulasDeHoje();
}
