import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../models/quiz_result_model.dart';
import '../widgets/score_circle.dart';
import '../widgets/stats_row.dart';
import '../widgets/stars_display.dart';
import '../widgets/question_review_card.dart';

class QuizResultsScreen extends ConsumerStatefulWidget {
  final QuizResultModel result;
  final String lessonTitle;

  const QuizResultsScreen({
    super.key,
    required this.result,
    required this.lessonTitle,
  });

  @override
  ConsumerState<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends ConsumerState<QuizResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.result.scorePercentage,
    ).animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      _scoreController.forward();
      if (widget.result.isPassed) {
        _confettiController.forward();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isPassed = result.isPassed;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isPassed
                    ? [AppColors.success.withOpacity(0.1), Colors.white]
                    : [AppColors.error.withOpacity(0.1), Colors.white],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Result header with Lottie
                  _buildResultHeader(isPassed),
                  
                  const SizedBox(height: 32),
                  
                  // Score circle with animation
                  AnimatedBuilder(
                    animation: _scoreAnimation,
                    builder: (context, child) {
                      return ScoreCircle(
                        score: _scoreAnimation.value,
                        size: 180,
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Stars display
                  StarsDisplay(
                    starsEarned: result.starsEarned,
                    totalStars: 3,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Stats row
                  StatsRow(
                    correct: result.correctAnswers,
                    wrong: result.wrongAnswers,
                    skipped: result.skippedAnswers,
                    time: result.formattedTime,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Review answers toggle
                  _buildReviewToggle(),
                  
                  // Question review list (collapsible)
                  if (_showDetails) ...[
                    const SizedBox(height: 16),
                    ...result.questionResults.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: QuestionReviewCard(
                          index: entry.key + 1,
                          result: entry.value,
                        ),
                      );
                    }),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  _buildActionButtons(isPassed),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Confetti overlay for passing
          if (isPassed)
            Positioned.fill(
              child: IgnorePointer(
                child: Lottie.network(
                  'https://lottie.host/embed/confetti-celebration.json',
                  controller: _confettiController,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback: show nothing if Lottie fails
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(bool isPassed) {
    return Column(
      children: [
        // Lottie animation
        SizedBox(
          height: 120,
          width: 120,
          child: isPassed
              ? Lottie.network(
                  'https://lottie.host/embed/success-check.json',
                  repeat: false,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.check_circle,
                      size: 80,
                      color: AppColors.success,
                    );
                  },
                )
              : Lottie.network(
                  'https://lottie.host/embed/try-again.json',
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.refresh,
                      size: 80,
                      color: AppColors.warning,
                    );
                  },
                ),
        ),
        
        const SizedBox(height: 16),
        
        // Title
        Text(
          isPassed ? AppStrings.quizPassed : AppStrings.quizTryAgain,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isPassed ? AppColors.success : AppColors.warning,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Lesson title
        Text(
          widget.lessonTitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReviewToggle() {
    return InkWell(
      onTap: () => setState(() => _showDetails = !_showDetails),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showDetails ? Icons.visibility_off : Icons.visibility,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _showDetails 
                  ? AppStrings.hideAnswers 
                  : AppStrings.reviewAnswers,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: _showDetails ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isPassed) {
    return Column(
      children: [
        // Primary action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (isPassed) {
                // Go to next lesson or back to lessons
                context.go(RouteNames.main);
              } else {
                // Retry the lesson
                context.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isPassed ? AppColors.primary : AppColors.warning,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              isPassed ? AppStrings.continueButton : AppStrings.tryAgain,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Secondary action
        TextButton(
          onPressed: () => context.go(RouteNames.main),
          child: Text(
            AppStrings.backToLessons,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
