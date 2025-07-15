import '../widgets/mobile_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session/session.dart';
import '../controllers/disciplinas_controller.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  _CoursePageState createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  String selectedYear = "Todos";
  List<Map<String, dynamic>> studentSubjects = [];
  bool isLoading = true;
  String? studentYear;
  String?
      actualCourseId; // Adicionar variável para armazenar o ID real do curso

  @override
  void initState() {
    super.initState();
    if (Session.currentStudent != null) {
      _loadStudentData();
    }
  }

  Future<void> _loadStudentData() async {
    if (Session.currentStudent == null) return;

    try {
      // Buscar dados do estudante usando o ID da sessão
      String studentId = Session.currentStudent!.id;
      print('Carregando dados para o estudante: $studentId');

      // Buscar dados do estudante
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();

      if (studentDoc.exists) {
        Map<String, dynamic> studentData =
            studentDoc.data() as Map<String, dynamic>;
        int anoAluno = studentData['year'] ?? 3;
        studentYear = anoAluno.toString();
        print('Ano do estudante: $anoAluno');

        // Buscar o nome do curso
        String courseId = studentData['courseId'] ?? 'engenharia_informatica';
        print('Course ID: $courseId');

        // Buscar o documento do curso pelo nome (não pelo ID)
        QuerySnapshot coursesQuery = await FirebaseFirestore.instance
            .collection('courses')
            .where('name', isEqualTo: courseId)
            .get();

        DocumentSnapshot? courseDoc;
        String actualCourseId = '';

        if (coursesQuery.docs.isNotEmpty) {
          courseDoc = coursesQuery.docs.first;
          actualCourseId = courseDoc.id;
        } else {
          // Se não encontrar pelo nome exato, tentar buscar por todos os cursos
          print(
              'Curso não encontrado pelo nome "$courseId". Buscando todos os cursos...');
          QuerySnapshot allCourses =
              await FirebaseFirestore.instance.collection('courses').get();

          for (var doc in allCourses.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            print('Curso disponível: ${data['name']} (ID: ${doc.id})');

            // Tentar match case-insensitive
            if (data['name'].toString().toLowerCase() ==
                courseId.toLowerCase()) {
              courseDoc = doc;
              actualCourseId = doc.id;
              break;
            }
          }
        }

        if (courseDoc != null && courseDoc.exists) {
          Map<String, dynamic> courseData =
              courseDoc.data() as Map<String, dynamic>;
          String nomeCurso = courseData['name'] ?? 'Engenharia Informática';
          print('Nome do curso: $nomeCurso');
          print('ID real do curso (actualCourseId): $actualCourseId');

          // Usar o controller para buscar as disciplinas do curso e ano específicos
          QuerySnapshot subjectsSnapshot = await FirebaseFirestore.instance
              .collection('courses')
              .doc(actualCourseId)
              .collection('subjects')
              .where('courseYear', isEqualTo: anoAluno)
              .get();

          print(
              'Número de disciplinas encontradas: ${subjectsSnapshot.docs.length}');

          // Se não encontrar disciplinas com filtro de ano, tentar buscar todas
          if (subjectsSnapshot.docs.isEmpty) {
            print(
                'Nenhuma disciplina encontrada com filtro de ano. Buscando todas...');
            QuerySnapshot allSubjectsSnapshot = await FirebaseFirestore.instance
                .collection('courses')
                .doc(actualCourseId)
                .collection('subjects')
                .get();

            print(
                'Total de disciplinas no curso (sem filtro): ${allSubjectsSnapshot.docs.length}');

            // Mostrar estrutura das disciplinas encontradas
            for (var doc in allSubjectsSnapshot.docs) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              print(
                  'Disciplina: ${data['name']} - courseYear: ${data['courseYear']} (tipo: ${data['courseYear'].runtimeType})');
            }

            // Usar todas as disciplinas se não conseguir filtrar
            subjectsSnapshot = allSubjectsSnapshot;
          }

          List<Map<String, dynamic>> subjects = [];
          for (var doc in subjectsSnapshot.docs) {
            Map<String, dynamic> subjectData =
                doc.data() as Map<String, dynamic>;
            subjectData['id'] = doc.id;
            subjects.add(subjectData);
            print(
                'Disciplina encontrada: ${subjectData['name']} - Ano: ${subjectData['courseYear']}');
          }

          // Contar disciplinas usando o controller
          int totalDisciplinas =
              await contarDisciplinasDoAluno(nomeCurso, anoAluno);
          print(
              'Total de disciplinas do ano $anoAluno (via controller): $totalDisciplinas');

          setState(() {
            studentSubjects = subjects;
            isLoading = false;
            this.actualCourseId =
                actualCourseId; // Armazenar o ID real do curso
          });
        } else {
          print('Curso não encontrado: $courseId');
          print('Tentando listar todos os cursos disponíveis...');

          QuerySnapshot allCourses =
              await FirebaseFirestore.instance.collection('courses').get();

          print('Cursos disponíveis no Firebase:');
          for (var doc in allCourses.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            print('- ${data['name']} (ID: ${doc.id})');
          }

          setState(() {
            isLoading = false;
          });
        }
      } else {
        print('Estudante não encontrado: $studentId');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar dados: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Disciplinas"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ano Letivo: ${studentYear ?? 'N/A'}",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Disciplinas do Curso",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: studentSubjects.isEmpty
                        ? Center(
                            child: Text(
                              "Nenhuma disciplina encontrada",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: studentSubjects.length,
                            itemBuilder: (context, index) {
                              final subject = studentSubjects[index];
                              return _buildSubjectCard(subject);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: MobileSidebar(),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          // Navegar para CourseDetailPage com os dados da disciplina
          Navigator.pushNamed(
            context,
            '/course_detail_page',
            arguments: {
              'subject': subject,
              'courseId': actualCourseId ?? '', // Usar o ID real do curso
            },
          );
        },
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject["name"] ?? 'Nome da Disciplina',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subject["description"] != null) ...[
                  SizedBox(height: 8),
                  Text(
                    subject["description"],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.class_, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      "Ano ${subject['courseYear'] ?? studentYear ?? 'N/A'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 16),
                    if (subject["credits"] != null) ...[
                      Icon(Icons.credit_card, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        "${subject['credits']} ECTS",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
