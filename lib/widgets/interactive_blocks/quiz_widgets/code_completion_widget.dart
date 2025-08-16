import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import '../../../models/quiz_block_model.dart';

class CodeCompletionWidget extends StatefulWidget {
  final CodeCompletionQuestion question;
  final Function(String answer) onAnswerChanged;
  final bool showResult;
  final bool isCorrect;

  const CodeCompletionWidget({
    Key? key,
    required this.question,
    required this.onAnswerChanged,
    this.showResult = false,
    this.isCorrect = false,
  }) : super(key: key);

  @override
  State<CodeCompletionWidget> createState() => _CodeCompletionWidgetState();
}

class _CodeCompletionWidgetState extends State<CodeCompletionWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question.question,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // عرض الكود مع الجزء المفقود
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  // الكود قبل الجزء المفقود
                  if (widget.question.codeBefore.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      child: HighlightView(
                        widget.question.codeBefore,
                        language: 'python',
                        theme: githubTheme,
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                  
                  // منطقة إدخال الكود
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: widget.showResult 
                          ? (widget.isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                          : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: widget.showResult 
                            ? (widget.isCorrect ? Colors.green : Colors.red)
                            : Colors.grey[400]!,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      enabled: !widget.showResult,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: '// اكتب الكود هنا',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(8),
                      ),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      onChanged: widget.onAnswerChanged,
                    ),
                  ),
                  
                  // الكود بعد الجزء المفقود
                  if (widget.question.codeAfter.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      child: HighlightView(
                        widget.question.codeAfter,
                        language: 'python',
                        theme: githubTheme,
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // عرض النتيجة
            if (widget.showResult) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isCorrect ? Colors.green : Colors.red,
                    width: 1,
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
                          widget.isCorrect ? 'إجابة صحيحة!' : 'إجابة خاطئة',
                          style: TextStyle(
                            color: widget.isCorrect ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (!widget.isCorrect) ...[
                      const SizedBox(height: 8),
                      Text(
                        'الإجابة الصحيحة:',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: HighlightView(
                          widget.question.correctAnswer,
                          language: 'python',
                          theme: githubTheme,
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
