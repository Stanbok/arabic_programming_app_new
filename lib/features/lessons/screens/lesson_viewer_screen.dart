import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/lesson_model.dart';
import '../../../core/services/cache_service.dart';
import '../widgets/lesson_cards/text_card.dart';
import '../widgets/lesson_cards/code_card.dart';
import '../widgets/lesson_cards/mixed_card.dart';
import '../widgets/lesson_cards/quiz_start_card.dart';
import '../../quiz/screens/quiz_screen.dart';

class LessonViewerScreen extends StatefulWidget {
  final LessonModel lesson;

  const LessonViewerScreen({
    super.key,
    required this.lesson,
  });

  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  late List<dynamic> _allCards;

  @override
  void initState() {
    super.initState();
    
    _allCards = [
      ...widget.lesson.cards,
      {'type': 'quiz_start'},
    ];
    
    final savedPosition = CacheService.getLessonPosition(widget.lesson.id);
    _currentPage = savedPosition ?? 0;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    CacheService.saveLessonPosition(widget.lesson.id, page);
  }

  void _nextPage() {
    if (_currentPage < _allCards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _startQuiz() {
    CacheService.clearLessonPosition(widget.lesson.id);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizScreen(lesson: widget.lesson),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress Dots
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _allCards.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index <= _currentPage
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          
          // Cards PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _allCards.length,
              itemBuilder: (context, index) {
                final item = _allCards[index];
                
                if (item is Map && item['type'] == 'quiz_start') {
                  return QuizStartCard(
                    questionCount: widget.lesson.quiz.length,
                    onStart: _startQuiz,
                  );
                }
                
                final card = item as LessonCard;
                
                switch (card.type) {
                  case 'text':
                    return TextLessonCard(card: card);
                  case 'code':
                    return CodeLessonCard(card: card);
                  case 'mixed':
                    return MixedLessonCard(card: card);
                  default:
                    return TextLessonCard(card: card);
                }
              },
            ),
          ),
          
          // Bottom Button
          if (_currentPage < _allCards.length - 1)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    child: const Text('التالي'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
