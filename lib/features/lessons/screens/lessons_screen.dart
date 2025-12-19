import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/cache_service.dart';

// Models (alias for LessonCard model)
import '../../../core/models/path_model.dart';
import '../../../core/models/lesson_model.dart' as model;
import '../../../core/models/progress_model.dart';
import '../../../core/models/user_model.dart';

// Widgets
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/no_internet_popup.dart';
import '../widgets/lesson_card.dart'; // Widget version
import '../widgets/download_sheet.dart';

// Screens
import '../../premium/screens/premium_screen.dart';
import 'lesson_viewer_screen.dart';
import 'path_completion_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  List<PathModel> _paths = [];
  List<model.LessonModel> _lessons = [];
  Map<String, ProgressModel> _progress = {};
  UserModel? _user;
  PathModel? _currentPath;
  int _currentPathIndex = 0;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = context.read<AuthService>();
      final firestoreService = context.read<FirestoreService>();
      final connectivity = context.read<ConnectivityService>();
      final userId = authService.currentUser?.uid;
      
      if (userId == null) return;

      // التحقق من الاتصال قبل جلب البيانات
      if (!connectivity.isOnline) {
        _showNoInternetPopup();
        setState(() => _isLoading = false);
        return;
      }

      final paths = await firestoreService.getPaths();
      final user = await firestoreService.getUser(userId);
      final progress = await firestoreService.getUserProgress(userId);

      if (paths.isNotEmpty) {
        final currentPath = _currentPathIndex < paths.length 
            ? paths[_currentPathIndex] 
            : paths.first;
        final lessons = await firestoreService.getLessonsForPath(currentPath.id);
        
        setState(() {
          _paths = paths;
          _currentPath = currentPath;
          _lessons = lessons;
          _progress = progress;
          _user = user;
          _isLoading = false;
        });

        _scrollToCurrentLesson();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // عرض popup فقط إذا كان خطأ شبكة
      final connectivity = context.read<ConnectivityService>();
      if (!connectivity.isOnline) {
        _showNoInternetPopup();
      }
      setState(() => _isLoading = false);
    }
  }

  void _showNoInternetPopup() {
    NoInternetPopup.show(
      context: context,
      onRetry: _loadData,
      onDismiss: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }

  void _scrollToCurrentLesson() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentIndex = _findCurrentLessonIndex();
      if (currentIndex > 0 && _scrollController.hasClients) {
        _scrollController.animateTo(
          currentIndex * 140.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  int _findCurrentLessonIndex() {
    for (int i = 0; i < _lessons.length; i++) {
      if (!(_progress[_lessons[i].id]?.completed ?? false)) {
        return i;
      }
    }
    return _lessons.length - 1;
  }

  LessonState _getLessonState(int index, model.LessonModel lesson) {
    final isCompleted = _progress[lesson.id]?.completed ?? false;
    final isCached = CacheService.isLessonCached(lesson.id);
    
    if (isCompleted) return LessonState.completed;
    if (index == 0) return isCached ? LessonState.downloaded : LessonState.available;
    
    final prevCompleted = _progress[_lessons[index - 1].id]?.completed ?? false;
    if (prevCompleted) return isCached ? LessonState.downloaded : LessonState.available;
    
    return LessonState.locked;
  }

  void _onLessonTap(model.LessonModel lesson, LessonState state) async {
    if (state == LessonState.locked) return;

    final connectivity = context.read<ConnectivityService>();
    final isCached = CacheService.isLessonCached(lesson.id);

    // عرض popup فقط إذا لم يكن محفوظاً محلياً
    if (!connectivity.isOnline && !isCached) {
      _showNoInternetPopup();
      return;
    }

    // الانتقال للدرس بدون تخزين تلقائي
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonViewerScreen(
          lesson: isCached ? CacheService.getCachedLesson(lesson.id)! : lesson,
        ),
      ),
    );

    if (result == 'completed') {
      await _loadData();
      _checkPathCompletion();
    }
  }

  void _checkPathCompletion() {
    final allCompleted = _lessons.every(
      (lesson) => _progress[lesson.id]?.completed ?? false,
    );

    if (allCompleted && _currentPath != null) {
      final totalQuestions = _lessons.fold<int>(
        0,
        (sum, lesson) => sum + lesson.quiz.length,
      );

      final nextPath = _currentPathIndex + 1 < _paths.length
          ? _paths[_currentPathIndex + 1]
          : null;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PathCompletionScreen(
            completedPath: _currentPath!,
            nextPath: nextPath,
            totalLessons: _lessons.length,
            totalQuestions: totalQuestions,
            onContinue: () {
              Navigator.pop(context);
              if (nextPath != null) {
                setState(() => _currentPathIndex++);
                _loadData();
              }
            },
            onShare: () {
              // TODO: تنفيذ المشاركة
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('سيتم إضافة المشاركة قريباً')),
              );
            },
          ),
        ),
      );
    }
  }

  void _onDownloadTap(model.LessonModel lesson) {
    if (_user == null) return;

    if (_user!.isPremium) {
      _downloadLesson(lesson);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DownloadSheet(
        lesson: lesson,
        isPremium: _user!.isPremium,
        onSubscribe: _showPremiumScreen,
        onWatchAd: () => _watchAdAndDownload(lesson),
      ),
    );
  }

  void _showPremiumScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PremiumScreen()),
    ).then((_) => _loadData());
  }

  Future<void> _watchAdAndDownload(model.LessonModel lesson) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري تحميل الإعلان...'),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.pop(context);
      _downloadLesson(lesson);
    }
  }

  Future<void> _downloadLesson(model.LessonModel lesson) async {
    try {
      final authService = context.read<AuthService>();
      final firestoreService = context.read<FirestoreService>();
      final userId = authService.currentUser!.uid;

      await CacheService.cacheLesson(lesson);
      await firestoreService.recordDownload(userId, lesson.id, lesson.title);

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحميل الدرس بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل تحميل الدرس'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToPreviousPath() {
    if (_currentPathIndex > 0) {
      setState(() => _currentPathIndex--);
      _loadData();
    }
  }

  void _navigateToNextPath() {
    // السماح بالانتقال فقط للمسارات المكتملة
    final allCompleted = _lessons.every(
      (lesson) => _progress[lesson.id]?.completed ?? false,
    );
    
    if (allCompleted && _currentPathIndex + 1 < _paths.length) {
      setState(() => _currentPathIndex++);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget(message: 'جاري التحميل...'));
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final lesson = _lessons[index];
                      final state = _getLessonState(index, lesson);
                      final isLeft = index % 2 == 0;
                      
                      return Padding(
                        padding: EdgeInsets.only(
                          right: isLeft ? 0 : 80,
                          left: isLeft ? 80 : 0,
                          bottom: 16,
                        ),
                        child: LessonCard(
                          lesson: lesson,
                          state: state,
                          index: index + 1,
                          onTap: () => _onLessonTap(lesson, state),
                          onDownload: state == LessonState.available
                              ? () => _onDownloadTap(lesson)
                              : null,
                        ),
                      );
                    },
                    childCount: _lessons.length,
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final completedCount = _progress.values.where((p) => p.completed).length;
    final progress = _lessons.isEmpty ? 0.0 : completedCount / _lessons.length;
    final canGoBack = _currentPathIndex > 0;
    final canGoForward = _currentPathIndex + 1 < _paths.length &&
        _lessons.every((lesson) => _progress[lesson.id]?.completed ?? false);

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // زر السابق
                  if (canGoBack)
                    IconButton(
                      onPressed: _navigateToPreviousPath,
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 32,
                      ),
                      tooltip: 'المسار السابق',
                    )
                  else
                    const SizedBox(width: 48),
                  
                  const Spacer(),
                  
                  // زر التالي
                  if (canGoForward)
                    IconButton(
                      onPressed: _navigateToNextPath,
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 32,
                      ),
                      tooltip: 'المسار التالي',
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
              
              // المحتوى الأصلي
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentPath?.name ?? 'مسار التعلم',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentPath?.description ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (_user?.isPremium == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: Colors.amber,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'VIP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$completedCount من ${_lessons.length} درس مكتمل',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
