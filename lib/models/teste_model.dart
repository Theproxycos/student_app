import 'package:intl/intl.dart';

class TesteModel {
  final String id;
  final String nome; // "Teste 1", "Teste 2", etc.
  final String disciplinaId;
  final String professorId;
  final DateTime dataHora;

  TesteModel({
    required this.id,
    required this.nome,
    required this.disciplinaId,
    required this.professorId,
    required this.dataHora,
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

  // Verificar se já passou
  bool get jaPasso {
    return dataHora.isBefore(DateTime.now());
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'disciplinaId': disciplinaId,
      'professorId': professorId,
      'dataHora': dataHora.millisecondsSinceEpoch,
    };
  }

  factory TesteModel.fromMap(Map<String, dynamic> map) {
    try {
      // Debug: imprimir os dados recebidos
      print('Debug TesteModel.fromMap - Map: $map');

      DateTime dataHora;

      // Tratar diferentes tipos de data
      if (map['dataHora'] is String) {
        dataHora = DateTime.parse(map['dataHora']);
      } else if (map['dataHora'] is int) {
        dataHora = DateTime.fromMillisecondsSinceEpoch(map['dataHora']);
      } else if (map['dataHora'] != null &&
          map['dataHora'].toString().contains('Timestamp')) {
        // Firestore Timestamp
        var timestamp = map['dataHora'];
        dataHora = timestamp.toDate();
      } else if (map['dataHora'] != null) {
        // Tentar converter para int se for outro tipo
        dataHora = DateTime.fromMillisecondsSinceEpoch(
            int.parse(map['dataHora'].toString()));
      } else {
        dataHora = DateTime.now(); // Fallback
      }

      return TesteModel(
        id: map['id']?.toString() ?? '',
        nome: map['nome']?.toString() ?? '',
        disciplinaId: map['disciplinaId']?.toString() ?? '',
        professorId: map['professorId']?.toString() ?? '',
        dataHora: dataHora,
      );
    } catch (e) {
      print('Erro ao criar TesteModel a partir do map: $e');
      print('Map problemático: $map');
      rethrow;
    }
  }

  TesteModel copyWith({
    String? id,
    String? nome,
    String? disciplinaId,
    String? professorId,
    DateTime? dataHora,
  }) {
    return TesteModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      disciplinaId: disciplinaId ?? this.disciplinaId,
      professorId: professorId ?? this.professorId,
      dataHora: dataHora ?? this.dataHora,
    );
  }

  @override
  String toString() {
    return 'TesteModel(id: $id, nome: $nome, disciplinaId: $disciplinaId, professorId: $professorId, dataHora: $dataHora)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TesteModel &&
        other.id == id &&
        other.nome == nome &&
        other.disciplinaId == disciplinaId &&
        other.professorId == professorId &&
        other.dataHora == dataHora;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nome.hashCode ^
        disciplinaId.hashCode ^
        professorId.hashCode ^
        dataHora.hashCode;
  }
}
