import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/lesson_content_model.dart';

class SummaryCard extends StatelessWidget {
  final List<ContentBlock> blocks;

  const SummaryCard({super.key, required this.blocks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card type indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.summarize_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ملخص الدرس',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Content blocks
          ...blocks.map((block) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBlock(context, block),
          )),
        ],
      ),
    );
  }

  Widget _buildBlock(BuildContext context, ContentBlock block) {
    switch (block.type) {
      case BlockType.text:
        return Text(
          block.content ?? '',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
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
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            line.replaceFirst(RegExp(r'^[-•]\s*'), ''),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        );
      
      default:
        return Text(
          block.content ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
        );
    }
  }
}
