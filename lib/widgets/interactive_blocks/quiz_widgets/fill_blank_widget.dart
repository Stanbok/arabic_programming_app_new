import 'package:flutter/material.dart';
import '../../../models/quiz_block_model.dart';

class FillBlankWidget extends StatefulWidget {
  final FillBlankQuestion question;
  final Function(String answer) onAnswerChanged;
  final bool showResult;
  final bool isCorrect;

  const FillBlankWidget({
    Key? key,
    required this.question,
    required this.onAnswerChanged,
    this.showResult = false,
    this.isCorrect = false,
  }) : super(key: key);

  @override
  State<FillBlankWidget> createState() => _FillBlankWidgetState();
}

class _FillBlankWidgetState extends State<FillBlankWidget> {
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
            
            // عرض النص مع الفراغات
            _buildTextWithBlanks(),
            
            const SizedBox(height: 16),
            
            // عرض النتيجة إذا كانت متاحة
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
                child: Row(
                  children: [
                    Icon(
                      widget.isCorrect ? Icons.check_circle : Icons.cancel,
                      color: widget.isCorrect ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isCorrect ? 'إجابة صحيحة!' : 'إجابة خاطئة. الإجابة الصحيحة: ${widget.question.correctAnswer}',
                        style: TextStyle(
                          color: widget.isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextWithBlanks() {
    final parts = widget.question.textWithBlanks.split('___');
    final widgets = <Widget>[];
    
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        widgets.add(
          Text(
            parts[i],
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      }
      
      if (i < parts.length - 1) {
        widgets.add(
          Container(
            width: 120,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: TextField(
              controller: _controller,
              enabled: !widget.showResult,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                fillColor: widget.showResult 
                    ? (widget.isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                    : null,
                filled: widget.showResult,
              ),
              onChanged: widget.onAnswerChanged,
            ),
          ),
        );
      }
    }
    
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: widgets,
    );
  }
}
