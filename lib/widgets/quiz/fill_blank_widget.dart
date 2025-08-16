import 'package:flutter/material.dart';
import '../../models/lesson_model.dart';

class FillBlankWidget extends StatefulWidget {
  final QuizQuestionModel question;
  final List<String>? userAnswers;
  final Function(List<String>) onAnswersChanged;
  final bool showResult;
  final bool isCorrect;

  const FillBlankWidget({
    super.key,
    required this.question,
    this.userAnswers,
    required this.onAnswersChanged,
    this.showResult = false,
    this.isCorrect = false,
  });

  @override
  State<FillBlankWidget> createState() => _FillBlankWidgetState();
}

class _FillBlankWidgetState extends State<FillBlankWidget> {
  late List<TextEditingController> _controllers;
  late List<String> _answers;

  @override
  void initState() {
    super.initState();
    final blanksCount = widget.question.correctAnswers?.length ?? 0;
    _answers = widget.userAnswers ?? List.filled(blanksCount, '');
    _controllers = _answers.map((answer) => TextEditingController(text: answer)).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateAnswer(int index, String value) {
    setState(() {
      _answers[index] = value;
      widget.onAnswersChanged(_answers);
    });
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
                'املأ الفراغات بالكلمات المناسبة',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Text with blanks
        _buildTextWithBlanks(),
      ],
    );
  }

  Widget _buildTextWithBlanks() {
    final text = widget.question.fillInBlankText!;
    final parts = text.split('___');
    
    List<Widget> widgets = [];
    
    for (int i = 0; i < parts.length; i++) {
      // Add text part
      if (parts[i].isNotEmpty) {
        widgets.add(
          Text(
            parts[i],
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      }
      
      // Add blank field (except for the last part)
      if (i < parts.length - 1) {
        widgets.add(_buildBlankField(i));
      }
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: widgets,
      ),
    );
  }

  Widget _buildBlankField(int index) {
    if (index >= _controllers.length) return const SizedBox.shrink();
    
    final isCorrect = widget.showResult && 
        widget.question.correctAnswers != null &&
        index < widget.question.correctAnswers!.length &&
        _answers[index].toLowerCase().trim() == widget.question.correctAnswers![index].toLowerCase().trim();
    
    final hasAnswer = _answers[index].isNotEmpty;
    
    Color? borderColor;
    Color? backgroundColor;
    
    if (widget.showResult) {
      if (isCorrect) {
        borderColor = Colors.green;
        backgroundColor = Colors.green.withOpacity(0.1);
      } else if (hasAnswer) {
        borderColor = Colors.red;
        backgroundColor = Colors.red.withOpacity(0.1);
      }
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: IntrinsicWidth(
        child: Container(
          constraints: const BoxConstraints(minWidth: 80),
          child: TextField(
            controller: _controllers[index],
            enabled: !widget.showResult,
            onChanged: (value) => _updateAnswer(index, value),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.showResult
                  ? (isCorrect ? Colors.green[700] : Colors.red[700])
                  : Theme.of(context).colorScheme.primary,
            ),
            decoration: InputDecoration(
              hintText: '___',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: borderColor ?? Theme.of(context).colorScheme.outline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: borderColor ?? Theme.of(context).colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: borderColor ?? Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: backgroundColor ?? Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              suffixIcon: widget.showResult
                  ? Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 20,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
