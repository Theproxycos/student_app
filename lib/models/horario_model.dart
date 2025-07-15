class Aula {
  final String disciplina;
  final String diaSemana;
  final String horaInicio;
  final String horaFim;

  Aula({
    required this.disciplina,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFim,
  });

  Map<String, dynamic> toMap() {
    return {
      'disciplina': disciplina,
      'diaSemana': diaSemana,
      'horaInicio': horaInicio,
      'horaFim': horaFim,
    };
  }

  factory Aula.fromMap(Map<String, dynamic> map) {
    return Aula(
      disciplina: map['disciplina'] ?? '',
      diaSemana: map['diaSemana'] ?? '',
      horaInicio: map['horaInicio'] ?? '',
      horaFim: map['horaFim'] ?? '',
    );
  }
}

class Horario {
  final String id;
  final String courseId;
  final int year;
  final List<Aula> aulas;

  Horario({
    required this.id,
    required this.courseId,
    required this.year,
    required this.aulas,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'year': year,
      'aulas': aulas.map((aula) => aula.toMap()).toList(),
    };
  }

  factory Horario.fromMap(String id, Map<String, dynamic> map, int year) {
    List<Aula> aulasList = [];

    // Buscar as aulas do ano específico
    if (map['aulasPorAno'] != null &&
        map['aulasPorAno'][year.toString()] != null) {
      List<dynamic> aulasData = map['aulasPorAno'][year.toString()];
      aulasList = aulasData.map((aulaMap) => Aula.fromMap(aulaMap)).toList();
    }

    return Horario(
      id: id,
      courseId: map['courseId'] ?? '',
      year: year,
      aulas: aulasList,
    );
  }

  // Agrupar aulas por dia da semana
  Map<String, List<Aula>> get aulasPorDia {
    Map<String, List<Aula>> grouped = {};
    for (Aula aula in aulas) {
      if (!grouped.containsKey(aula.diaSemana)) {
        grouped[aula.diaSemana] = [];
      }
      grouped[aula.diaSemana]!.add(aula);
    }

    // Ordenar por hora de início
    grouped.forEach((dia, aulasDay) {
      aulasDay.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
    });

    return grouped;
  }
}
