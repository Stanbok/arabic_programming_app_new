import 'package:flutter/material.dart';
import '../../../models/quiz_block_model.dart';

class DragDropWidget extends StatefulWidget {
  final DragDropQuestion question;
  final Function(List<String> answer) onAnswerChanged;
  final bool showResult;
  final bool isCorrect;

  const DragDropWidget({
    Key? key,
    required this.question,
    required this.onAnswerChanged,
    this.showResult = false,
    this.isCorrect = false,
  }) : super(key: key);

  @override
  State<DragDropWidget> createState() => _DragDropWidgetState();
}

class _DragDropWidgetState extends State<DragDropWidget> {
  List<String> _availableItems = [];
  List<String> _droppedItems = [];

  @override
  void initState() {
    super.initState();
    _availableItems = List.from(widget.question.items);
    _droppedItems = [];
  }

  void _onItemDropped(String item) {
    setState(() {
      _availableItems.remove(item);
      _droppedItems.add(item);
    });
    widget.onAnswerChanged(_droppedItems);
  }

  void _onItemRemoved(String item) {
    setState(() {
      _droppedItems.remove(item);
      _availableItems.add(item);
    });
    widget.onAnswerChanged(_droppedItems);
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
            
            // منطقة الإسقاط
            Container(
              width: double.infinity,
              min: 100,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.showResult 
                    ? (widget.isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.showResult 
                      ? (widget.isCorrect ? Colors.green : Colors.red)
                      : Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: DragTarget<String>(
                onAccept: widget.showResult ? null : _onItemDropped,
                builder: (context, candidateData, rejectedData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اسحب العناصر هنا بالترتيب الصحيح:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_droppedItems.isEmpty)
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: Text(
                            'اسحب العناصر هنا',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _droppedItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return GestureDetector(
                              onTap: widget.showResult ? null : () => _onItemRemoved(item),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${index + 1}. $item',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (!widget.showResult) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // العناصر المتاحة للسحب
            if (_availableItems.isNotEmpty) ...[
              Text(
                'العناصر المتاحة:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableItems.map((item) {
                  return Draggable<String>(
                    data: item,
                    feedback: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            
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
                          widget.isCorrect ? 'ترتيب صحيح!' : 'ترتيب خاطئ',
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
                        'الترتيب الصحيح: ${widget.question.correctOrder.join(' → ')}',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
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
