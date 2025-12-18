import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/card_model.dart';
import '../code_block_widget.dart';

class QuizQuestionWidget extends StatefulWidget {
  final QuizQuestion question;
  final Function(bool isCorrect) onAnswerSubmitted;
  final bool isAnswered;

  const QuizQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswerSubmitted,
    required this.isAnswered,
  });

  @override
  State<QuizQuestionWidget> createState() => _QuizQuestionWidgetState();
}

class _QuizQuestionWidgetState extends State<QuizQuestionWidget> {
  dynamic _selectedAnswer;
  final TextEditingController _textController = TextEditingController();
  List<String> _orderedItems = [];
  Map<String, String> _matchedPairs = {};

  @override
  void initState() {
    super.initState();
    if (widget.question.type == 'order' && widget.question.options != null) {
      _orderedItems = List.from(widget.question.options!);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    if (widget.isAnswered) return;

    bool isCorrect = false;
    final correctAnswer = widget.question.correctAnswer;

    switch (widget.question.type) {
      case 'mcq':
      case 'true_false':
        isCorrect = _selectedAnswer == correctAnswer;
        break;
      case 'fill_blank':
      case 'code_complete':
        isCorrect = _textController.text.trim().toLowerCase() ==
            correctAnswer.toString().toLowerCase();
        break;
      case 'multi_select':
        if (_selectedAnswer is List && correctAnswer is List) {
          final selected = Set.from(_selectedAnswer);
          final correct = Set.from(correctAnswer);
          isCorrect = selected.containsAll(correct) && correct.containsAll(selected);
        }
        break;
      case 'order':
        if (correctAnswer is List) {
          isCorrect = _listEquals(_orderedItems, List<String>.from(correctAnswer));
        }
        break;
      case 'match':
        if (correctAnswer is Map) {
          isCorrect = _mapEquals(_matchedPairs, Map<String, String>.from(correctAnswer));
        }
        break;
      case 'spot_error':
        isCorrect = _selectedAnswer == correctAnswer;
        break;
    }

    widget.onAnswerSubmitted(isCorrect);
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _mapEquals(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text
        Text(
          widget.question.question,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        // Code snippet if exists
        if (widget.question.codeSnippet != null) ...[
          const SizedBox(height: 16),
          CodeBlockWidget(code: widget.question.codeSnippet!),
        ],
        const SizedBox(height: 20),
        // Answer options based on type
        _buildAnswerWidget(),
        const SizedBox(height: 24),
        // Submit button
        if (!widget.isAnswered)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit() ? _submitAnswer : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                disabledBackgroundColor: AppColors.textHint,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'تحقق من الإجابة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _canSubmit() {
    switch (widget.question.type) {
      case 'mcq':
      case 'true_false':
      case 'spot_error':
        return _selectedAnswer != null;
      case 'fill_blank':
      case 'code_complete':
        return _textController.text.trim().isNotEmpty;
      case 'multi_select':
        return _selectedAnswer is List && (_selectedAnswer as List).isNotEmpty;
      case 'order':
        return _orderedItems.isNotEmpty;
      case 'match':
        return _matchedPairs.length == (widget.question.options?.length ?? 0) ~/ 2;
      default:
        return false;
    }
  }

  Widget _buildAnswerWidget() {
    switch (widget.question.type) {
      case 'mcq':
        return _buildMCQ();
      case 'true_false':
        return _buildTrueFalse();
      case 'fill_blank':
        return _buildFillBlank();
      case 'multi_select':
        return _buildMultiSelect();
      case 'order':
        return _buildOrder();
      case 'match':
        return _buildMatch();
      case 'code_complete':
        return _buildCodeComplete();
      case 'spot_error':
        return _buildSpotError();
      default:
        return const Text('نوع السؤال غير مدعوم');
    }
  }

  Widget _buildMCQ() {
    return Column(
      children: (widget.question.options ?? []).map((option) {
        final isSelected = _selectedAnswer == option;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: widget.isAnswered ? null : () => setState(() => _selectedAnswer = option),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalse() {
    return Row(
      children: [
        Expanded(
          child: _buildTrueFalseOption(true, 'صحيح', Icons.check_circle_outline),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTrueFalseOption(false, 'خطأ', Icons.cancel_outlined),
        ),
      ],
    );
  }

  Widget _buildTrueFalseOption(bool value, String label, IconData icon) {
    final isSelected = _selectedAnswer == value;
    return InkWell(
      onTap: widget.isAnswered ? null : () => setState(() => _selectedAnswer = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? (value ? AppColors.success : AppColors.error).withOpacity(0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? (value ? AppColors.success : AppColors.error) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? (value ? AppColors.success : AppColors.error)
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? (value ? AppColors.success : AppColors.error)
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFillBlank() {
    return TextField(
      controller: _textController,
      enabled: !widget.isAnswered,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        hintText: 'اكتب إجابتك هنا',
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildMultiSelect() {
    final selected = _selectedAnswer as List? ?? [];
    return Column(
      children: (widget.question.options ?? []).map((option) {
        final isSelected = selected.contains(option);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: widget.isAnswered
                ? null
                : () {
                    setState(() {
                      final newSelected = List<String>.from(selected);
                      if (isSelected) {
                        newSelected.remove(option);
                      } else {
                        newSelected.add(option);
                      }
                      _selectedAnswer = newSelected;
                    });
                  },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
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

  Widget _buildOrder() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _orderedItems.length,
      onReorder: widget.isAnswered
          ? (_, __) {}
          : (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _orderedItems.removeAt(oldIndex);
                _orderedItems.insert(newIndex, item);
              });
            },
      itemBuilder: (context, index) {
        return Container(
          key: ValueKey(_orderedItems[index]),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
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
                  _orderedItems[index],
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const Icon(Icons.drag_handle, color: AppColors.textHint),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatch() {
    // Simplified match - pairs are in options as alternating key/value
    final options = widget.question.options ?? [];
    final keys = <String>[];
    final values = <String>[];
    
    for (int i = 0; i < options.length; i++) {
      if (i % 2 == 0) {
        keys.add(options[i]);
      } else {
        values.add(options[i]);
      }
    }

    return Column(
      children: [
        const Text(
          'اسحب للمطابقة',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ...keys.asMap().entries.map((entry) {
          final key = entry.value;
          final matched = _matchedPairs[key];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(key, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_back, color: AppColors.textHint),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: matched,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: const Text('اختر'),
                    items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: widget.isAnswered
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _matchedPairs[key] = value;
                              });
                            }
                          },
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCodeComplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أكمل الكود:',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _textController,
          enabled: !widget.isAnswered,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
          decoration: InputDecoration(
            hintText: '...',
            hintStyle: const TextStyle(color: AppColors.textHint),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildSpotError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اضغط على السطر الذي يحتوي على الخطأ:',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ...(widget.question.options ?? []).asMap().entries.map((entry) {
          final index = entry.key;
          final line = entry.value;
          final isSelected = _selectedAnswer == index;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: widget.isAnswered ? null : () => setState(() => _selectedAnswer = index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.error.withOpacity(0.1) : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.error : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
