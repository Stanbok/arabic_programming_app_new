import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class TrueFalseQuestion extends StatefulWidget {
  final bool? correctAnswer;
  final bool enabled;
  final void Function(bool isCorrect) onAnswer;

  const TrueFalseQuestion({
    super.key,
    required this.correctAnswer,
    required this.enabled,
    required this.onAnswer,
  });

  @override
  State<TrueFalseQuestion> createState() => _TrueFalseQuestionState();
}

class _TrueFalseQuestionState extends State<TrueFalseQuestion> {
  bool? _selectedAnswer;

  bool get _correctAnswer => widget.correctAnswer ?? false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOption(
                context,
                value: true,
                label: 'صح',
                icon: Icons.check_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOption(
                context,
                value: false,
                label: 'خطأ',
                icon: Icons.close_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (widget.enabled && _selectedAnswer != null)
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

  Widget _buildOption(
    BuildContext context, {
    required bool value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedAnswer == value;
    final isCorrect = value == _correctAnswer;
    final showResult = !widget.enabled;

    Color getColor() {
      if (!showResult) {
        return isSelected ? AppColors.primary : AppColors.dividerLight;
      }
      if (isCorrect) return AppColors.success;
      if (isSelected && !isCorrect) return AppColors.error;
      return AppColors.dividerLight;
    }

    return GestureDetector(
      onTap: widget.enabled ? () => setState(() => _selectedAnswer = value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: isSelected || (showResult && isCorrect)
              ? getColor().withOpacity(0.1)
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: getColor(),
            width: isSelected || (showResult && isCorrect) ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: getColor(),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: getColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAnswer() {
    if (_selectedAnswer != null) {
      widget.onAnswer(_selectedAnswer == _correctAnswer);
    }
  }
}
