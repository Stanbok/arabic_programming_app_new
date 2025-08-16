import 'package:flutter/material.dart';
import '../../models/lesson_model.dart';

class CompleteCodeWidget extends StatefulWidget {
  final QuizQuestionModel question;
  final String? userAnswer;
  final Function(String) onAnswerChanged;
  final bool showResult;
  final bool isCorrect;

  const CompleteCodeWidget({
    super.key,
    required this.question,
    this.userAnswer,
    required this.onAnswerChanged,
    this.showResult = false,
    this.isCorrect = false,
  });

  @override
  State<CompleteCodeWidget> createState() => _CompleteCodeWidgetState();
}

class _CompleteCodeWidgetState extends State<CompleteCodeWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.userAnswer ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.question.question,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'أكمل الكود الناقص',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Code template
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.code,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الكود الناقص:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.question.codeTemplate ?? '',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Answer input
        if (!widget.showResult)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أكمل الكود:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                onChanged: widget.onAnswerChanged,
                maxLines: 5,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب الكود المكمل هنا...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          )
        else
          _buildResultView(),
      ],
    );
  }

  Widget _buildResultView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User answer
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isCorrect 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isCorrect ? Colors.green : Colors.red,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.isCorrect ? Icons.check_circle : Icons.cancel,
                    color: widget.isCorrect ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'إجابتك:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: widget.isCorrect ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.userAnswer ?? 'لم تجب',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Correct answer
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: Colors.green[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الكود الصحيح:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.question.correctCode ?? '',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
