import 'package:flutter/material.dart';
import '../../models/lesson_block_model.dart';

class TextBlockWidget extends StatelessWidget {
  final LessonBlockModel block;

  const TextBlockWidget({
    Key? key,
    required this.block,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = block.content['text'] as String;
    final imageUrl = block.content['imageUrl'] as String?;
    final blockStyle = block.content['style'] as String? ?? 'normal';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBlockHeader(context, blockStyle),
            const SizedBox(height: 16),
            
            // محتوى النص
            Text(
              content,
              style: _getTextStyle(context, blockStyle),
            ),
            
            // صورة اختيارية
            if (imageUrl != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBlockHeader(BuildContext context, String blockStyle) {
    IconData icon;
    Color color;
    String label;

    switch (blockStyle) {
      case 'explanation':
        icon = Icons.lightbulb_outline;
        color = Colors.blue;
        label = 'شرح';
        break;
      case 'note':
        icon = Icons.note_outlined;
        color = Colors.orange;
        label = 'ملاحظة';
        break;
      case 'fun_fact':
        icon = Icons.star_outline;
        color = Colors.purple;
        label = 'معلومة ممتعة';
        break;
      case 'summary':
        icon = Icons.summarize_outlined;
        color = Colors.green;
        label = 'ملخص';
        break;
      default:
        icon = Icons.article_outlined;
        color = Colors.grey;
        label = 'نص';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _getTextStyle(BuildContext context, String blockStyle) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge!;
    
    switch (blockStyle) {
      case 'explanation':
        return baseStyle.copyWith(
          fontSize: 16,
          height: 1.6,
        );
      case 'note':
        return baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: Colors.orange.shade700,
        );
      case 'fun_fact':
        return baseStyle.copyWith(
          fontWeight: FontWeight.w500,
          color: Colors.purple.shade700,
        );
      case 'summary':
        return baseStyle.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        );
      default:
        return baseStyle;
    }
  }
}
