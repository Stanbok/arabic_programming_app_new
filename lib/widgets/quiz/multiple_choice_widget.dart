import 'package:flutter/material.dart';
import '../../models/lesson_model.dart';

class MultipleChoiceWidget extends StatelessWidget {
  final QuizQuestionModel question;
  final int? selectedAnswer;
  final Function(int) onAnswerSelected;
  final bool showResult;
  final bool isCorrect;

  const MultipleChoiceWidget({
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
        
        const SizedBox(height: 24),
        
        // Options
        ...question.options!.asMap().entries.map((entry) {
          final optionIndex = entry.key;
          final optionText = entry.value;
          final isSelected = selectedAnswer == optionIndex;
          final isCorrectOption = question.correctAnswerIndex == optionIndex;
          
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
            backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
            borderColor = Theme.of(context).colorScheme.primary;
            textColor = Theme.of(context).colorScheme.primary;
          }
          
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: showResult ? null : () => onAnswerSelected(optionIndex),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor ?? Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor ?? Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      width: (isSelected || (showResult && isCorrectOption)) ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isSelected || (showResult && isCorrectOption))
                              ? (borderColor ?? Theme.of(context).colorScheme.primary)
                              : Colors.transparent,
                          border: Border.all(
                            color: borderColor ?? Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: (isSelected || (showResult && isCorrectOption))
                            ? Icon(
                                showResult && isCorrectOption ? Icons.check : Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Text(
                          optionText,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textColor,
                            fontWeight: (isSelected || (showResult && isCorrectOption)) ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                      
                      if (showResult && isCorrectOption)
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      if (showResult && isSelected && !isCorrectOption)
                        const Icon(Icons.cancel, color: Colors.red, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
