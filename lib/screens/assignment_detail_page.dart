import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:campus_link/controllers/tarefas_controller.dart';
import 'package:campus_link/session/session.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/mobile_sidebar.dart';

class AssignmentDetailPage extends StatefulWidget {
  final Map<String, dynamic> assignment;

  const AssignmentDetailPage({super.key, required this.assignment});

  @override
  _AssignmentDetailPageState createState() => _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends State<AssignmentDetailPage> {
  String? selectedFile;
  String? selectedFilePath;
  bool hasSubmittedFile = false;
  String? submittedFileName;
  bool isCheckingSubmission = true;
  String? horaLimite; // Adicionar campo para armazenar a hora limite

  @override
  void initState() {
    super.initState();
    _checkExistingSubmission();
    _fetchHoraLimite(); // Buscar hora limite
  }

  // Função para buscar a horaLimite do Firebase
  Future<void> _fetchHoraLimite() async {
    try {
      final tarefaId = widget.assignment["id"] ?? '';
      if (tarefaId.isNotEmpty) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('tarefas')
            .doc(tarefaId)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          final horaLimiteStr = data?['horaLimite'] ?? '';

          if (horaLimiteStr.isNotEmpty) {
            setState(() {
              horaLimite = horaLimiteStr;
            });
          }
        }
      }
    } catch (e) {
      print('Erro ao buscar horaLimite: $e');
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFile = result.files.single.name;
        selectedFilePath = result.files.single.path;
      });
    }
  }

  void _clearFile() {
    setState(() {
      selectedFile = null;
      selectedFilePath = null;
    });
  }

  Future<void> _checkExistingSubmission() async {
    try {
      final tarefaId = widget.assignment["id"] ?? '';
      final alunoId = Session.currentStudent!.id;

      // Verificar se já existe uma submissão para este aluno
      final submissionInfo =
          await verificarSubmissaoExistente(tarefaId, alunoId);

      setState(() {
        hasSubmittedFile = submissionInfo != null;
        submittedFileName = submissionInfo?['fileName'];
        isCheckingSubmission = false;
      });
    } catch (e) {
      print('Erro ao verificar submissão existente: $e');
      setState(() {
        isCheckingSubmission = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignment["subject"] ?? "Detalhes do Trabalho"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/assigments_page');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.assignment["descricao"] ?? "Descrição não disponível",
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            _buildDetailRow(
              "Data de Criação",
              widget.assignment["createdDate"] ?? "N/A",
            ),
            _buildDetailRow("Prazo", widget.assignment["dueDate"] ?? "N/A"),
            // Mostrar hora limite se disponível
            if (horaLimite != null && horaLimite!.isNotEmpty)
              _buildDetailRow("Hora Limite", horaLimite!),

            _buildDetailRow("Estado",
                widget.assignment["completed"] ? "Concluído" : "Pendente"),
            _buildDetailRow(
                "Dias Restantes", widget.assignment["daysRemaining"] ?? "N/A"),
            SizedBox(height: 24),
            // Seção para ficheiros do professor
            if (widget.assignment["ficheiros"] != null &&
                widget.assignment["ficheiros"].isNotEmpty) ...[
              Text(
                "Ficheiros do Professor",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              ...widget.assignment["ficheiros"].map<Widget>((ficheiro) {
                return _buildProfessorFileCard(ficheiro);
              }).toList(),
              SizedBox(height: 24),
            ],
            // Seção para submissão do aluno
            Text(
              "Submissão do Trabalho",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (isCheckingSubmission) ...[
              Center(child: CircularProgressIndicator()),
            ] else if (hasSubmittedFile && selectedFile == null) ...[
              // Mostrar arquivo já enviado
              Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 48, color: Colors.green),
                    SizedBox(height: 8),
                    Text(
                      "Arquivo já enviado",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      submittedFileName ?? "Arquivo submetido",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          // Permite escolher um novo arquivo para reenvio
                          // Não mudamos hasSubmittedFile, apenas permitimos nova seleção
                        });
                        _pickFile(); // Chama diretamente o seletor de arquivos
                      },
                      icon: Icon(Icons.refresh),
                      label: Text("Reenviar Trabalho"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Interface para escolher arquivo (novo ou reenvio)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    selectedFile == null
                        ? Column(
                            children: [
                              Text(
                                hasSubmittedFile
                                    ? "Escolher novo documento para reenvio"
                                    : "Carregar o seu Documento",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _pickFile,
                                child: Text("Escolher Ficheiro"),
                              ),
                              if (hasSubmittedFile) ...[
                                SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedFile = null;
                                      selectedFilePath = null;
                                    });
                                  },
                                  child: Text("Cancelar reenvio"),
                                ),
                              ],
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 200,
                                child: Text(
                                  selectedFile!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                              SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.cancel, color: Colors.red),
                                onPressed: _clearFile,
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 24), // Substituir Spacer por espaçamento fixo
            if (!isCheckingSubmission &&
                (selectedFile != null || !hasSubmittedFile)) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedFile != null && selectedFilePath != null
                      ? () async {
                          final bytes =
                              await File(selectedFilePath!).readAsBytes();

                          final success = await submeterTrabalhoDoAluno(
                            tarefaId: widget.assignment["id"] ?? '',
                            alunoId: Session.currentStudent!.id,
                            fileName: selectedFile!,
                            fileBytes: bytes,
                          );

                          if (success) {
                            final wasResubmission = hasSubmittedFile;
                            setState(() {
                              hasSubmittedFile = true;
                              submittedFileName = selectedFile;
                              selectedFile = null;
                              selectedFilePath = null;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(wasResubmission
                                    ? 'Trabalho reenviado com sucesso!'
                                    : 'Trabalho submetido com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(hasSubmittedFile
                                    ? 'Erro ao reenviar o trabalho.'
                                    : 'Erro ao submeter o trabalho.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      : null,
                  child: Text(hasSubmittedFile ? "Reenviar" : "Carregar"),
                ),
              ),
            ],
            SizedBox(height: 20), // Espaçamento no final
          ],
        ),
      ),
      floatingActionButton: MobileSidebar(),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildProfessorFileCard(Map<String, dynamic> ficheiro) {
    final String nome = ficheiro['nome'] ?? 'Ficheiro sem nome';
    final String base64 = ficheiro['base64'] ?? '';
    final bool hasFile = base64.isNotEmpty;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              _getFileIcon(nome),
              size: 32,
              color: hasFile ? Colors.blue : Colors.grey,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasFile) ...[
                    SizedBox(height: 4),
                    Text(
                      'Disponível para download',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: 4),
                    Text(
                      'Ficheiro não disponível',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasFile) ...[
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _downloadProfessorFile(base64, nome),
                icon: Icon(Icons.download, size: 16),
                label: Text('Download'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final String extension = fileName.toLowerCase().split('.').last;

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _downloadProfessorFile(
      String base64Content, String fileName) async {
    try {
      if (base64Content.isEmpty) {
        _showErrorSnackBar('Ficheiro não disponível para download');
        return;
      }

      // Verificar e solicitar permissões de armazenamento
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }

      // Decodificar o conteúdo base64
      final Uint8List bytes = base64Decode(base64Content);

      // Obter o diretório de downloads
      Directory? downloadsDirectory;

      if (Platform.isAndroid) {
        downloadsDirectory = Directory('/storage/emulated/0/Download');
        if (!await downloadsDirectory.exists()) {
          downloadsDirectory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDirectory = await getApplicationDocumentsDirectory();
      }

      if (downloadsDirectory == null) {
        throw Exception('Não foi possível acessar o diretório de downloads');
      }

      // Criar o arquivo
      final String filePath = '${downloadsDirectory.path}/$fileName';
      final File file = File(filePath);

      // Escrever os bytes no arquivo
      await file.writeAsBytes(bytes);

      // Mostrar mensagem de sucesso
      if (Platform.isAndroid) {
        _showSuccessSnackBar('Ficheiro baixado em: /Download/$fileName');
      } else {
        _showSuccessSnackBar('Ficheiro salvo em: ${file.path}');
      }

      print('✅ Ficheiro do professor baixado: $filePath');
    } catch (e) {
      print('❌ Erro ao fazer download do ficheiro: $e');
      _showErrorSnackBar('Erro ao baixar ficheiro: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }
}
