import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../providers/lesson_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/lesson_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/code_block_widget.dart';
import '../../widgets/mixed_text_widget.dart';
import '../../widgets/progressive_content_viewer.dart';
import '../../widgets/lesson_summary_slide.dart';

class LessonScreen extends StatefulWidget {
  final String lessonId;

  const LessonScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  PageController _pageController = PageController();
  int _currentSlideIndex = 0;
  Timer? _timer;
  int _timeSpent = 0;
  bool _isCompleted = false;
  Set<int> _viewedSlides = {};
  bool _canSwipeToNext = false;
  bool _currentSlideCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadLesson();
    _startTimer();
    _viewedSlides.add(0); // إضافة السلايد الأول كمقروء
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeSpent++;
      });
    });
  }

  Future<void> _loadLesson() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await lessonProvider.loadLesson(widget.lessonId, authProvider.user!.uid);
    } else {
      // للضيوف - تحميل الدرس فقط
      await lessonProvider.loadLesson(widget.lessonId, 'guest');
    }
  }

  void _nextSlide() {
    final lesson = _getCurrentLesson();
    if (lesson != null) {
      _viewedSlides.add(_currentSlideIndex);
      
      if (_currentSlideIndex < lesson.slides.length) {
        final nextIndex = _currentSlideIndex + 1;
        _viewedSlides.add(nextIndex);
        
        setState(() {
          _canSwipeToNext = true;
        });
        
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  void _goToSlide(int index) {
    if (_viewedSlides.contains(index)) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onSlideCompleted() {
    setState(() {
      _currentSlideCompleted = true;
      _canSwipeToNext = true;
    });
  }

  bool _canSwipeToPage(int targetIndex) {
    if (targetIndex < _currentSlideIndex) {
      return _viewedSlides.contains(targetIndex);
    }
    
    if (targetIndex == _currentSlideIndex + 1) {
      return _currentSlideCompleted && _canSwipeToNext;
    }
    
    return false;
  }

  void _finishLesson() {
    final lesson = _getCurrentLesson();
    if (lesson != null) {
      setState(() {
        _isCompleted = true;
      });
    }
  }

  LessonModel? _getCurrentLesson() {
    return Provider.of<LessonProvider>(context, listen: false).currentLesson;
  }

  List<String> _generateKeyPoints(LessonModel lesson) {
    if (lesson.summary != null && lesson.summary!.keyPoints.isNotEmpty) {
      return lesson.summary!.keyPoints;
    }
    
    List<String> keyPoints = [];
    
    for (final slide in lesson.slides) {
      final content = slide.content.toLowerCase();
      
      if (content.contains('مهم') || content.contains('أساسي') || content.contains('رئيسي')) {
        final sentences = slide.content.split('.');
        for (final sentence in sentences) {
          if (sentence.toLowerCase().contains('مهم') || 
              sentence.toLowerCase().contains('أساسي') || 
              sentence.toLowerCase().contains('رئيسي')) {
            keyPoints.add(sentence.trim());
            break;
          }
        }
      }
    }
    
    if (keyPoints.isEmpty) {
      for (final slide in lesson.slides.take(5)) {
        final firstSentence = slide.content.split('.').first.trim();
        if (firstSentence.isNotEmpty && firstSentence.length > 20) {
          keyPoints.add(firstSentence);
        }
      }
    }
    
    if (keyPoints.isEmpty) {
      keyPoints = [
        'تعلمت أساسيات البرمجة بـ Python',
        'فهمت كيفية كتابة الكود بشكل صحيح',
        'تطبقت المفاهيم من خلال الأمثلة العملية',
        'أصبحت جاهزاً للانتقال للمستوى التالي',
      ];
    }
    
    return keyPoints.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LessonProvider>(
          builder: (context, lessonProvider, child) {
            final lesson = lessonProvider.currentLesson;
            return Text(lesson?.title ?? 'جاري التحميل...');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Consumer<LessonProvider>(
        builder: (context, lessonProvider, child) {
          if (lessonProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final lesson = lessonProvider.currentLesson;

          if (lesson == null) {
            return const Center(
              child: Text('لم يتم العثور على الدرس'),
            );
          }

          return Column(
            children: [
              _buildInteractiveProgressBar(lesson),
              
              Expanded(
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if (details.delta.dx > 0) {
                      final targetIndex = _currentSlideIndex - 1;
                      if (targetIndex >= 0 && !_canSwipeToPage(targetIndex)) {
                        return;
                      }
                    } else if (details.delta.dx < 0) {
                      final targetIndex = _currentSlideIndex + 1;
                      if (!_canSwipeToPage(targetIndex)) {
                        _showSwipeHint();
                        return;
                      }
                    }
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentSlideIndex = index;
                        _currentSlideCompleted = _viewedSlides.contains(index);
                        _canSwipeToNext = _currentSlideCompleted;
                      });
                    },
                    physics: _buildPageScrollPhysics(),
                    itemCount: lesson.slides.length + 1,
                    itemBuilder: (context, index) {
                      if (index < lesson.slides.length) {
                        return ProgressiveContentViewer(
                          title: lesson.slides[index].title,
                          content: lesson.slides[index].content,
                          imageUrl: lesson.slides[index].imageUrl,
                          codeExample: lesson.slides[index].codeExample,
                          isLastSlide: index == lesson.slides.length - 1,
                          onCompleted: () {
                            _onSlideCompleted();
                            _nextSlide();
                          },
                        );
                      } else {
                        return LessonSummarySlide(
                          lesson: lesson,
                          timeSpent: _timeSpent,
                          onStartQuiz: lesson.quiz.isNotEmpty 
                              ? () => context.push('/quiz/${lesson.id}')
                              : null,
                          onGoHome: () => context.go('/home'),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  ScrollPhysics _buildPageScrollPhysics() {
    return CustomPageScrollPhysics(
      canScrollToNext: _canSwipeToNext,
      canScrollToPrevious: _currentSlideIndex > 0 && _viewedSlides.length > 1,
    );
  }

  void _showSwipeHint() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'يجب إكمال قراءة الشريحة الحالية أولاً',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[600],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildInteractiveProgressBar(LessonModel lesson) {
    final totalSlides = lesson.slides.length + 1;
    final progress = (_currentSlideIndex + 1) / totalSlides;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentSlideIndex < lesson.slides.length 
                    ? 'الشريحة ${_currentSlideIndex + 1} من ${lesson.slides.length}'
                    : 'ملخص الدرس',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                
                Row(
                  children: List.generate(totalSlides, (index) {
                    final isViewed = _viewedSlides.contains(index);
                    final isCurrent = index == _currentSlideIndex;
                    final canNavigate = isViewed;
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: canNavigate ? () => _goToSlide(index) : null,
                        child: Container(
                          height: 8,
                          margin: EdgeInsets.only(
                            right: index < totalSlides - 1 ? 2 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : isViewed
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.6)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: canNavigate
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: isCurrent
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  margin: const EdgeInsets.all(2),
                                )
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_viewedSlides.length > 1) ...[
                Icon(
                  Icons.swipe,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'مرر للتنقل بين الشرائح المقروءة',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.touch_app,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'انقر في أي مكان للمتابعة',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class CustomPageScrollPhysics extends ScrollPhysics {
  final bool canScrollToNext;
  final bool canScrollToPrevious;

  const CustomPageScrollPhysics({
    super.parent,
    required this.canScrollToNext,
    required this.canScrollToPrevious,
  });

  @override
  CustomPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageScrollPhysics(
      parent: buildParent(ancestor),
      canScrollToNext: canScrollToNext,
      canScrollToPrevious: canScrollToPrevious,
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (offset < 0 && !canScrollToNext) {
      return 0.0;
    }
    if (offset > 0 && !canScrollToPrevious) {
      return 0.0;
    }
    
    return super.applyPhysicsToUserOffset(position, offset);
  }
}
