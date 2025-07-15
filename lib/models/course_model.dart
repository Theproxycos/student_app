import '../models/subject_model.dart';

class Course {
  final String id;
  final String name;
  final List<Subject>? subjects;

  Course({required this.id, required this.name,this.subjects,});

  factory Course.fromMap(Map<String, dynamic> data, String id) {
    return Course(id: id, name: data['name']);
  }

  Map<String, dynamic> toMap() {
    return {'name': name};
  }
}
