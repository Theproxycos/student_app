import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../widgets/mobile_sidebar.dart';
import '../controllers/notas_controller.dart';
import '../session/session.dart';

class GradesPageDetail extends StatefulWidget {
  final Subject subject;

  const GradesPageDetail({super.key, required this.subject});

  @override
  _GradesPageDetailState createState() => _GradesPageDetailState();
}

class _GradesPageDetailState extends State<GradesPageDetail> {
  bool _isTestsExpanded = true;
  bool _isAssignmentsExpanded = true;

  List<Map<String, dynamic>> _testes = [];
  List<Map<String, dynamic>> _tarefas = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarNotas();
  }

  Future<void> _carregarNotas() async {
    try {
      final studentEmail = Session.currentStudent?.userId;
      if (studentEmail == null) {
        print("Nenhum estudante na sessão!");
        setState(() {
          _loading = false;
        });
        return;
      }

      // Buscar o documento do aluno com base no email
      final snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('userId', isEqualTo: studentEmail)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print("Aluno não encontrado!");
        setState(() {
          _loading = false;
        });
        return;
      }

      final alunoId = snapshot.docs.first.id; // <- Aqui está o alunoId correto
      final disciplinaId = widget.subject.id;

      print("Carregando notas para aluno: $alunoId, disciplina: $disciplinaId");

      final testes =
          await NotaController().getTestesComNotas(disciplinaId, alunoId);
      final tarefas =
          await NotaController().getTarefasComNotas(disciplinaId, alunoId);

      print("Testes com notas encontrados: ${testes.length}");
      print("Tarefas com notas encontradas: ${tarefas.length}");

      setState(() {
        _testes = testes;
        _tarefas = tarefas;
        _loading = false;
      });
    } catch (e) {
      print("Erro ao carregar notas: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando notas...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGradeSection(
                      title: "Testes",
                      isExpanded: _isTestsExpanded,
                      onToggle: () {
                        setState(() => _isTestsExpanded = !_isTestsExpanded);
                      },
                      content: _testes.isEmpty
                          ? Container(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Nenhum teste com nota encontrado.',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Column(
                              children: _testes
                                  .map((t) => _buildGradeItem(
                                      t['nome'] ?? 'Nome não disponível',
                                      t['nota']?.toString() ?? '0'))
                                  .toList(),
                            ),
                    ),
                    SizedBox(height: 20),
                    _buildGradeSection(
                      title: "Trabalhos",
                      isExpanded: _isAssignmentsExpanded,
                      onToggle: () {
                        setState(() =>
                            _isAssignmentsExpanded = !_isAssignmentsExpanded);
                      },
                      content: _tarefas.isEmpty
                          ? Container(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Nenhum trabalho com nota encontrado.',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Column(
                              children: _tarefas
                                  .map((t) => _buildGradeItem(
                                      t['titulo'] ?? 'Título não disponível',
                                      t['nota']?.toString() ?? '0'))
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: MobileSidebar(),
    );
  }

  Widget _buildGradeSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget content,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        title == "Testes" ? Icons.quiz : Icons.assignment,
                        color: Colors.blue,
                        size: 20.0,
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.blue,
                    ),
                    onPressed: onToggle,
                  ),
                ],
              ),
              if (isExpanded) ...[
                SizedBox(height: 12),
                content,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeItem(String name, String score) {
    // Determinar cor da nota
    double? nota = double.tryParse(score);
    Color scoreColor = Colors.white;
    Color scoreBgColor = Colors.grey;

    if (nota != null) {
      if (nota >= 14) {
        scoreBgColor = Colors.green[600]!;
      } else if (nota >= 10) {
        scoreBgColor = Colors.orange[600]!;
      } else {
        scoreBgColor = Colors.red[600]!;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.0),
      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: scoreBgColor,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              score,
              style: TextStyle(
                fontSize: 14,
                color: scoreColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
