class Professor {
  final String id;
  final String nome;
  final String email;
  final String codigoPostal;
  final String dataNascimento;
  final List<String> disciplinas;
  final String distrito;
  final String iban;
  final String morada;
  final String nacionalidade;
  final String nif;
  final String password;

  Professor({
    required this.id,
    required this.nome,
    required this.email,
    required this.codigoPostal,
    required this.dataNascimento,
    required this.disciplinas,
    required this.distrito,
    required this.iban,
    required this.morada,
    required this.nacionalidade,
    required this.nif,
    required this.password,
  });

  String get role => 'Professor';

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'codigoPostal': codigoPostal,
      'dataNascimento': dataNascimento,
      'disciplinas': disciplinas,
      'distrito': distrito,
      'iban': iban,
      'morada': morada,
      'nacionalidade': nacionalidade,
      'nif': nif,
      'password': password,
    };
  }

  factory Professor.fromMap(Map<String, dynamic> data, String id) {
    return Professor(
      id: id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      codigoPostal: data['codigoPostal'] ?? '',
      dataNascimento: data['dataNascimento'] ?? '',
      disciplinas: List<String>.from(data['disciplinas'] ?? []),
      distrito: data['distrito'] ?? '',
      iban: data['iban'] ?? '',
      morada: data['morada'] ?? '',
      nacionalidade: data['nacionalidade'] ?? '',
      nif: data['nif'] ?? '',
      password: data['password'] ?? '',
    );
  }
}
