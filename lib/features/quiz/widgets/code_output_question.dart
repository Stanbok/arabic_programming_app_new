import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CodeOutputQuestion extends StatefulWidget {
  final String codeSnippet;
  final String expectedOutput;
  final List<String> options;
  final int correctIndex;
  final bool enabled;
  final void Function(bool isCorrect) onAnswer;

  const CodeOutputQuestion({
    super.key,
    required this.codeSnippet,
    required this.expectedOutput,
    required this.options,
    required this.correctIndex,
    required this.enabled,
    required this.onAnswer,
  });

  @override
  State<CodeOutputQuestion> createState() => _CodeOutputQuestionState();
}

class _CodeOutputQuestionState extends State<CodeOutputQuestion> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Code snippet
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.codeBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            widget.codeSnippet,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: AppColors.codeText,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        Text(
          'ما هو ناتج هذا الكود؟',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Options
        ...List.generate(widget.options.length, (index) {
          final isSelected = _selectedIndex == index;
          final isCorrect = index == widget.correctIndex;
          final showResult = !widget.enabled;

          Color getBorderColor() {
            if (!showResult) {
              return isSelected ? AppColors.primary : AppColors.dividerLight;
            }
            if (isCorrect) return AppColors.success;
            if (isSelected && !isCorrect) return AppColors.error;
            return AppColors.dividerLight;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: widget.enabled ? () => setState(() => _selectedIndex = index) : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected || (showResult && isCorrect)
                      ? getBorderColor().withOpacity(0.1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: getBorderColor()),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.codeBackground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.options[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: AppColors.codeText,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (showResult && isCorrect)
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    if (showResult && isSelected && !isCorrect)
                      const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
        
        const SizedBox(height: 16),
        if (widget.enabled && _selectedIndex != null)
          ElevatedButton(
            onPressed: () => widget.onAnswer(_selectedIndex == widget.correctIndex),
            child: const Text('تأكيد الإجابة'),
          ),
      ],
    );
  }
}
