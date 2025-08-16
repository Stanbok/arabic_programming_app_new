import 'package:flutter/material.dart';
import 'quiz_theme.dart';

class QuizProgressIndicator extends StatefulWidget {
  final int currentQuestion;
  final int totalQuestions;
  final double progress;
  final Duration timeRemaining;
  final bool showTimer;

  const QuizProgressIndicator({
    Key? key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.progress,
    required this.timeRemaining,
    this.showTimer = true,
  }) : super(key: key);

  @override
  State<QuizProgressIndicator> createState() => _QuizProgressIndicatorState();
}

class _QuizProgressIndicatorState extends State<QuizProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _timerController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _timerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    _progressController.forward();
    if (widget.showTimer) {
      _timerController.repeat();
    }
  }

  @override
  void didUpdateWidget(QuizProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ));
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: QuizTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السؤال ${widget.currentQuestion} من ${widget.totalQuestions}',
                style: QuizTheme.optionTextStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.showTimer)
                AnimatedBuilder(
                  animation: _timerController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.timeRemaining.inSeconds < 30
                            ? QuizTheme.incorrectColor.withOpacity(0.1)
                            : QuizTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.timeRemaining.inSeconds < 30
                              ? QuizTheme.incorrectColor
                              : QuizTheme.primaryColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: widget.timeRemaining.inSeconds < 30
                                ? QuizTheme.incorrectColor
                                : QuizTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(widget.timeRemaining),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.timeRemaining.inSeconds < 30
                                  ? QuizTheme.incorrectColor
                                  : QuizTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  QuizTheme.primaryColor,
                ),
                minHeight: 8,
              );
            },
          ),
        ],
      ),
    );
  }
}
