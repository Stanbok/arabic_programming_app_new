import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/lesson_model.dart';

class FindBugWidget extends StatefulWidget {
  final QuizQuestionModel question;
  final String? userAnswer;
  final Function(String) onAnswerChanged;
  final bool showResult;
  final bool isCorrect;

  const FindBugWidget({
    super.key,
    required this.question,
    this.userAnswer,
    required this.onAnswerChanged,
    this.showResult = false,
    this.isCorrect = false,
  });

  @override
  State<FindBugWidget> createState() => _FindBugWidgetState();
}

class _FindBugWidgetState extends State<FindBugWidget> {
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
                'ابحث عن الخطأ في الكود واكتب السطر الصحيح',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Code with bug
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bug_report,
                    color: Colors.red[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الكود الذي يحتوي على خطأ:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.red[700],
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
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.question.codeWithBug!,
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
                'اكتب الكود الصحيح:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                onChanged: widget.onAnswerChanged,
                maxLines: 3,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب الكود الصحيح هنا...',
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
                  color: Colors.grey[100],
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
                    'الإجابة الصحيحة:',
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
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.question.correctCode!,
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
