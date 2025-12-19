import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/lesson_model.dart';
import '../../../core/models/progress_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../home/screens/main_screen.dart';
import 'dart:math' as math;

class ResultsScreen extends StatefulWidget {
  final LessonModel lesson;
  final int correctAnswers;
  final int totalQuestions;

  const ResultsScreen({
    super.key,
    required this.lesson,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late bool _passed;

  @override
  void initState() {
    super.initState();
    
    _passed = (widget.correctAnswers / widget.totalQuestions) >= 0.5;
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.correctAnswers / widget.totalQuestions,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));

    _progressController.forward();

    if (_passed) {
      _saveProgress();
    }
  }

  Future<void> _saveProgress() async {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final userId = authService.currentUser?.uid;
    
    if (userId == null) return;

    final progress = ProgressModel(
      lessonId: widget.lesson.id,
      completed: true,
      completedAt: DateTime.now(),
      quizScore: widget.correctAnswers,
      totalQuestions: widget.totalQuestions,
    );

    await firestoreService.saveProgress(userId, widget.lesson.id, progress);
    await firestoreService.incrementCompletedLessons(userId);
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  String _getResultMessage() {
    final percentage = widget.correctAnswers / widget.totalQuestions;
    if (percentage == 1.0) return 'ممتاز! إجابة مثالية';
    if (percentage >= 0.8) return 'أحسنت! أداء رائع';
    if (percentage >= 0.5) return 'جيد! استمر في التعلم';
    return 'حاول مرة أخرى';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              
              // Result Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: (_passed ? AppColors.success : AppColors.error)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _passed ? Icons.check_circle : Icons.refresh,
                  size: 56,
                  color: _passed ? AppColors.success : AppColors.error,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Score Circle
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: _CircleProgressPainter(
                            progress: _progressAnimation.value,
                            isPassed: _passed,
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${widget.correctAnswers}/${widget.totalQuestions}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(
                                'إجابة صحيحة',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Message
              Text(
                _getResultMessage(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              if (_passed)
                const Text(
                  'تم فتح الدرس التالي',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.success,
                  ),
                )
              else
                const Text(
                  'تحتاج 50% للنجاح',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              
              const Spacer(),
              
              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(_passed ? 'completed' : null);
                    Navigator.of(context).pop(_passed ? 'completed' : null);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_passed ? 'الدرس التالي' : 'العودة للدروس'),
                ),
              ),
              
              if (!_passed) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('إعادة المحاولة'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final bool isPassed;

  _CircleProgressPainter({required this.progress, required this.isPassed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final bgPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = isPassed ? AppColors.success : AppColors.error
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
