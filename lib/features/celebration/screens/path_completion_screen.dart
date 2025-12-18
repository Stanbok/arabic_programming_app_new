import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../models/path_model.dart';
import '../widgets/confetti_painter.dart';
import '../widgets/trophy_widget.dart';
import '../widgets/stats_summary.dart';

class PathCompletionScreen extends ConsumerStatefulWidget {
  final PathModel path;
  final int totalLessons;
  final int totalXpEarned;
  final bool hasNextPath;

  const PathCompletionScreen({
    super.key,
    required this.path,
    required this.totalLessons,
    required this.totalXpEarned,
    this.hasNextPath = true,
  });

  @override
  ConsumerState<PathCompletionScreen> createState() =>
      _PathCompletionScreenState();
}

class _PathCompletionScreenState extends ConsumerState<PathCompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _trophyController;
  late AnimationController _contentController;
  late Animation<double> _trophyScaleAnimation;
  late Animation<double> _trophyRotateAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Haptic feedback for celebration
    HapticFeedback.heavyImpact();
    
    // Confetti animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Trophy bounce animation
    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _trophyScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _trophyController,
      curve: Curves.easeOut,
    ));

    _trophyRotateAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.02), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.02, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _trophyController,
      curve: Curves.easeOut,
    ));

    // Content fade/slide animation
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _contentFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations sequentially
    _trophyController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _trophyController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _shareAchievement() {
    final message = '''
أكملت مسار "${widget.path.title}" في تطبيق تعلم بايثون! 
${widget.totalLessons} درس | ${widget.totalXpEarned} نقطة خبرة

#تعلم_بايثون #برمجة
''';
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.accent.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.1),
                  AppColors.background,
                ],
              ),
            ),
          ),

          // Confetti overlay
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(
                  progress: _confettiController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 1),

                  // Trophy with animation
                  AnimatedBuilder(
                    animation: _trophyController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _trophyScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _trophyRotateAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: TrophyWidget(
                      color: _parseColor(widget.path.color),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Content with fade/slide animation
                  SlideTransition(
                    position: _contentSlideAnimation,
                    child: FadeTransition(
                      opacity: _contentFadeAnimation,
                      child: Column(
                        children: [
                          // Celebration title
                          Text(
                            AppStrings.celebration,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                          ),

                          const SizedBox(height: 8),

                          // Path completed message
                          Text(
                            AppStrings.pathCompleted,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 8),

                          // Path name
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _parseColor(widget.path.color)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.path.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _parseColor(widget.path.color),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Stats summary
                          StatsSummary(
                            lessonsCompleted: widget.totalLessons,
                            xpEarned: widget.totalXpEarned,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Action buttons
                  SlideTransition(
                    position: _contentSlideAnimation,
                    child: FadeTransition(
                      opacity: _contentFadeAnimation,
                      child: Column(
                        children: [
                          // Share button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _shareAchievement,
                              icon: const Icon(Icons.share_rounded),
                              label: Text(AppStrings.shareAchievement),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Continue button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (widget.hasNextPath) {
                                  context.go(RouteNames.main);
                                } else {
                                  context.go(RouteNames.main);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                widget.hasNextPath
                                    ? AppStrings.continueToNext
                                    : AppStrings.backToLessons,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }
}
