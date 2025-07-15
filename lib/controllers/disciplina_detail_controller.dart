import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/professor_model.dart';
import '../models/student_model.dart';
import '../models/material_model.dart';

class DisciplinaDetailController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Buscar professor da disciplina
  Future<Professor?> buscarProfessorDaDisciplina(
      String disciplinaId, String disciplinaNome) async {
    try {
      print(
          'Buscando professor para disciplina: $disciplinaId, nome: $disciplinaNome');

      // Primeiro, vamos ver todos os professores para debug
      QuerySnapshot todosProfessoresQuery =
          await _firestore.collection('professores').get();

      print(
          'Total de professores na base: ${todosProfessoresQuery.docs.length}');

      // Ver TODOS os professores para debug completo
      print('=== TODOS OS PROFESSORES NA BASE ===');
      for (var doc in todosProfessoresQuery.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print(
            'ID: ${doc.id} - Nome: ${data['nome']} - Disciplinas: ${data['disciplinas']}');
      }
      print('=== FIM DA LISTA DE PROFESSORES ===');

      // Primeiro tentar buscar pelo ID da disciplina
      QuerySnapshot professorQuery = await _firestore
          .collection('professores')
          .where('disciplinas', arrayContains: disciplinaId)
          .get();

      print(
          'Professores encontrados com disciplinaId "$disciplinaId": ${professorQuery.docs.length}');

      // Se não encontrar, tentar buscar pelo nome da disciplina
      if (professorQuery.docs.isEmpty) {
        professorQuery = await _firestore
            .collection('professores')
            .where('disciplinas', arrayContains: disciplinaNome)
            .get();

        print(
            'Professores encontrados com disciplinaNome "$disciplinaNome": ${professorQuery.docs.length}');
      }

      // Se ainda não encontrar, fazer busca manual mais flexível
      if (professorQuery.docs.isEmpty) {
        print(
            '⚠️ Nenhum professor encontrado com critérios rígidos. Fazendo busca manual...');

        for (var doc in todosProfessoresQuery.docs) {
          var data = doc.data() as Map<String, dynamic>;
          List<dynamic> disciplinas = data['disciplinas'] ?? [];

          print(
              'Analisando professor ${data['nome']} com disciplinas: $disciplinas');

          // Verificar se alguma disciplina do professor contém o ID ou nome procurado
          for (var disciplina in disciplinas) {
            String disciplinaStr = disciplina.toString().toLowerCase().trim();
            String targetId = disciplinaId.toLowerCase().trim();
            String targetNome = disciplinaNome.toLowerCase().trim();

            if (disciplinaStr == targetId ||
                disciplinaStr == targetNome ||
                disciplinaStr.contains(targetId) ||
                disciplinaStr.contains(targetNome) ||
                targetId.contains(disciplinaStr) ||
                targetNome.contains(disciplinaStr)) {
              print(
                  '✅ Match encontrado! Professor: ${data['nome']}, Disciplina: $disciplina');

              return Professor.fromMap(data, doc.id);
            }
          }
        }

        print('❌ Nenhum professor encontrado mesmo com busca flexível');

        // Como último recurso, retornar o primeiro professor (para teste)
        if (todosProfessoresQuery.docs.isNotEmpty) {
          print(
              '🔄 Fallback: Retornando primeiro professor da base para teste');
          var data =
              todosProfessoresQuery.docs.first.data() as Map<String, dynamic>;
          return Professor.fromMap(data, todosProfessoresQuery.docs.first.id);
        }
      }

      if (professorQuery.docs.isNotEmpty) {
        var data = professorQuery.docs.first.data() as Map<String, dynamic>;
        print('✅ Dados do professor encontrado: $data');

        return Professor.fromMap(
          data,
          professorQuery.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar professor: $e');
      return null;
    }
  }

  // Buscar alunos inscritos na disciplina
  Future<List<Student>> buscarAlunosInscritosDisciplina(
      String courseId, int courseYear) async {
    print('Buscando alunos inscritos no curso ID: $courseId, ano: $courseYear');
    final firestore = FirebaseFirestore.instance;

    final alunosSnap = await firestore
        .collection('students')
        .where('courseId', isEqualTo: courseId)
        .where('year', isEqualTo: courseYear)
        .get();
    print('Lista de alunos');
    print(alunosSnap.docs
        .map((doc) => Student.fromMap(doc.data(), doc.id))
        .toList());
    print('Lista de alunos');
    return alunosSnap.docs
        .map((doc) => Student.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Buscar materiais da disciplina
  Future<List<MaterialModel>> buscarMateriaisDaDisciplina(
      String disciplinaId, String disciplinaNome) async {
    try {
      print(
          'Buscando materiais para disciplina: $disciplinaId, nome: $disciplinaNome');

      // Verificar possíveis localizações da coleção de materiais
      List<String> possibleCollections = ['materials', 'material', 'materiais'];
      QuerySnapshot? todosMateriais;
      String? workingCollection;

      for (String collectionName in possibleCollections) {
        try {
          print('Tentando coleção: $collectionName');
          todosMateriais = await _firestore.collection(collectionName).get();
          if (todosMateriais.docs.isNotEmpty) {
            workingCollection = collectionName;
            print(
                'Coleção encontrada: $collectionName com ${todosMateriais.docs.length} documentos');
            break;
          } else {
            print('Coleção $collectionName existe mas está vazia');
          }
        } catch (e) {
          print('Coleção $collectionName não existe ou erro: $e');
        }
      }

      if (todosMateriais == null || todosMateriais.docs.isEmpty) {
        print('Nenhuma coleção de materiais encontrada ou todas estão vazias');
        return [];
      }

      // Ver alguns exemplos de dados de materiais
      for (var doc in todosMateriais.docs.take(5)) {
        var data = doc.data() as Map<String, dynamic>;
        print(
            'Exemplo de material: ${doc.id} - disciplinaId: ${data['disciplinaId']}');
      }

      // Vamos verificar todas as disciplinas disponíveis para encontrar correspondências
      print(
          'Verificando todas as disciplinas para encontrar correspondência...');
      try {
        QuerySnapshot allCourses = await _firestore.collection('courses').get();
        for (var courseDoc in allCourses.docs) {
          QuerySnapshot subjectsQuery = await _firestore
              .collection('courses')
              .doc(courseDoc.id)
              .collection('subjects')
              .get();

          for (var subjectDoc in subjectsQuery.docs) {
            var subjectData = subjectDoc.data() as Map<String, dynamic>;
            print(
                'Disciplina disponível: ${subjectDoc.id} - Nome: ${subjectData['name']} - Curso: ${courseDoc.id}');
          }
        }
      } catch (e) {
        print('Erro ao listar disciplinas: $e');
      }

      // Buscar materiais usando o ID da disciplina (que é o doc.id do subject)
      QuerySnapshot materiaisQuery = await _firestore
          .collection(workingCollection!)
          .where('disciplinaId', isEqualTo: disciplinaId)
          .get();

      print(
          'Materiais encontrados com disciplinaId "$disciplinaId": ${materiaisQuery.docs.length}');

      List<MaterialModel> materiais = [];

      for (var doc in materiaisQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Adicionar o ID ao mapa

        print('Dados do material encontrado: $data');

        materiais.add(MaterialModel.fromMap(data));
      }

      // Ordenar em memória por data de criação (mais recente primeiro)
      materiais.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));

      return materiais;
    } catch (e) {
      print('Erro ao buscar materiais: $e');
      return [];
    }
  }

  // Buscar detalhes completos da disciplina
  Future<Map<String, dynamic>> buscarDetalhesDisciplina(
      String disciplinaId, String courseId, String courseName) async {
    try {
      print('Buscando disciplina ID: $disciplinaId no curso ID: $courseId');

      // Buscar dados da disciplina
      DocumentSnapshot disciplinaDoc = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('subjects')
          .doc(disciplinaId)
          .get();

      print('Documento da disciplina existe: ${disciplinaDoc.exists}');

      if (!disciplinaDoc.exists) {
        // Tentar buscar todas as disciplinas do curso para debug
        print(
            'Disciplina não encontrada. Listando todas as disciplinas do curso...');
        QuerySnapshot allSubjects = await _firestore
            .collection('courses')
            .doc(courseId)
            .collection('subjects')
            .get();

        print('Total de disciplinas no curso: ${allSubjects.docs.length}');
        for (var doc in allSubjects.docs) {
          print('Disciplina disponível: ${doc.id} - ${doc.data()}');
        }

        throw Exception('Disciplina não encontrada');
      }

      Map<String, dynamic> disciplinaData =
          disciplinaDoc.data() as Map<String, dynamic>;

      print('Dados da disciplina: $disciplinaData');

      // Obter o courseYear da disciplina e o nome
      int courseYear = disciplinaData['courseYear'] ?? 1;
      String disciplinaNome = disciplinaData['name'] ?? '';

      print('courseId para busca de alunos: "$courseId"');
      print('courseYear para busca de alunos: $courseYear');
      print('disciplinaNome: "$disciplinaNome"');

      // Buscar professor, alunos e materiais em paralelo
      List<dynamic> results = await Future.wait([
        buscarProfessorDaDisciplina(disciplinaId, disciplinaNome),
        buscarAlunosInscritosDisciplina(courseName, courseYear),
        buscarMateriaisDaDisciplina(disciplinaId, disciplinaNome),
      ]);

      Professor? professor = results[0] as Professor?;
      List<Student> alunos = results[1] as List<Student>;
      List<MaterialModel> materiais = results[2] as List<MaterialModel>;

      return {
        'id': disciplinaId,
        'name': disciplinaData['name'] ?? '',
        'description': disciplinaData['description'] ?? '',
        'credits': disciplinaData['credits'] ?? 0,
        'courseYear': disciplinaData['courseYear'] ?? 1,
        'professor': professor,
        'students': alunos,
        'materials': materiais,
      };
    } catch (e) {
      print('Erro ao buscar detalhes da disciplina: $e');
      rethrow;
    }
  }
}
