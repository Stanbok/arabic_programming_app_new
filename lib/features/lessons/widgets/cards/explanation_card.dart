import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/card_model.dart';
import '../code_block_widget.dart';

class ExplanationCard extends StatelessWidget {
  final LessonCard card;

  const ExplanationCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card.title != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      card.title!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            if (card.content != null)
              Text(
                card.content!,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: AppColors.textPrimary,
                ),
              ),
            if (card.codeBlock != null) ...[
              const SizedBox(height: 20),
              CodeBlockWidget(
                code: card.codeBlock!,
                language: card.codeLanguage ?? 'python',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
