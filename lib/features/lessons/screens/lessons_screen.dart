import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/sync_service.dart';

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
  SyncService? _syncService;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentPathIndex = CacheService.getLastPathIndex();
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
      // 1. تحميل البيانات المحلية أولاً (Offline-First)
      _progress = CacheService.getAllLocalProgress();
      _paths = CacheService.getCachedPaths() ?? [];
      
      if (_paths.isNotEmpty) {
        _loadCurrentPathLessons();
      }

      // 2. تحديث الواجهة بالبيانات المحلية
      setState(() => _isLoading = false);

      // 3. مزامنة مع الخادم في الخلفية
      await _syncInBackground();

    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncInBackground() async {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final connectivity = context.read<ConnectivityService>();
    final userId = authService.currentUser?.uid;

    if (userId == null) return;

    _syncService = SyncService(
      firestoreService: firestoreService,
      connectivityService: connectivity,
      userId: userId,
    );

    if (!connectivity.isOnline) return;

    // التهيئة الأولى إذا لم تتم
    if (!CacheService.isInitialSyncDone()) {
      await _syncService!.initialSync();
      _paths = CacheService.getCachedPaths() ?? [];
      _loadCurrentPathLessons();
      setState(() {});
    }

    // جلب بيانات المستخدم
    _user = await firestoreService.getUser(userId);

    // مزامنة التقدم
    await _syncService!.fullSync();
    _progress = CacheService.getAllLocalProgress();

    // تحديث البيانات من الخادم
    final serverPaths = await firestoreService.getPaths();
    await CacheService.cachePaths(serverPaths);
    _paths = serverPaths;

    for (final path in _paths) {
      final lessons = await firestoreService.getLessonsForPath(path.id);
      await CacheService.cacheLessonsMetadata(path.id, lessons);
    }

    _loadCurrentPathLessons();
    setState(() {});
  }

  void _loadCurrentPathLessons() {
    if (_paths.isEmpty) return;

    _currentPathIndex = _currentPathIndex.clamp(0, _paths.length - 1);
    _currentPath = _paths[_currentPathIndex];
    _lessons = CacheService.getCachedLessonsMetadata(_currentPath!.id) ?? [];
    
    CacheService.saveLastPathIndex(_currentPathIndex);
  }

  int _getCompletedCountForCurrentPath() {
    int count = 0;
    for (final lesson in _lessons) {
      if (CacheService.isLessonCompleted(lesson.id)) {
        count++;
      }
    }
    return count;
  }

  LessonState _getLessonState(int index, model.LessonModel lesson) {
    final isCompleted = CacheService.isLessonCompleted(lesson.id);
    final isContentCached = CacheService.isLessonContentCached(lesson.id);

    if (isCompleted) return LessonState.completed;

    // الدرس الأول دائماً متاح
    if (index == 0) {
      return isContentCached ? LessonState.downloaded : LessonState.available;
    }

    // الدرس متاح إذا الدرس السابق مكتمل
    final prevLessonId = _lessons[index - 1].id;
    final prevCompleted = CacheService.isLessonCompleted(prevLessonId);
    
    if (prevCompleted) {
      return isContentCached ? LessonState.downloaded : LessonState.available;
    }

    return LessonState.locked;
  }

  bool _canShowDownloadButton(int index, LessonState state) {
    // لا نعرض زر التحميل للدروس المكتملة أو المقفلة أو المحملة
    if (state == LessonState.locked || 
        state == LessonState.completed || 
        state == LessonState.downloaded) {
      return false;
    }
    // الدرس متاح وغير محمّل = نعرض زر التحميل
    return state == LessonState.available;
  }

  void _onLessonTap(model.LessonModel lesson, LessonState state) async {
    if (state == LessonState.locked) return;

    final isContentCached = CacheService.isLessonContentCached(lesson.id);
    final connectivity = context.read<ConnectivityService>();

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
      // الدرس غير محمّل ومتصل = نطلب التحميل
      _onDownloadTap(lesson);
      return;
    }

    // الدرس محمّل = نفتحه
    final cachedLesson = CacheService.getCachedFullLesson(lesson.id);
    if (cachedLesson == null) return;

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => LessonViewerScreen(lesson: cachedLesson),
      ),
    );

    _progress = CacheService.getAllLocalProgress();
    setState(() {});

    if (result == 'completed') {
      _checkPathCompletion();
    }
  }

  void _checkPathCompletion() {
    final allCompleted = _lessons.every(
      (lesson) => CacheService.isLessonCompleted(lesson.id),
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
    if (_user?.isPremium == true) {
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
      final fullLesson = await firestoreService.getLesson(lesson.id);

      if (fullLesson != null) {
        await CacheService.cacheFullLesson(fullLesson);

        final authService = context.read<AuthService>();
        final userId = authService.currentUser?.uid;
        if (userId != null) {
          await firestoreService.recordDownload(userId, lesson.id, lesson.title);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        setState(() {});

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
      _currentPathIndex--;
      _loadCurrentPathLessons();
      setState(() {});
      _scrollToTop();
    }
  }

  void _navigateToNextPath() {
    if (_currentPathIndex + 1 < _paths.length) {
      _currentPathIndex++;
      _loadCurrentPathLessons();
      setState(() {});
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _onRefresh() async {
    await _syncInBackground();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _paths.isEmpty) {
      return const Scaffold(body: LoadingWidget(message: 'جاري التحميل...'));
    }

    if (_paths.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text(
                'لا توجد بيانات متاحة',
                style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              const Text(
                'يرجى الاتصال بالإنترنت للتحميل الأولي',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
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
                      final showDownload = _canShowDownloadButton(index, state);

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
                          onDownload: showDownload ? () => _onDownloadTap(lesson) : null,
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
              // السهم الأيمن = المسار السابق (في RTL)
              IconButton(
                onPressed: canGoBack ? _navigateToPreviousPath : null,
                icon: Icon(
                  Icons.chevron_right,
                  color: canGoBack ? Colors.white : Colors.white38,
                  size: 32,
                ),
                tooltip: 'المسار السابق',
              ),

              // السهم الأيسر = المسار التالي (في RTL)
              IconButton(
                onPressed: canGoForward ? _navigateToNextPath : null,
                icon: Icon(
                  Icons.chevron_left,
                  color: canGoForward ? Colors.white : Colors.white38,
                  size: 32,
                ),
                tooltip: 'المسار التالي',
              ),
            ],
          ),

          const SizedBox(height: 8),

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
