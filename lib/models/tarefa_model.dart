class TarefaModel {
  final String id;
  final String titulo;
  final String descricao;
  final String disciplinaId;
  final String professorId;
  final DateTime dataLimite;
  final DateTime dataPublicacao;
  final List<String> ficheiros; // nomes dos arquivos
  final Map<String, bool> entregas; // alunoId/nome : entregue
  final String horaLimite; // formato HH:mm

  TarefaModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.disciplinaId,
    required this.professorId,
    required this.dataLimite,
    required this.dataPublicacao,
    required this.ficheiros,
    required this.entregas,
    required this.horaLimite,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'disciplinaId': disciplinaId,
      'professorId': professorId,
      'dataLimite': dataLimite.toIso8601String(),
      'dataPublicacao': dataPublicacao.toIso8601String(),
      'ficheiros': ficheiros,
      'entregas': entregas,
      'horaLimite': horaLimite,
    };
  }

  factory TarefaModel.fromMap(Map<String, dynamic> map) {
    try {
      // Debug: imprimir os dados recebidos
      print('Debug TarefaModel.fromMap - Map: $map');

      return TarefaModel(
        id: map['id']?.toString() ?? '',
        titulo: map['titulo']?.toString() ?? '',
        descricao: map['descricao']?.toString() ?? '',
        disciplinaId: map['disciplinaId']?.toString() ?? '',
        professorId: map['professorId']?.toString() ?? '',
        dataLimite: DateTime.parse(
            map['dataLimite']?.toString() ?? DateTime.now().toIso8601String()),
        dataPublicacao: map['dataPublicacao'] != null
            ? DateTime.parse(map['dataPublicacao']?.toString() ??
                DateTime.now().toIso8601String())
            : DateTime.now(),
        ficheiros:
            map['ficheiros'] != null ? List<String>.from(map['ficheiros']) : [],
        entregas: map['entregas'] != null
            ? Map<String, bool>.from(map['entregas'])
            : {},
        horaLimite: map['horaLimite']?.toString() ?? '23:59',
      );
    } catch (e) {
      print('Erro ao criar TarefaModel a partir do map: $e');
      print('Map problemático: $map');
      rethrow;
    }
  }
}
