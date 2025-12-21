import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CodeChoiceQuestion extends StatefulWidget {
  final List<String> options;
  final int correctIndex;
  final bool enabled;
  final void Function(bool isCorrect) onAnswer;

  const CodeChoiceQuestion({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.enabled,
    required this.onAnswer,
  });

  @override
  State<CodeChoiceQuestion> createState() => _CodeChoiceQuestionState();
}

class _CodeChoiceQuestionState extends State<CodeChoiceQuestion> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'اختر الكود الصحيح:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
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
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: widget.enabled ? () => setState(() => _selectedIndex = index) : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.codeBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: getBorderColor(),
                    width: isSelected || (showResult && isCorrect) ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.options[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: AppColors.codeText,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    if (showResult && isCorrect)
                      const Icon(Icons.check_circle_rounded, color: AppColors.success),
                    if (showResult && isSelected && !isCorrect)
                      const Icon(Icons.cancel_rounded, color: AppColors.error),
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
