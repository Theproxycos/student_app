import 'package:flutter/material.dart';

class AssignmentCard extends StatelessWidget {
  final String subject;
  final String date;
  final String subjectType;
  final bool isUrgent;
  final VoidCallback? onTap;

  const AssignmentCard({
    super.key,
    required this.subject,
    required this.date,
    required this.subjectType,
    this.isUrgent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 71,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isUrgent ? Colors.red[300] : Colors.green[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              subject,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              subjectType,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              date,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
