import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/cache_service.dart';

// Models
import '../../../core/models/path_model.dart';
import '../../../core/models/lesson_model.dart' as model;
import '../../../core/models/progress_model.dart';
import '../../../core/models/user_model.dart';

// Widgets
import '../../../core/widgets/loading_widget.dart';
import '../widgets/lesson_card.dart';
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
  bool _isInitialLoad = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentPathIndex = CacheService.getLastPathIndex();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = context.read<AuthService>();
      final firestoreService = context.read<FirestoreService>();
      final connectivity = context.read<ConnectivityService>();
      final userId = authService.currentUser?.uid;
      
      if (userId == null) return;

      _progress = CacheService.getAllLocalProgress();

      _paths = CacheService.getCachedPaths() ?? [];

      if (connectivity.isOnline) {
        // جلب من الإنترنت
        final serverPaths = await firestoreService.getPaths();
        _user = await firestoreService.getUser(userId);
        final serverProgress = await firestoreService.getUserProgress(userId);
        
        // تخزين المسارات محلياً
        await CacheService.cachePaths(serverPaths);
        _paths = serverPaths;
        
        // دمج التقدم
        await CacheService.mergeProgress(serverProgress);
        _progress = CacheService.getAllLocalProgress();

        for (final path in _paths) {
          if (!CacheService.hasLessonsMetadata(path.id)) {
            final lessons = await firestoreService.getLessonsForPath(path.id);
            await CacheService.cacheLessonsMetadata(path.id, lessons);
            
            // تحميل صور الدروس
            for (final lesson in lessons) {
              if (lesson.thumbnailUrl.isNotEmpty) {
                _cacheImageInBackground(lesson.thumbnailUrl);
              }
            }
          }
        }
      }

      // تحميل دروس المسار الحالي
      await _loadCurrentPathLessons();

      setState(() {
        _isLoading = false;
        _isInitialLoad = false;
      });

      _scrollToCurrentLesson();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isInitialLoad = false;
      });
    }
  }

  Future<void> _loadCurrentPathLessons() async {
    if (_paths.isEmpty) return;
    
    _currentPath = _currentPathIndex < _paths.length 
        ? _paths[_currentPathIndex] 
        : _paths.first;

    // جلب الدروس من الكاش (البيانات الوصفية فقط)
    _lessons = CacheService.getCachedLessonsMetadata(_currentPath!.id) ?? [];

    // إذا لم تتوفر في الكاش ومتصل بالإنترنت
    if (_lessons.isEmpty) {
      final connectivity = context.read<ConnectivityService>();
      if (connectivity.isOnline) {
        final firestoreService = context.read<FirestoreService>();
        final lessons = await firestoreService.getLessonsForPath(_currentPath!.id);
        await CacheService.cacheLessonsMetadata(_currentPath!.id, lessons);
        _lessons = CacheService.getCachedLessonsMetadata(_currentPath!.id) ?? [];
      }
    }

    // حفظ المسار الحالي
    await CacheService.saveLastPathIndex(_currentPathIndex);
  }

  void _cacheImageInBackground(String url) async {
    if (CacheService.isImageCached(url)) return;
    // يمكن إضافة منطق تحميل الصورة هنا
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

  int _getCompletedCountForCurrentPath() {
    int count = 0;
    for (final lesson in _lessons) {
      if (_progress[lesson.id]?.completed ?? false) {
        count++;
      }
    }
    return count;
  }

  LessonState _getLessonState(int index, model.LessonModel lesson) {
    final isCompleted = _progress[lesson.id]?.completed ?? false;
    final isContentCached = CacheService.isLessonContentCached(lesson.id);
    
    // إذا مكتمل
    if (isCompleted) return LessonState.completed;
    
    // الدرس الأول دائماً متاح
    if (index == 0) {
      return isContentCached ? LessonState.downloaded : LessonState.available;
    }
    
    // الدرس متاح إذا كان الدرس السابق مكتمل
    final prevCompleted = _progress[_lessons[index - 1].id]?.completed ?? false;
    if (prevCompleted) {
      return isContentCached ? LessonState.downloaded : LessonState.available;
    }
    
    return LessonState.locked;
  }

  void _onLessonTap(model.LessonModel lesson, LessonState state) async {
    if (state == LessonState.locked) return;

    final connectivity = context.read<ConnectivityService>();
    final isContentCached = CacheService.isLessonContentCached(lesson.id);

    if (!isContentCached) {
      if (!connectivity.isOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب تحميل الدرس أولاً للعمل دون إنترنت'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      // إذا كان متصل لكن المحتوى غير محمّل، نطلب التحميل
      _onDownloadTap(lesson);
      return;
    }

    // الدخول للدرس المحمّل
    final cachedLesson = CacheService.getCachedFullLesson(lesson.id);
    if (cachedLesson == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonViewerScreen(lesson: cachedLesson),
      ),
    );

    if (result == 'completed') {
      await _refreshProgress();
      _checkPathCompletion();
    }
  }

  Future<void> _refreshProgress() async {
    _progress = CacheService.getAllLocalProgress();
    setState(() {});
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
                _navigateToNextPath();
              }
            },
            onShare: () {
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
    if (_user == null) {
      // للمستخدمين غير المسجلين
      _showDownloadSheet(lesson);
      return;
    }

    if (_user!.isPremium) {
      _downloadLesson(lesson);
      return;
    }

    _showDownloadSheet(lesson);
  }

  void _showDownloadSheet(model.LessonModel lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DownloadSheet(
        lesson: lesson,
        isPremium: _user?.isPremium ?? false,
        onSubscribe: _showPremiumScreen,
        onWatchAd: () => _watchAdAndDownload(lesson),
      ),
    );
  }

  void _showPremiumScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PremiumScreen()),
    ).then((_) => _loadInitialData());
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
    final connectivity = context.read<ConnectivityService>();
    
    if (!connectivity.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يتطلب الاتصال بالإنترنت للتحميل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // عرض مؤشر التحميل
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
                  Text('جاري تحميل الدرس...'),
                ],
              ),
            ),
          ),
        ),
      );

      final firestoreService = context.read<FirestoreService>();
      
      // جلب المحتوى الكامل من الخادم
      final fullLesson = await firestoreService.getLesson(lesson.id);
      
      if (fullLesson != null) {
        // حفظ المحتوى الكامل محلياً
        await CacheService.cacheFullLesson(fullLesson);
        
        // تسجيل التحميل في الخادم
        final authService = context.read<AuthService>();
        final userId = authService.currentUser?.uid;
        if (userId != null) {
          await firestoreService.recordDownload(userId, lesson.id, lesson.title);
        }
      }

      if (mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل
        setState(() {}); // تحديث الواجهة
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحميل الدرس بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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
      _loadCurrentPathLessons().then((_) {
        setState(() {});
        _scrollToCurrentLesson();
      });
    }
  }

  void _navigateToNextPath() {
    if (_currentPathIndex + 1 < _paths.length) {
      setState(() => _currentPathIndex++);
      _loadCurrentPathLessons().then((_) {
        setState(() {});
        _scrollToCurrentLesson();
      });
    }
  }

  Future<void> _onRefresh() async {
    final connectivity = context.read<ConnectivityService>();
    if (connectivity.isOnline) {
      await _loadInitialData();
    } else {
      await _refreshProgress();
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
          onRefresh: _onRefresh,
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
                          onDownload: (state == LessonState.available)
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
    final completedCount = _getCompletedCountForCurrentPath();
    final totalLessons = _lessons.length;
    final progress = totalLessons == 0 ? 0.0 : completedCount / totalLessons;
    final canGoBack = _currentPathIndex > 0;
    final canGoForward = _currentPathIndex + 1 < _paths.length;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
          
          const SizedBox(height: 8),
          
          // المحتوى
          Row(
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
          
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt().clamp(0, 100)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$completedCount من $totalLessons درس مكتمل',
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
