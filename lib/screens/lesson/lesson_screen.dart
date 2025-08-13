import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../providers/lesson_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/lesson_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/code_block_widget.dart';
import '../../widgets/mixed_text_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _loadLesson();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _saveTimeSpent();
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
    }
  }

  Future<void> _saveTimeSpent() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null && _timeSpent > 0) {
      try {
        await FirebaseService.updateTimeSpent(
          authProvider.user!.uid,
          widget.lessonId,
          _timeSpent,
        );
      } catch (e) {
        // Handle error silently for time tracking
      }
    }
  }

  Future<void> _completeSlide(String slideId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await lessonProvider.completeSlide(
        authProvider.user!.uid,
        widget.lessonId,
        slideId,
      );
      
      // Log analytics
      await FirebaseService.logSlideCompletion(
        authProvider.user!.uid,
        widget.lessonId,
        slideId,
      );
    }
  }

  Future<void> _completeLesson() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await lessonProvider.completeLesson(authProvider.user!.uid, widget.lessonId);
      
      // Check and update level
      await FirebaseService.checkAndUpdateLevel(authProvider.user!.uid);
      
      setState(() {
        _isCompleted = true;
      });
    }
  }

  void _nextSlide() {
    if (_currentSlideIndex < _getCurrentLesson()!.slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousSlide() {
    if (_currentSlideIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  LessonModel? _getCurrentLesson() {
    return Provider.of<LessonProvider>(context, listen: false).currentLesson;
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
          final progress = lessonProvider.currentProgress;

          if (lesson == null) {
            return const Center(
              child: Text('لم يتم العثور على الدرس'),
            );
          }

          if (_isCompleted) {
            return _buildCompletionScreen(lesson);
          }

          return Column(
            children: [
              // Progress Bar
              _buildProgressBar(lesson, progress?.slidesCompleted ?? []),
              
              // Slide Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentSlideIndex = index;
                    });
                  },
                  itemCount: lesson.slides.length,
                  itemBuilder: (context, index) {
                    return _buildSlideContent(lesson.slides[index]);
                  },
                ),
              ),
              
              // Navigation Controls
              _buildNavigationControls(lesson),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(LessonModel lesson, List<String> completedSlides) {
    final progress = completedSlides.length / lesson.slides.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الشريحة ${_currentSlideIndex + 1} من ${lesson.slides.length}',
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
          
          const SizedBox(height: 8),
          
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideContent(SlideModel slide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slide Title
          MixedTextWidget(
            text: slide.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Slide Image
          if (slide.imageUrl != null)
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: slide.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ),
          
          // Slide Content
          MixedTextWidget(
            text: slide.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Code Example
          if (slide.codeExample != null)
            CodeBlockWidget(
              code: slide.codeExample!,
              language: 'python',
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls(LessonModel lesson) {
    final isLastSlide = _currentSlideIndex == lesson.slides.length - 1;
    final currentSlide = lesson.slides[_currentSlideIndex];
    final progress = Provider.of<LessonProvider>(context).currentProgress;
    final isSlideCompleted = progress?.slidesCompleted.contains(currentSlide.id) ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Button
          if (_currentSlideIndex > 0)
            Expanded(
              child: CustomButton(
                text: 'السابق',
                onPressed: _previousSlide,
                isOutlined: true,
                icon: Icons.arrow_back_ios,
              ),
            ),
          
          if (_currentSlideIndex > 0) const SizedBox(width: 12),
          
          // Complete Slide / Next Button
          Expanded(
            flex: 2,
            child: !isSlideCompleted
                ? CustomButton(
                    text: 'إكمال الشريحة',
                    onPressed: () => _completeSlide(currentSlide.id),
                    icon: Icons.check,
                  )
                : isLastSlide
                    ? CustomButton(
                        text: 'إنهاء الدرس',
                        onPressed: _completeLesson,
                        icon: Icons.flag,
                      )
                    : CustomButton(
                        text: 'التالي',
                        onPressed: _nextSlide,
                        icon: Icons.arrow_forward_ios,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen(LessonModel lesson) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Congratulations Animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              size: 60,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'تهانينا! 🎉',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'لقد أكملت درس "${lesson.title}" بنجاح',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'ملخص الدرس',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      icon: Icons.timer,
                      label: 'الوقت المستغرق',
                      value: '${(_timeSpent / 60).ceil()} دقيقة',
                    ),
                    _buildSummaryItem(
                      icon: Icons.star,
                      label: 'النقاط المكتسبة',
                      value: '${lesson.xpReward} XP',
                    ),
                    _buildSummaryItem(
                      icon: Icons.diamond,
                      label: 'الجواهر',
                      value: '${lesson.gemsReward}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action Buttons
          Column(
            children: [
              if (lesson.quiz.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'ابدأ الاختبار',
                    onPressed: () => context.push('/quiz/${lesson.id}'),
                    icon: Icons.quiz,
                  ),
                ),
              
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'العودة للرئيسية',
                  onPressed: () => context.go('/home'),
                  isOutlined: true,
                  icon: Icons.home,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
