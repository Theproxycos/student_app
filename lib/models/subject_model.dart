class Subject {
  final String id; // ID do documento no Firestore
  final String name;
  final int courseYear; // 1, 2 ou 3 (ano curricular)
  final String courseId;

  Subject({
    required this.id,
    required this.name,
    required this.courseYear,
    required this.courseId,
  });

  factory Subject.fromMap(Map<String, dynamic> data, String id) {
    return Subject(
      id: id,
      name: data['name'],
      courseYear: data['courseYear'],
      courseId: data['courseId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'courseYear': courseYear, 'courseId': courseId};
  }
}
