import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class OrderingQuestion extends StatefulWidget {
  final List<String> items;
  final List<String> correctOrder;
  final bool enabled;
  final void Function(bool isCorrect) onAnswer;

  const OrderingQuestion({
    super.key,
    required this.items,
    required this.correctOrder,
    required this.enabled,
    required this.onAnswer,
  });

  @override
  State<OrderingQuestion> createState() => _OrderingQuestionState();
}

class _OrderingQuestionState extends State<OrderingQuestion> {
  late List<String> _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = List.from(widget.items)..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final showResult = !widget.enabled;
    final isCorrect = _checkOrder();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'رتب العناصر بالترتيب الصحيح:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        if (widget.enabled)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentOrder.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _currentOrder.removeAt(oldIndex);
                _currentOrder.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              return _buildItem(
                key: ValueKey(_currentOrder[index]),
                item: _currentOrder[index],
                index: index,
                showResult: false,
              );
            },
          )
        else
          Column(
            children: List.generate(_currentOrder.length, (index) {
              final isItemCorrect = _currentOrder[index] == widget.correctOrder[index];
              return _buildItem(
                key: ValueKey(_currentOrder[index]),
                item: _currentOrder[index],
                index: index,
                showResult: true,
                isItemCorrect: isItemCorrect,
              );
            }),
          ),
        
        const SizedBox(height: 24),
        if (widget.enabled)
          ElevatedButton(
            onPressed: () => widget.onAnswer(_checkOrder()),
            child: const Text('تأكيد الإجابة'),
          ),
      ],
    );
  }

  Widget _buildItem({
    required Key key,
    required String item,
    required int index,
    required bool showResult,
    bool isItemCorrect = false,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: showResult
            ? (isItemCorrect
                ? AppColors.success.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1))
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: showResult
              ? (isItemCorrect ? AppColors.success : AppColors.error)
              : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: showResult
                  ? (isItemCorrect ? AppColors.success : AppColors.error)
                  : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (!showResult)
            const Icon(Icons.drag_handle_rounded, color: AppColors.locked),
          if (showResult)
            Icon(
              isItemCorrect ? Icons.check_rounded : Icons.close_rounded,
              color: isItemCorrect ? AppColors.success : AppColors.error,
            ),
        ],
      ),
    );
  }

  bool _checkOrder() {
    if (_currentOrder.length != widget.correctOrder.length) return false;
    for (int i = 0; i < _currentOrder.length; i++) {
      if (_currentOrder[i] != widget.correctOrder[i]) return false;
    }
    return true;
  }
}
