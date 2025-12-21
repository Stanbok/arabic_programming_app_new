import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/content_provider.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../../core/widgets/error_view.dart';
import '../../../data/models/lesson_model.dart';
import '../../../data/models/lesson_content_model.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../widgets/explanation_card.dart';
import '../widgets/summary_card.dart';

class LessonViewerScreen extends ConsumerStatefulWidget {
  final LessonModel lesson;
  final String pathId;

  const LessonViewerScreen({
    super.key,
    required this.lesson,
    required this.pathId,
  });

  @override
  ConsumerState<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends ConsumerState<LessonViewerScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  List<CardModel> _contentCards = [];
  List<QuizData> _quizQuestions = [];
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressProvider.notifier).setCurrentPosition(
            pathId: widget.pathId,
            lessonId: widget.lesson.id,
          );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _parseContent(LessonContentModel content) {
    _contentCards = [];
    _quizQuestions = [];

    for (final card in content.cards) {
      if (card.type == CardType.quiz && card.quizData != null) {
        _quizQuestions.add(card.quizData!);
      } else {
        _contentCards.add(card);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(lessonContentProvider((
      lessonId: widget.lesson.id,
      pathId: widget.pathId,
    )));

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.lesson.title),
            centerTitle: true,
          ),
          body: contentAsync.when(
            data: (content) {
              if (content == null) {
                return const ErrorView(
                  message: 'محتوى الدرس غير متاح\nيرجى التحقق من الاتصال بالإنترنت',
                  icon: Icons.wifi_off_rounded,
                );
              }
              _parseContent(content);
              return _buildContent(context);
            },
            loading: () => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل الدرس...'),
                ],
              ),
            ),
            error: (e, _) => ErrorView(
              message: 'حدث خطأ أثناء تحميل الدرس\n${e.toString()}',
              onRetry: () => ref.invalidate(lessonContentProvider),
            ),
          ),
        ),
        
        if (_showCelebration)
          CelebrationOverlay(
            title: 'أحسنت! أكملت المسار!',
            subtitle: 'لقد أتممت جميع دروس هذا المسار بنجاح',
            onDismiss: () {
              setState(() => _showCelebration = false);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final totalPages = _contentCards.length;

    if (totalPages == 0) {
      // No content cards, go directly to quiz
      return Center(
        child: ElevatedButton.icon(
          onPressed: () => _startQuiz(context),
          icon: const Icon(Icons.quiz_rounded),
          label: const Text('بدء الاختبار'),
        ),
      );
    }

    return Column(
      children: [
        // Progress dots
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _buildProgressDots(totalPages),
        ),

        // Card content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              ref.read(progressProvider.notifier).updateCardIndex(index);
            },
            itemCount: totalPages,
            itemBuilder: (context, index) {
              final card = _contentCards[index];
              return _buildCardContent(context, card, index, totalPages);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDots(int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == _currentPage;
        final isCompleted = index < _currentPage;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.success
                : isActive
                    ? AppColors.primary
                    : AppColors.dividerLight,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    CardModel card,
    int index,
    int total,
  ) {
    final isLast = index == total - 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card widget based on type
          if (card.type == CardType.explanation)
            ExplanationCard(blocks: card.blocks ?? [])
          else if (card.type == CardType.summary)
            SummaryCard(blocks: card.blocks ?? []),

          const SizedBox(height: 24),

          // Navigation buttons
          Row(
            children: [
              if (index > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('السابق'),
                  ),
                ),
              if (index > 0 && !isLast) const SizedBox(width: 12),
              if (!isLast)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('التالي'),
                  ),
                ),
              if (isLast)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startQuiz(context),
                    icon: const Icon(Icons.quiz_rounded),
                    label: Text(
                      _quizQuestions.isEmpty ? 'إنهاء الدرس' : 'بدء الاختبار',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _startQuiz(BuildContext context) {
    if (_quizQuestions.isEmpty) {
      _completeLesson(context);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: _quizQuestions,
          lessonTitle: widget.lesson.title,
          onComplete: () => _completeLesson(context),
        ),
      ),
    );
  }

  Future<void> _completeLesson(BuildContext context) async {
    final progressNotifier = ref.read(progressProvider.notifier);
    
    // Mark lesson as completed
    await progressNotifier.completeLesson(widget.lesson.id);

    // Check if all lessons in path are completed
    final lessonsAsync = ref.read(lessonsForPathProvider(widget.pathId));
    final progress = ref.read(progressProvider);
    
    bool allCompleted = false;
    lessonsAsync.whenData((lessons) {
      allCompleted = lessons.every(
        (l) => progress.completedLessonIds.contains(l.id),
      );
    });

    if (allCompleted) {
      await progressNotifier.completePath(widget.pathId);
      if (mounted) {
        setState(() => _showCelebration = true);
      }
      return;
    }

    // Invalidate providers to refresh UI
    ref.invalidate(lessonLockStateProvider);
    ref.invalidate(pathLockStateProvider);
    ref.invalidate(pathProgressProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إكمال الدرس بنجاح!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop();
    }
  }
}
