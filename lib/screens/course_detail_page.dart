import 'package:campus_link/session/session.dart';

import '../widgets/mobile_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../controllers/disciplina_detail_controller.dart';
import '../models/professor_model.dart';
import '../models/student_model.dart';
import '../models/material_model.dart';
import '../utils/string_utils.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({super.key});

  @override
  _CourseDetailPageState createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  bool showTeachers = true;
  bool isLoading = true;
   late Student student;
  Set<String> downloadingMaterials = {}; // Track materials being downloaded

  Map<String, dynamic>? disciplinaData;
  Professor? professor;
  List<Student> students = [];
  List<MaterialModel> materials = [];

  final DisciplinaDetailController _controller = DisciplinaDetailController();

  @override
  void initState() {
    super.initState();
    student = Session.currentStudent!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDisciplinaData();
    });
  }

  Future<void> _loadDisciplinaData() async {
    try {
      final arguments =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (arguments == null) {
        throw Exception('Argumentos não encontrados');
      }

      final Map<String, dynamic> subject = arguments['subject'];
      final String courseId = arguments['courseId'];
      final String subjectId = subject['id'];

      print('Argumentos recebidos: $arguments');
      print('Subject ID: $subjectId');
      print('Course ID: $courseId');
      print('Subject data: $subject');

      final detalhes =
          await _controller.buscarDetalhesDisciplina(subjectId, courseId, student.courseId);

      setState(() {
        disciplinaData = detalhes;
        professor = detalhes['professor'];
        students = detalhes['students'];
        materials = detalhes['materials'];
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar detalhes da disciplina: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> getDownloadPath() async {
    try {
      // Tentar obter a pasta Downloads primeiro (Android)
      if (Platform.isAndroid) {
        final directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          return directory.path;
        }
      }

      // Fallback para external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        // Criar uma pasta "Downloads" dentro do diretório do app se não existir
        final downloadDir = Directory('${directory.path}/Downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir.path;
      } else {
        // Último recurso: usar o diretório de documentos da aplicação
        final appDirectory = await getApplicationDocumentsDirectory();
        final downloadDir = Directory('${appDirectory.path}/Downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir.path;
      }
    } catch (e) {
      print('Erro ao obter diretório de download: $e');
      // Fallback final
      final appDirectory = await getApplicationDocumentsDirectory();
      return appDirectory.path;
    }
  }

  Future<bool> requestStoragePermission() async {
    try {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      var status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Permissão de armazenamento é necessária para o download."),
        ),
      );

      openAppSettings();
      return false;
    } catch (e) {
      print('Erro ao solicitar permissão: $e');
      // Para plataformas que não suportam essa permissão, assumir que é permitido
      return true;
    }
  }

  Future<void> downloadFile(String url, String fileName) async {
    // Solicita a permissão antes de baixar
    bool permissionGranted = await requestStoragePermission();
    if (!permissionGranted) return;

    try {
      Dio dio = Dio();
      String dir = await getDownloadPath();
      await dio.download(url, '$dir/$fileName');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download concluído: $fileName")),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Falha no download")),
      );
    }
  }

  List<Widget> _buildTeachersList() {
    if (professor == null) {
      return [
        Center(
          child: Text(
            "Nenhum professor atribuído",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ];
    }

    return [
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[300],
          child: Text(
            professor!.nome.initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(professor!.nome),
        subtitle: Text(professor!.role),
        trailing: professor!.email.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.email),
                onPressed: () {
                  // Implementar ação de email
                },
              )
            : null,
      ),
    ];
  }

  List<Widget> _buildStudentsList() {
    if (students.isEmpty) {
      return [
        Center(
          child: Text(
            "Nenhum aluno inscrito",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ];
    }

    return students.map((student) {
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[300],
          child: Text(
            student.nome.initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(student.nome),
        subtitle: Text("Aluno - Ano ${student.year}"),
      );
    }).toList();
  }

  Widget _buildMaterialCard(MaterialModel material) {
    bool hasFile =
        material.base64Arquivo != null && material.base64Arquivo!.isNotEmpty;
    bool isDownloading = downloadingMaterials.contains(material.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com ícone e título
              GestureDetector(
                onTap: () => _showMaterialDetailModal(material),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          hasFile ? Colors.blue[400] : Colors.grey[400],
                      radius: 20,
                      child: isDownloading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              hasFile
                                  ? Icons.file_present
                                  : Icons.file_download_off,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            material.titulo,
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (material.descricao.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                material.descricao,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          // Indicador de que é clicável
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Icon(Icons.touch_app,
                                    size: 12, color: Colors.blue[400]),
                                SizedBox(width: 4),
                                Text(
                                  "Toque para ver detalhes",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[400],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // Informações do arquivo
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        "Criado: ${_formatDate(material.dataCriacao)}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (material.nomeArquivo != null &&
                      material.nomeArquivo!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            material.nomeArquivo!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (hasFile && material.base64Arquivo != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          "${_formatFileSize(_calculateBase64Size(material.base64Arquivo!))}",
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                ],
              ),

              SizedBox(height: 12),

              // Botão de download
              if (hasFile)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isDownloading
                        ? null
                        : () => _downloadMaterial(material),
                    icon: isDownloading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.download, size: 18),
                    label: Text(
                      isDownloading ? "Baixando..." : "Fazer Download",
                      style: TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDownloading ? Colors.grey : Colors.blue,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.file_download_off,
                          color: Colors.grey[600], size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Arquivo não disponível",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateBase64Size(String base64String) {
    // Calcular o tamanho aproximado do arquivo decodificado
    // Base64 adiciona ~33% de overhead, então o tamanho real é ~75% da string
    return (base64String.length * 0.75).round();
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _downloadMaterial(MaterialModel material) async {
    // Verificar se já está fazendo download
    if (downloadingMaterials.contains(material.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download já em andamento...")),
      );
      return;
    }

    setState(() {
      downloadingMaterials.add(material.id);
    });

    try {
      bool permissionGranted = await requestStoragePermission();
      if (!permissionGranted) {
        setState(() {
          downloadingMaterials.remove(material.id);
        });
        return;
      }

      // Verificar se o material tem arquivo base64
      if (material.base64Arquivo == null || material.base64Arquivo!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Material não possui arquivo para download")),
        );
        setState(() {
          downloadingMaterials.remove(material.id);
        });
        return;
      }

      // Mostrar feedback de início do download
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text("Preparando download de ${material.titulo}..."),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Decodificar o base64
      Uint8List bytes;
      try {
        bytes = base64Decode(material.base64Arquivo!);
      } catch (e) {
        print('Erro ao decodificar base64: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao processar arquivo")),
        );
        setState(() {
          downloadingMaterials.remove(material.id);
        });
        return;
      }

      // Determinar o nome do arquivo
      String fileName = material.nomeArquivo ?? '${material.titulo}.pdf';

      // Garantir que o nome do arquivo seja válido
      fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

      // Obter o diretório de download
      String dir = await getDownloadPath();
      String filePath = '$dir/$fileName';

      // Salvar o arquivo no sistema de arquivos mobile
      File file = File(filePath);
      await file.writeAsBytes(bytes);

      // Calcular tamanho do arquivo em formato legível
      String fileSize = _formatFileSize(bytes.length);

      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Download concluído: $fileName"),
              Text("Tamanho: $fileSize", style: TextStyle(fontSize: 12)),
              Text("Local: $dir", style: TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      print('Arquivo salvo em: $filePath');
      print('Tamanho do arquivo: $fileSize');
    } catch (e) {
      print('Erro no download: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro no download: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        downloadingMaterials.remove(material.id);
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showMaterialDetailModal(MaterialModel material) {
    bool hasFile =
        material.base64Arquivo != null && material.base64Arquivo!.isNotEmpty;
    bool isDownloading = downloadingMaterials.contains(material.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: 12, bottom: 8),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header da modal
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: hasFile
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).disabledColor,
                          radius: 25,
                          child: Icon(
                            hasFile
                                ? Icons.file_present
                                : Icons.file_download_off,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                material.titulo,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.color,
                                ),
                              ),
                              Text(
                                "Material da Disciplina",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close,
                              color: Theme.of(context).iconTheme.color),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1),

                  // Conteúdo scrollável
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título e descrição completa
                          if (material.descricao.isNotEmpty) ...[
                            Text(
                              "Descrição",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.color,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: Text(
                                material.descricao,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                          ],

                          // Informações do arquivo
                          Text(
                            "Informações do Material",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          SizedBox(height: 12),

                          Card(
                            elevation: 1,
                            color: Theme.of(context).cardColor,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    Icons.calendar_today,
                                    "Data de Criação",
                                    _formatDate(material.dataCriacao),
                                  ),
                                  if (material.nomeArquivo != null &&
                                      material.nomeArquivo!.isNotEmpty) ...[
                                    SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.attach_file,
                                      "Nome do Arquivo",
                                      material.nomeArquivo!,
                                    ),
                                  ],
                                  if (hasFile &&
                                      material.base64Arquivo != null) ...[
                                    SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.info_outline,
                                      "Tamanho do Arquivo",
                                      _formatFileSize(_calculateBase64Size(
                                          material.base64Arquivo!)),
                                    ),
                                  ],
                                  SizedBox(height: 12),
                                  _buildInfoRow(
                                    Icons.cloud_download,
                                    "Status",
                                    hasFile
                                        ? "Arquivo Disponível"
                                        : "Arquivo Indisponível",
                                    valueColor:
                                        hasFile ? Colors.green : Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 24),

                          // Botão de download
                          if (hasFile)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: isDownloading
                                    ? null
                                    : () {
                                        _downloadMaterial(material);
                                        Navigator.pop(context);
                                      },
                                icon: isDownloading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Icon(Icons.download, size: 20),
                                label: Text(
                                  isDownloading
                                      ? "Baixando..."
                                      : "Fazer Download do Arquivo",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isDownloading ? Colors.grey : Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .disabledColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.file_download_off,
                                      color: Theme.of(context).disabledColor,
                                      size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Arquivo não disponível para download",
                                    style: TextStyle(
                                      color: Theme.of(context).disabledColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).iconTheme.color),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ??
                      Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Carregando..."),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/course_page');
            },
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (disciplinaData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Erro"),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/course_page');
            },
          ),
        ),
        body: Center(
          child: Text(
            "Erro ao carregar detalhes da disciplina",
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    final int teachersCount = professor != null ? 1 : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(disciplinaData!["name"] ?? "Detalhes da Disciplina"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/course_page');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[300],
                  child: Icon(Icons.book, size: 30, color: Colors.white),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disciplinaData!["name"] ?? '',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        disciplinaData!["description"] ?? '',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => showTeachers = true),
                  child: Text(
                    "Professor (${teachersCount})",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: showTeachers ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => showTeachers = false),
                  child: Text(
                    "Alunos (${students.length})",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: !showTeachers ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                child: Column(
                  children: showTeachers
                      ? _buildTeachersList()
                      : _buildStudentsList(),
                ),
              ),
            ),
            Divider(height: 30),
            Text(
              "Lista de Materiais",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 14),
            Expanded(
              child: materials.isEmpty
                  ? Center(
                      child: Text(
                        "Nenhum material disponível",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: materials.length,
                      itemBuilder: (context, index) {
                        final material = materials[index];
                        return _buildMaterialCard(material);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: MobileSidebar(),
    );
  }
}
