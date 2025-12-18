import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../models/card_model.dart';
import '../../../models/lesson_model.dart';
import '../../../providers/lesson_viewer_provider.dart';
import '../../../providers/lessons_provider.dart';
import '../widgets/cards/explanation_card.dart';
import '../widgets/cards/summary_card.dart';
import '../widgets/cards/quiz_card.dart';
import '../widgets/lesson_progress_bar.dart';

class LessonViewerScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonViewerScreen({super.key, required this.lessonId});

  @override
  ConsumerState<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends ConsumerState<LessonViewerScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(currentCardIndexProvider.notifier).state = index;
  }

  void _goToNextCard(List<LessonCard> cards) {
    final currentIndex = ref.read(currentCardIndexProvider);
    if (currentIndex < cards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showCompletionDialog();
    }
  }

  void _goToPreviousCard() {
    final currentIndex = ref.read(currentCardIndexProvider);
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showCompletionDialog() {
    final quizResult = ref.read(quizResultProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              quizResult?.passed ?? true ? Icons.celebration : Icons.refresh,
              size: 64,
              color: quizResult?.passed ?? true ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              quizResult?.passed ?? true ? 'أحسنت! 🎉' : 'حاول مرة أخرى',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (quizResult != null)
              Text(
                'النتيجة: ${quizResult.correct}/${quizResult.total}',
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go(RouteNames.main);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'العودة للدروس',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _markLessonComplete();
                      context.go(RouteNames.main);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إنهاء الدرس',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _markLessonComplete() {
    ref.read(lessonsServiceProvider).updateLessonProgress(
      lessonId: widget.lessonId,
      completed: true,
      lastCardIndex: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(lessonCardsProvider(widget.lessonId));
    final currentIndex = ref.watch(currentCardIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => _showExitDialog(),
        ),
        title: cardsAsync.when(
          data: (cards) => LessonProgressBar(
            current: currentIndex + 1,
            total: cards.length,
          ),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
        centerTitle: true,
      ),
      body: cardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد بطاقات في هذا الدرس',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildCard(card, cards),
                    );
                  },
                ),
              ),
              _buildNavigationButtons(cards, currentIndex),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                AppStrings.errorOccurred,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(lessonCardsProvider(widget.lessonId)),
                child: Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(LessonCard card, List<LessonCard> allCards) {
    switch (card.cardType) {
      case CardType.explanation:
        return ExplanationCard(card: card);
      case CardType.summary:
        return SummaryCard(card: card);
      case CardType.quiz:
        return QuizCard(
          card: card,
          onComplete: () => _goToNextCard(allCards),
        );
    }
  }

  Widget _buildNavigationButtons(List<LessonCard> cards, int currentIndex) {
    final isFirstCard = currentIndex == 0;
    final isLastCard = currentIndex == cards.length - 1;
    final currentCard = cards[currentIndex];
    final isQuizCard = currentCard.cardType == CardType.quiz;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isFirstCard)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _goToPreviousCard,
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  label: const Text('السابق'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.textHint),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (!isFirstCard && !isQuizCard) const SizedBox(width: 12),
            if (!isQuizCard)
              Expanded(
                flex: isFirstCard ? 1 : 1,
                child: ElevatedButton.icon(
                  onPressed: () => _goToNextCard(cards),
                  icon: Icon(
                    isLastCard ? Icons.check : Icons.arrow_back,
                    size: 20,
                  ),
                  label: Text(isLastCard ? 'إنهاء' : 'التالي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'الخروج من الدرس؟',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'سيتم حفظ تقدمك تلقائياً',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('البقاء', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveProgress();
              context.go(RouteNames.main);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveProgress() {
    final currentIndex = ref.read(currentCardIndexProvider);
    ref.read(lessonsServiceProvider).updateLessonProgress(
      lessonId: widget.lessonId,
      completed: false,
      lastCardIndex: currentIndex,
    );
  }
}
