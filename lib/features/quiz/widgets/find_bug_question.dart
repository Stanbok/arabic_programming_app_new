import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class FindBugQuestion extends StatefulWidget {
  final String buggyCode;
  final List<String> options;
  final int correctIndex;
  final bool enabled;
  final void Function(bool isCorrect) onAnswer;

  const FindBugQuestion({
    super.key,
    required this.buggyCode,
    required this.options,
    required this.correctIndex,
    required this.enabled,
    required this.onAnswer,
  });

  @override
  State<FindBugQuestion> createState() => _FindBugQuestionState();
}

class _FindBugQuestionState extends State<FindBugQuestion> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bug indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bug_report_rounded, color: AppColors.warning, size: 18),
              SizedBox(width: 6),
              Text(
                'الكود التالي يحتوي على خطأ',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Buggy code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.codeBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withOpacity(0.5)),
          ),
          child: SelectableText(
            widget.buggyCode,
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
          'ما هو الخطأ في هذا الكود؟',
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
                    Expanded(
                      child: Text(
                        widget.options[index],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
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
