import 'package:flutter/material.dart';
import '../../models/lesson_model.dart';

class TrueFalseWidget extends StatelessWidget {
  final QuizQuestionModel question;
  final bool? selectedAnswer;
  final Function(bool) onAnswerSelected;
  final bool showResult;
  final bool isCorrect;

  const TrueFalseWidget({
    super.key,
    required this.question,
    this.selectedAnswer,
    required this.onAnswerSelected,
    this.showResult = false,
    this.isCorrect = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            question.question,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // True/False options
        Row(
          children: [
            Expanded(
              child: _buildOption(
                context: context,
                value: true,
                label: 'صحيح',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOption(
                context: context,
                value: false,
                label: 'خطأ',
                icon: Icons.cancel,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required bool value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedAnswer == value;
    final isCorrectOption = question.correctBoolean == value;
    
    Color? backgroundColor;
    Color? borderColor;
    Color? textColor;
    
    if (showResult) {
      if (isCorrectOption) {
        backgroundColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green;
        textColor = Colors.green[700];
      } else if (isSelected && !isCorrectOption) {
        backgroundColor = Colors.red.withOpacity(0.1);
        borderColor = Colors.red;
        textColor = Colors.red[700];
      }
    } else if (isSelected) {
      backgroundColor = color.withOpacity(0.1);
      borderColor = color;
      textColor = color;
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: showResult ? null : () => onAnswerSelected(value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor ?? Colors.grey.withOpacity(0.3),
              width: (isSelected || (showResult && isCorrectOption)) ? 3 : 1,
            ),
            boxShadow: [
              if (isSelected || (showResult && isCorrectOption))
                BoxShadow(
                  color: (borderColor ?? color).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (isSelected || (showResult && isCorrectOption))
                      ? (borderColor ?? color)
                      : Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: (isSelected || (showResult && isCorrectOption))
                      ? Colors.white
                      : Colors.grey,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor ?? Colors.grey[700],
                ),
              ),
              
              if (showResult && isCorrectOption)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
              
              if (showResult && isSelected && !isCorrectOption)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: const Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
