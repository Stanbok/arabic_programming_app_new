import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/lesson_model.dart';

class MixedLessonCard extends StatelessWidget {
  final LessonCard card;

  const MixedLessonCard({super.key, required this.card});

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
          Text(
            card.body,
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
              color: AppColors.textPrimary,
            ),
          ),
          if (card.codeExample != null) ...[
            const SizedBox(height: 16),
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
                    ),
                  ),
                ],
              ),
            ),
          ],
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
