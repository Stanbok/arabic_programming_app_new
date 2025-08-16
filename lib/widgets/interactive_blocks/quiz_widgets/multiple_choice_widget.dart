import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../models/quiz_block_model.dart';

class MultipleChoiceWidget extends StatefulWidget {
  final QuizBlockModel quiz;
  final Function(bool, int?) onAnswerSelected;

  const MultipleChoiceWidget({
    Key? key,
    required this.quiz,
    required this.onAnswerSelected,
  }) : super(key: key);

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  int? _selectedAnswer;
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  Widget build(BuildContext context) {
    final options = widget.quiz.content['options'] as List<dynamic>;
    final correctAnswer = widget.quiz.content['correctAnswerIndex'] as int;
    final allowMultiple = widget.quiz.content['allowMultiple'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade400, Colors.purple.shade400],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.quiz, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'اختيار من متعدد',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // السؤال
            Text(
              widget.quiz.question,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            
            // الخيارات
            AnimationLimiter(
              child: Column(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    horizontalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value as String;
                    
                    return _buildOptionTile(
                      index: index,
                      option: option,
                      correctAnswer: correctAnswer,
                    );
                  }).toList(),
                ),
              ),
            ),
            
            // زر التحقق
            if (_selectedAnswer != null && !_showResult) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checkAnswer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('تحقق من الإجابة'),
                ),
              ),
            ],
            
            // عرض النتيجة
            if (_showResult) ...[
              const SizedBox(height: 20),
              _buildResultCard(correctAnswer),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required int index,
    required String option,
    required int correctAnswer,
  }) {
    Color? tileColor;
    Color? textColor;
    IconData? icon;

    if (_showResult) {
      if (index == correctAnswer) {
        tileColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
      } else if (index == _selectedAnswer && index != correctAnswer) {
        tileColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel;
      }
    } else if (index == _selectedAnswer) {
      tileColor = Theme.of(context).colorScheme.primaryContainer;
      textColor = Theme.of(context).colorScheme.onPrimaryContainer;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: tileColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _showResult ? null : () => _selectAnswer(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: index == _selectedAnswer
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: index == _selectedAnswer ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: textColor ?? Colors.grey.shade600,
                      width: 2,
                    ),
                    color: index == _selectedAnswer
                        ? (textColor ?? Theme.of(context).colorScheme.primary)
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: TextStyle(
                        color: index == _selectedAnswer
                            ? Colors.white
                            : (textColor ?? Colors.grey.shade600),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: textColor, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(int correctAnswer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isCorrect ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isCorrect ? Icons.check_circle : Icons.error,
                color: _isCorrect ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                _isCorrect ? 'إجابة صحيحة! 🎉' : 'إجابة خاطئة 😔',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isCorrect ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.quiz.evaluation.successMessage,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(int index) {
    setState(() {
      _selectedAnswer = index;
    });
  }

  void _checkAnswer() {
    final correctAnswer = widget.quiz.content['correctAnswerIndex'] as int;
    final isCorrect = _selectedAnswer == correctAnswer;
    
    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
    });
    
    widget.onAnswerSelected(isCorrect, _selectedAnswer);
  }
}
