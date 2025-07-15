import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/theme_switcher.dart';

class ClassCard extends StatelessWidget {
  final String className;
  final String time;
  final String duration;

  const ClassCard({
    super.key,
    required this.className,
    required this.time,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final themeSwitcher = Provider.of<ThemeSwitcher>(context);
    final isDarkMode = themeSwitcher.themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            className,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.blue,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time,
                  style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black)),
              Text(duration,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
