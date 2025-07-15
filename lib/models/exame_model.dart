import 'package:intl/intl.dart';

class ExameModel {
  final String id;
  final String subjectId; // ID da disciplina
  final String disciplinaNome; // Nome da disciplina
  final String professorId;
  final String tipo; // 'Recurso', 'Época Especial', 'Época Normal'
  final DateTime dataHora;
  final String? observacoes;

  ExameModel({
    required this.id,
    required this.subjectId,
    required this.disciplinaNome,
    required this.professorId,
    required this.tipo,
    required this.dataHora,
    this.observacoes,
  });

  // Formatação da data para exibição
  String get dataFormatada {
    return DateFormat('dd/MM/yyyy').format(dataHora);
  }

  // Formatação do horário para exibição
  String get horarioFormatado {
    return DateFormat('HH:mm').format(dataHora);
  }

  // Data e hora juntas formatadas
  String get dataHoraFormatada {
    return DateFormat('dd/MM/yyyy HH:mm').format(dataHora);
  }

  // Verificar se é hoje
  bool get isHoje {
    final hoje = DateTime.now();
    return dataHora.year == hoje.year &&
        dataHora.month == hoje.month &&
        dataHora.day == hoje.day;
  }

  // Verificar se é amanhã
  bool get isAmanha {
    final amanha = DateTime.now().add(Duration(days: 1));
    return dataHora.year == amanha.year &&
        dataHora.month == amanha.month &&
        dataHora.day == amanha.day;
  }

  // Verificar se já passou
  bool get jaPasso {
    return dataHora.isBefore(DateTime.now());
  }

  // Dias restantes até o exame
  int get diasRestantes {
    final agora = DateTime.now();
    final diferenca = dataHora.difference(agora);
    return diferenca.inDays;
  }

  // Status do exame baseado na data
  String get status {
    if (jaPasso) return 'Concluído';
    if (isHoje) return 'Hoje';
    if (isAmanha) return 'Amanhã';
    if (diasRestantes > 0) return '${diasRestantes} dias';
    return 'Hoje';
  }

  // Cor baseada no tipo de exame
  String get corTipo {
    switch (tipo.toLowerCase()) {
      case 'época normal':
        return 'blue';
      case 'época especial':
        return 'orange';
      case 'recurso':
        return 'red';
      default:
        return 'grey';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'disciplinaNome': disciplinaNome,
      'professorId': professorId,
      'tipo': tipo,
      'dataHora': dataHora.toIso8601String(),
      'observacoes': observacoes,
    };
  }

  factory ExameModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ExameModel(
      id: id,
      subjectId: data['subjectId'] ?? '',
      disciplinaNome: data['disciplinaNome'] ?? '',
      professorId: data['professorId'] ?? '',
      tipo: data['tipo'] ?? '',
      dataHora: data['dataHora'] is String
          ? DateTime.parse(data['dataHora'])
          : DateTime.fromMillisecondsSinceEpoch(data['dataHora'] ?? 0),
      observacoes: data['observacoes'],
    );
  }

  ExameModel copyWith({
    String? id,
    String? subjectId,
    String? disciplinaNome,
    String? professorId,
    String? tipo,
    DateTime? dataHora,
    String? observacoes,
  }) {
    return ExameModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      disciplinaNome: disciplinaNome ?? this.disciplinaNome,
      professorId: professorId ?? this.professorId,
      tipo: tipo ?? this.tipo,
      dataHora: dataHora ?? this.dataHora,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  @override
  String toString() {
    return 'ExameModel(id: $id, disciplina: $disciplinaNome, tipo: $tipo, data: $dataFormatada, hora: $horarioFormatado)';
  }
}
