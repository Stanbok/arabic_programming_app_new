import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class FillBlankQuestion extends StatefulWidget {
  final String correctText;
  final bool enabled;
  final void Function(bool isCorrect) onAnswer;

  const FillBlankQuestion({
    super.key,
    required this.correctText,
    required this.enabled,
    required this.onAnswer,
  });

  @override
  State<FillBlankQuestion> createState() => _FillBlankQuestionState();
}

class _FillBlankQuestionState extends State<FillBlankQuestion> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showResult = !widget.enabled;
    final isCorrect = _controller.text.trim().toLowerCase() ==
        widget.correctText.trim().toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
          decoration: InputDecoration(
            hintText: 'اكتب إجابتك هنا',
            filled: true,
            fillColor: showResult
                ? (isCorrect
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1))
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: showResult
                    ? (isCorrect ? AppColors.success : AppColors.error)
                    : AppColors.dividerLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.dividerLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            suffixIcon: showResult
                ? Icon(
                    isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isCorrect ? AppColors.success : AppColors.error,
                  )
                : null,
          ),
        ),
        if (showResult && !isCorrect) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الإجابة الصحيحة: ${widget.correctText}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (widget.enabled && _hasText)
          ElevatedButton(
            onPressed: _confirmAnswer,
            child: const Text('تأكيد الإجابة'),
          ),
      ],
    );
  }

  void _confirmAnswer() {
    final isCorrect = _controller.text.trim().toLowerCase() ==
        widget.correctText.trim().toLowerCase();
    widget.onAnswer(isCorrect);
  }
}
