import 'package:flutter/material.dart';
import '../../models/lesson_model.dart';

class MatchPairsWidget extends StatefulWidget {
  final QuizQuestionModel question;
  final Map<String, String>? userMatches;
  final Function(Map<String, String>) onMatchesChanged;
  final bool showResult;
  final bool isCorrect;

  const MatchPairsWidget({
    super.key,
    required this.question,
    this.userMatches,
    required this.onMatchesChanged,
    this.showResult = false,
    this.isCorrect = false,
  });

  @override
  State<MatchPairsWidget> createState() => _MatchPairsWidgetState();
}

class _MatchPairsWidgetState extends State<MatchPairsWidget> {
  late Map<String, String> currentMatches;
  String? selectedLeft;
  String? selectedRight;

  @override
  void initState() {
    super.initState();
    currentMatches = Map.from(widget.userMatches ?? {});
  }

  void _selectLeft(String key) {
    if (widget.showResult) return;
    
    setState(() {
      selectedLeft = selectedLeft == key ? null : key;
      selectedRight = null;
    });
  }

  void _selectRight(String value) {
    if (widget.showResult) return;
    
    setState(() {
      if (selectedLeft != null) {
        // Remove any existing match for this value
        currentMatches.removeWhere((k, v) => v == value);
        // Add new match
        currentMatches[selectedLeft!] = value;
        widget.onMatchesChanged(currentMatches);
        selectedLeft = null;
        selectedRight = null;
      } else {
        selectedRight = selectedRight == value ? null : value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final leftItems = widget.question.pairs!.keys.toList();
    final rightItems = widget.question.pairs!.values.toList()..shuffle();

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
                'اضغط على عنصر من اليسار ثم على المطابق له من اليمين',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Matching interface
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                children: leftItems.map((leftItem) {
                  final isSelected = selectedLeft == leftItem;
                  final isMatched = currentMatches.containsKey(leftItem);
                  final matchedValue = currentMatches[leftItem];
                  final isCorrectMatch = widget.showResult && 
                      widget.question.pairs![leftItem] == matchedValue;
                  
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectLeft(leftItem),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getLeftItemColor(isSelected, isMatched, isCorrectMatch),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getLeftItemBorderColor(isSelected, isMatched, isCorrectMatch),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  leftItem,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : null,
                                  ),
                                ),
                              ),
                              if (widget.showResult && isMatched)
                                Icon(
                                  isCorrectMatch ? Icons.check_circle : Icons.cancel,
                                  color: isCorrectMatch ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Right column
            Expanded(
              child: Column(
                children: rightItems.map((rightItem) {
                  final isSelected = selectedRight == rightItem;
                  final isMatched = currentMatches.containsValue(rightItem);
                  final matchingKey = currentMatches.entries
                      .where((entry) => entry.value == rightItem)
                      .map((entry) => entry.key)
                      .firstOrNull;
                  final isCorrectMatch = widget.showResult && 
                      matchingKey != null &&
                      widget.question.pairs![matchingKey] == rightItem;
                  
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectRight(rightItem),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getRightItemColor(isSelected, isMatched, isCorrectMatch),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getRightItemBorderColor(isSelected, isMatched, isCorrectMatch),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  rightItem,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : null,
                                  ),
                                ),
                              ),
                              if (widget.showResult && isMatched)
                                Icon(
                                  isCorrectMatch ? Icons.check_circle : Icons.cancel,
                                  color: isCorrectMatch ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getLeftItemColor(bool isSelected, bool isMatched, bool isCorrectMatch) {
    if (widget.showResult && isMatched) {
      return isCorrectMatch 
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1);
    }
    if (isSelected) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.1);
    }
    if (isMatched) {
      return Colors.blue.withOpacity(0.1);
    }
    return Theme.of(context).colorScheme.surface;
  }

  Color _getLeftItemBorderColor(bool isSelected, bool isMatched, bool isCorrectMatch) {
    if (widget.showResult && isMatched) {
      return isCorrectMatch ? Colors.green : Colors.red;
    }
    if (isSelected) {
      return Theme.of(context).colorScheme.primary;
    }
    if (isMatched) {
      return Colors.blue;
    }
    return Theme.of(context).colorScheme.outline.withOpacity(0.2);
  }

  Color _getRightItemColor(bool isSelected, bool isMatched, bool isCorrectMatch) {
    if (widget.showResult && isMatched) {
      return isCorrectMatch 
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1);
    }
    if (isSelected) {
      return Theme.of(context).colorScheme.secondary.withOpacity(0.1);
    }
    if (isMatched) {
      return Colors.blue.withOpacity(0.1);
    }
    return Theme.of(context).colorScheme.surface;
  }

  Color _getRightItemBorderColor(bool isSelected, bool isMatched, bool isCorrectMatch) {
    if (widget.showResult && isMatched) {
      return isCorrectMatch ? Colors.green : Colors.red;
    }
    if (isSelected) {
      return Theme.of(context).colorScheme.secondary;
    }
    if (isMatched) {
      return Colors.blue;
    }
    return Theme.of(context).colorScheme.outline.withOpacity(0.2);
  }
}
