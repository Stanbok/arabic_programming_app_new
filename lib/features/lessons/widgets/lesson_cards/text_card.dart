import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/lesson_model.dart';

class TextLessonCard extends StatelessWidget {
  final LessonCard card;

  const TextLessonCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            card.body,
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
              color: AppColors.textPrimary,
            ),
          ),
          if (card.bulletPoints != null && card.bulletPoints!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...card.bulletPoints!.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}
