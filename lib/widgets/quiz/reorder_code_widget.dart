import 'package:flutter/material.dart';
import '../../models/lesson_model.dart';

class ReorderCodeWidget extends StatefulWidget {
  final QuizQuestionModel question;
  final List<int>? userOrder;
  final Function(List<int>) onOrderChanged;
  final bool showResult;
  final bool isCorrect;

  const ReorderCodeWidget({
    super.key,
    required this.question,
    this.userOrder,
    required this.onOrderChanged,
    this.showResult = false,
    this.isCorrect = false,
  });

  @override
  State<ReorderCodeWidget> createState() => _ReorderCodeWidgetState();
}

class _ReorderCodeWidgetState extends State<ReorderCodeWidget> {
  late List<int> currentOrder;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.userOrder ?? List.generate(widget.question.codeBlocks!.length, (index) => index);
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
                'اسحب وأفلت لترتيب أسطر الكود بالترتيب الصحيح',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Code blocks
        if (widget.showResult)
          _buildResultView()
        else
          _buildInteractiveView(),
      ],
    );
  }

  Widget _buildInteractiveView() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentOrder.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = currentOrder.removeAt(oldIndex);
          currentOrder.insert(newIndex, item);
          widget.onOrderChanged(currentOrder);
        });
      },
      itemBuilder: (context, index) {
        final codeIndex = currentOrder[index];
        final codeBlock = widget.question.codeBlocks![codeIndex];
        
        return Container(
          key: ValueKey(codeIndex),
          margin: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.drag_handle,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        codeBlock,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultView() {
    return Column(
      children: widget.question.correctOrder!.asMap().entries.map((entry) {
        final correctIndex = entry.key;
        final correctCodeIndex = entry.value;
        final userCodeIndex = currentOrder.length > correctIndex ? currentOrder[correctIndex] : -1;
        final isCorrectPosition = userCodeIndex == correctCodeIndex;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrectPosition ? Colors.green : Colors.red,
                  width: 2,
                ),
                color: isCorrectPosition 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrectPosition ? Icons.check_circle : Icons.cancel,
                    color: isCorrectPosition ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.question.codeBlocks![correctCodeIndex],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '${correctIndex + 1}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isCorrectPosition ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
