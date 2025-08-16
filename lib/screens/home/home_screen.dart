import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/user_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/world_map_lesson_card.dart';
import '../../models/lesson_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isInitialized = false;
  bool _isLoading = true;
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeDataInstantly();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isInitialized) {
      _refreshData();
    }
  }

  Future<void> _initializeDataInstantly() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);

    try {
      setState(() {
        _isLoading = true;
      });

      // تحميل الدروس المحلية فوراً
      await lessonProvider.loadLessons();
      
      // تحميل بيانات المستخدم إذا كان مسجل دخول
      if (authProvider.user != null && !authProvider.isGuestUser) {
        await userProvider.loadUserDataInstantly(authProvider.user!.uid);
      }

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      
      _animationController.forward();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تحميل المحتوى المحلي - بعض الميزات قد تحتاج اتصال إنترنت'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              onPressed: _initializeDataInstantly,
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);

    try {
      await lessonProvider.loadLessons(forceRefresh: true);
      
      if (authProvider.user != null && !authProvider.isGuestUser) {
        await userProvider.loadUserDataInstantly(authProvider.user!.uid);
      }
    } catch (e) {
      print('⚠️ خطأ في تحديث البيانات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: const Text('رحلة التعلم'),
            backgroundColor: const Color(0xFFF8F9FA),
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              if (!authProvider.isGuestUser)
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final user = userProvider.user;
                    return Container(
                      margin: const EdgeInsets.only(left: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.diamond,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${userProvider.totalGems}',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          body: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري التحميل الفوري...'),
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Consumer3<UserProvider, LessonProvider, AuthProvider>(
                    builder: (context, userProvider, lessonProvider, authProvider, child) {
                      final user = userProvider.user;
                      final unitsInfo = lessonProvider.getUnitsInfo(user?.completedLessons ?? []);

                      return RefreshIndicator(
                        onRefresh: _refreshData,
                        child: Container(
                          color: const Color(0xFFF8F9FA),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Section - Profile & XP
                                if (!authProvider.isGuestUser && user != null) 
                                  _buildTopSection(user, userProvider),
                                if (authProvider.isGuestUser) 
                                  _buildGuestSection(),
                                
                                const SizedBox(height: 24),
                                
                                // World Map Lessons
                                _buildWorldMapSection(unitsInfo, lessonProvider.isLoading),
                                
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            backgroundColor: Colors.white,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              if (index == 1) {
                context.push('/profile');
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'الخريطة',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'البروفايل',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopSection(user, UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: user.profileImageUrl != null
                    ? CachedNetworkImageProvider(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'المستوى ${user.level} • ${userProvider.totalXP} XP',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: user.xpForNextLevel > 0 ? user.currentLevelProgress / user.xpForNextLevel : 0.0,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: Colors.orange, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحباً أيها الضيف!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'أنشئ حساباً لحفظ تقدمك!',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.go('/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('إنشاء حساب', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldMapSection(List<UnitInfo> unitsInfo, bool isLessonsLoading) {
    if (isLessonsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (unitsInfo.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد وحدات متاحة حالياً',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _initializeDataInstantly,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة تحميل'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: unitsInfo.map((unitInfo) => _buildUnitSection(unitInfo)).toList(),
    );
  }

  Widget _buildUnitSection(UnitInfo unitInfo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: unitInfo.isUnlocked ? Colors.white : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: unitInfo.isUnlocked 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: unitInfo.isUnlocked
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${unitInfo.unit}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unitInfo.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: unitInfo.isUnlocked ? null : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: unitInfo.progress,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          unitInfo.isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unitInfo.isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 24)
                else if (!unitInfo.isUnlocked)
                  const Icon(Icons.lock, color: Colors.grey, size: 24),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lessons in spiral pattern
          if (unitInfo.isUnlocked && unitInfo.lessonsWithStatus.isNotEmpty)
            ...unitInfo.lessonsWithStatus.asMap().entries.map((entry) {
              final index = entry.key;
              final lessonWithStatus = entry.value;
              final isLeft = index % 2 == 0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    if (!isLeft) const Expanded(child: SizedBox()),
                    if (!isLeft) _buildConnectionLine(),
                    Expanded(
                      flex: 2,
                      child: WorldMapLessonCard(
                        lesson: lessonWithStatus.lesson,
                        status: lessonWithStatus.status,
                        onTap: () {
                          if (lessonWithStatus.status != LessonStatus.locked) {
                            context.push('/lesson/${lessonWithStatus.lesson.id}');
                          }
                        },
                      ),
                    ),
                    if (isLeft) _buildConnectionLine(),
                    if (isLeft) const Expanded(child: SizedBox()),
                  ],
                ),
              );
            }).toList()
          else if (!unitInfo.isUnlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 32,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أكمل الوحدة السابقة لفتح هذه الوحدة',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionLine() {
    return Container(
      width: 40,
      height: 2,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
