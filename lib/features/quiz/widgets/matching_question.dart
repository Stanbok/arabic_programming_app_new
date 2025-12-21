import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class MatchingQuestion extends StatefulWidget {
  final Map<String, String> pairs;
  final bool enabled;
  final void Function(bool isCorrect) onAnswer;

  const MatchingQuestion({
    super.key,
    required this.pairs,
    required this.enabled,
    required this.onAnswer,
  });

  @override
  State<MatchingQuestion> createState() => _MatchingQuestionState();
}

class _MatchingQuestionState extends State<MatchingQuestion> {
  late List<String> _leftItems;
  late List<String> _rightItems;
  final Map<String, String> _matches = {};
  String? _selectedLeft;

  @override
  void initState() {
    super.initState();
    _leftItems = widget.pairs.keys.toList();
    _rightItems = widget.pairs.values.toList()..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final showResult = !widget.enabled;
    final allMatched = _matches.length == _leftItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'صل بين كل عنصر على اليمين مع ما يناسبه على اليسار:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                children: _leftItems.map((item) {
                  final isSelected = _selectedLeft == item;
                  final isMatched = _matches.containsKey(item);
                  final matchedValue = _matches[item];
                  final isCorrectMatch = matchedValue == widget.pairs[item];

                  Color getColor() {
                    if (showResult && isMatched) {
                      return isCorrectMatch ? AppColors.success : AppColors.error;
                    }
                    if (isSelected) return AppColors.primary;
                    if (isMatched) return AppColors.secondary;
                    return AppColors.dividerLight;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: widget.enabled && !isMatched
                          ? () => setState(() => _selectedLeft = item)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: getColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: getColor(), width: isSelected ? 2 : 1),
                        ),
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Connection lines area
            const SizedBox(width: 16),
            
            // Right column
            Expanded(
              child: Column(
                children: _rightItems.map((item) {
                  final matchedKey = _matches.entries
                      .where((e) => e.value == item)
                      .map((e) => e.key)
                      .firstOrNull;
                  final isMatched = matchedKey != null;
                  final isCorrectMatch = widget.pairs[matchedKey] == item;

                  Color getColor() {
                    if (showResult && isMatched) {
                      return isCorrectMatch ? AppColors.success : AppColors.error;
                    }
                    if (isMatched) return AppColors.secondary;
                    return AppColors.dividerLight;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: widget.enabled && _selectedLeft != null && !isMatched
                          ? () => _matchItems(item)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: getColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: getColor()),
                        ),
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        
        if (widget.enabled && _matches.isNotEmpty && !allMatched)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton.icon(
              onPressed: () => setState(() {
                _matches.clear();
                _selectedLeft = null;
              }),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة'),
            ),
          ),
        
        const SizedBox(height: 16),
        if (widget.enabled && allMatched)
          ElevatedButton(
            onPressed: _confirmAnswer,
            child: const Text('تأكيد الإجابة'),
          ),
      ],
    );
  }

  void _matchItems(String rightItem) {
    if (_selectedLeft != null) {
      setState(() {
        _matches[_selectedLeft!] = rightItem;
        _selectedLeft = null;
      });
    }
  }

  void _confirmAnswer() {
    bool allCorrect = true;
    for (final entry in _matches.entries) {
      if (widget.pairs[entry.key] != entry.value) {
        allCorrect = false;
        break;
      }
    }
    widget.onAnswer(allCorrect);
  }
}
