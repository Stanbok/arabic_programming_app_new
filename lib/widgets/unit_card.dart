import 'package:flutter/material.dart';
import '../models/lesson_model.dart';

class UnitCard extends StatelessWidget {
  final int unitNumber;
  final List<LessonModel> lessons;
  final bool isUnlocked;
  final bool isCompleted;
  final VoidCallback? onTap;

  const UnitCard({
    Key? key,
    required this.unitNumber,
    required this.lessons,
    required this.isUnlocked,
    required this.isCompleted,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Unit completion indicator
          if (isCompleted)
            Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.star,
                color: Colors.amber,
                size: 32,
              ),
            ),
          
          // Unit card
          Card(
            elevation: isUnlocked ? 4 : 2,
            color: isUnlocked ? Colors.white : Colors.grey[300],
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الوحدة $unitNumber',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${lessons.length} دروس',
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnlocked ? Colors.grey[600] : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Lessons list
                  ...lessons.map((lesson) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: isUnlocked ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lesson.title,
                            style: TextStyle(
                              fontSize: 14,
                              color: isUnlocked ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
