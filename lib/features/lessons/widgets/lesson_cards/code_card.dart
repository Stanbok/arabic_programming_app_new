import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/lesson_model.dart';

class CodeLessonCard extends StatelessWidget {
  final LessonCard card;

  const CodeLessonCard({super.key, required this.card});

  void _copyCode(BuildContext context) {
    if (card.codeExample != null) {
      Clipboard.setData(ClipboardData(text: card.codeExample!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ الكود'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

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
          if (card.body.isNotEmpty) ...[
            Text(
              card.body,
              style: const TextStyle(
                fontSize: 16,
                height: 1.7,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (card.codeExample != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.codeBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      card.codeExample!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: IconButton(
                      onPressed: () => _copyCode(context),
                      icon: const Icon(
                        Icons.copy,
                        color: Colors.white54,
                        size: 18,
                      ),
                      tooltip: 'نسخ الكود',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
