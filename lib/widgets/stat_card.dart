import 'package:campus_link/models/student_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/theme_switcher.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Student student;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final themeSwitcher = Provider.of<ThemeSwitcher>(context);
    final isDarkMode = themeSwitcher.themeMode == ThemeMode.dark;
    return Container(
      height: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
