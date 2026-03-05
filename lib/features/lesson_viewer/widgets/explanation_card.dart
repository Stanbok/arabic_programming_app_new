import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/lesson_content_model.dart';
import 'code_block_widget.dart';
import 'image_block_widget.dart';
import 'video_block_widget.dart';

class ExplanationCard extends StatelessWidget {
  final List<ContentBlock> blocks;

  const ExplanationCard({super.key, required this.blocks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card type indicator
        _buildTypeChip(context),
        const SizedBox(height: 16),
        
        // Content blocks
        ...blocks.map((block) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildBlock(context, block),
        )),
      ],
    );
  }

  Widget _buildTypeChip(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_rounded, color: AppColors.primary, size: 16),
            SizedBox(width: 6),
            Text(
              'شرح',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlock(BuildContext context, ContentBlock block) {
    switch (block.type) {
      case BlockType.text:
        return Text(
          block.content ?? '',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
        );
      
      case BlockType.code:
        return CodeBlockWidget(
          code: block.content ?? '',
          language: block.language,
        );
      
      case BlockType.bullets:
        final items = block.items ?? block.content?.split('\n') ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .where((line) => line.trim().isNotEmpty)
              .map((line) => Padding(
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
                            line.replaceFirst(RegExp(r'^[-•]\s*'), ''),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        );
      
      case BlockType.note:
        return _buildInfoBox(
          context,
          block.content ?? '',
          AppColors.secondary,
          Icons.info_outline_rounded,
          'ملاحظة',
        );
      
      case BlockType.warning:
        return _buildInfoBox(
          context,
          block.content ?? '',
          AppColors.warning,
          Icons.warning_amber_rounded,
          'تحذير',
        );
      
      case BlockType.hint:
        return _buildInfoBox(
          context,
          block.content ?? '',
          AppColors.accent,
          Icons.lightbulb_outline_rounded,
          'تلميح',
        );
      
      case BlockType.image:
        if (block.url != null) {
          return ImageBlockWidget(
            url: block.url!,
            caption: block.caption,
          );
        }
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.dividerLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.image_rounded, size: 48, color: AppColors.locked),
          ),
        );
      
      case BlockType.video:
        if (block.url != null) {
          return VideoBlockWidget(
            url: block.url!,
            caption: block.caption,
            thumbnail: block.thumbnail,
          );
        }
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.dividerLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.videocam_off_rounded, size: 48, color: AppColors.locked),
          ),
        );
    }
  }

  Widget _buildInfoBox(
    BuildContext context,
    String content,
    Color color,
    IconData icon,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
