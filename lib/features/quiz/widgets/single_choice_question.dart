import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class SingleChoiceQuestion extends StatefulWidget {
  final List<String> options;
  final int correctIndex;
  final bool enabled;
  final void Function(bool isCorrect) onAnswer;

  const SingleChoiceQuestion({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.enabled,
    required this.onAnswer,
  });

  @override
  State<SingleChoiceQuestion> createState() => _SingleChoiceQuestionState();
}

class _SingleChoiceQuestionState extends State<SingleChoiceQuestion> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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

          Color? getBackgroundColor() {
            if (!showResult) {
              return isSelected ? AppColors.primary.withOpacity(0.1) : null;
            }
            if (isCorrect) return AppColors.success.withOpacity(0.1);
            if (isSelected && !isCorrect) return AppColors.error.withOpacity(0.1);
            return null;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: widget.enabled ? () => _selectOption(index) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: getBackgroundColor(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: getBorderColor(),
                    width: isSelected || (showResult && isCorrect) ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: getBorderColor(),
                          width: 2,
                        ),
                        color: isSelected ? getBorderColor() : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.options[index],
                        style: Theme.of(context).textTheme.bodyLarge,
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmAnswer,
              child: const Text('تأكيد الإجابة'),
            ),
          ),
      ],
    );
  }

  void _selectOption(int index) {
    setState(() => _selectedIndex = index);
  }

  void _confirmAnswer() {
    if (_selectedIndex != null) {
      widget.onAnswer(_selectedIndex == widget.correctIndex);
    }
  }
}
