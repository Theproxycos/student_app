class AssignmentData {
  final String subject;
  final String type;
  final String dueDate;
  final String daysRemaining;
  final bool completed;
  final String createdDate;
  final String assignmentType;
  final String descricao;
  final String id; // Optional ID field for the assignment
  final List<Map<String, dynamic>> ficheiros; // Ficheiros do professor

  AssignmentData({
    required this.subject,
    required this.type,
    required this.dueDate,
    required this.daysRemaining,
    required this.completed,
    required this.createdDate,
    required this.assignmentType,
    required this.descricao,
    required this.id,
    this.ficheiros = const [],
  });
}
