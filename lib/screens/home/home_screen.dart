import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/user_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/xp_bar.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/level_test_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isInitialized = false;
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDataInstantly();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

      print('🚀 بدء التحميل الفوري...');

      // المرحلة 1: تحميل الدروس المحلية فوراً (أولوية قصوى)
      await lessonProvider.loadLessons();
      
      // المرحلة 2: تحميل بيانات المستخدم إذا كان مسجل دخول
      if (authProvider.user != null && !authProvider.isGuestUser) {
        print('👤 المستخدم: ${authProvider.user!.uid}');
        
        // تحميل فوري لبيانات المستخدم
        await userProvider.loadUserDataInstantly(authProvider.user!.uid);
      }

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      
      print('✅ تم التحميل الفوري بنجاح');
      
    } catch (e) {
      print('❌ خطأ في التحميل الفوري: $e');
      setState(() {
        _isLoading = false;
      });
      
      // عرض رسالة خطأ مبسطة
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
      // إعادة تحميل الدروس
      await lessonProvider.loadLessons(forceRefresh: true);
      
      // إعادة تحميل بيانات المستخدم إذا كان مسجل دخول
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
          backgroundColor: Colors.white, // خلفية بيضاء ثابتة
          appBar: AppBar(
            title: const Text('الرئيسية'),
            backgroundColor: Colors.white,
            elevation: 0,
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
              : Consumer3<UserProvider, LessonProvider, AuthProvider>(
                  builder: (context, userProvider, lessonProvider, authProvider, child) {
                    final user = userProvider.user;
                    
                    final availableLessons = lessonProvider.getAvailableLessons(
                      user?.completedLessons ?? [],
                      user?.currentLevel ?? 1,
                    );

                    return RefreshIndicator(
                      onRefresh: _refreshData,
                      child: Container(
                        color: Colors.white, // خلفية بيضاء
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
                              
                              // Welcome Message
                              _buildWelcomeMessage(user),
                              
                              const SizedBox(height: 24),
                              
                              // Lessons Grid - متاح لجميع المستخدمين
                              _buildLessonsSection(availableLessons, user, lessonProvider.isLoading),
                              
                              const SizedBox(height: 24),
                              
                              // Level Test Button
                              if (!authProvider.isGuestUser && user != null) 
                                _buildLevelTestSection(user, availableLessons),
                              
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          bottomNavigationBar: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (!authProvider.isGuestUser) {
                return BottomNavigationBar(
                  currentIndex: _currentIndex,
                  backgroundColor: Colors.white,
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
                      icon: Icon(Icons.home),
                      label: 'الرئيسية',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'البروفايل',
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
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
              // Profile Image
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: user.profileImageUrl != null
                        ? CachedNetworkImageProvider(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  // Online indicator
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'المستوى ${user.level}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Gems (including local gems)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.diamond,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${userProvider.totalGems}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // XP Bar (including local XP)
          XPBar(
            currentXP: user.currentLevelProgress + (userProvider.totalXP - user.xp),
            maxXP: user.xpForNextLevel,
            level: user.level,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage(user) {
    final timeOfDay = DateTime.now().hour;
    String greeting;
    String emoji;
    
    if (timeOfDay < 12) {
      greeting = 'صباح الخير';
      emoji = '🌅';
    } else if (timeOfDay < 17) {
      greeting = 'مساء الخير';
      emoji = '☀️';
    } else {
      greeting = 'مساء الخير';
      emoji = '🌙';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user != null
                      ? '$greeting، ${user.name}!'
                      : 'مرحباً! ابدأ تعلمك الآن.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user != null
                ? 'أنت في المستوى ${user.level}. لديك ${user.completedLessons.length} درس مكتمل. استمر في التعلم!'
                : 'ابدأ رحلتك التعليمية مع الدروس المحلية المتاحة.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsSection(List availableLessons, user, bool isLessonsLoading) {
    return Container(
      color: Colors.white, // خلفية بيضاء
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الدروس المتاحة',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isLessonsLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (isLessonsLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (availableLessons.isEmpty)
            Container(
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
                    'لا توجد دروس متاحة حالياً',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Consumer<LessonProvider>(
                    builder: (context, lessonProvider, child) {
                      if (lessonProvider.lessons.isEmpty) {
                        return Column(
                          children: [
                            Text(
                              'جاري تحميل الدروس المحلية...',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _initializeDataInstantly,
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة تحميل'),
                            ),
                          ],
                        );
                      } else {
                        return Text(
                          'أكمل الدروس الحالية لفتح دروس جديدة\n(المستوى الحالي: ${user?.currentLevel ?? 1})',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        );
                      }
                    },
                  ),
                ],
              ),
            )
          else
            Container(
              color: Colors.white, // خلفية بيضاء
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: availableLessons.length,
                itemBuilder: (context, index) {
                  final lesson = availableLessons[index];
                  final isCompleted = user?.completedLessons.contains(lesson.id) ?? false;
                  
                  return LessonCard(
                    lesson: lesson,
                    isCompleted: isCompleted,
                    onTap: () => context.push('/lesson/${lesson.id}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLevelTestSection(user, availableLessons) {
    // Check if current level is completed
    final currentLevelLessons = availableLessons.where((l) => l.level == user.currentLevel).toList();
    final isLevelCompleted = currentLevelLessons.isNotEmpty && 
                            currentLevelLessons.every((l) => user.completedLessons.contains(l.id));
    
    if (!isLevelCompleted) return const SizedBox.shrink();
    
    return Container(
      color: Colors.white, // خلفية بيضاء
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختبار المستوى',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          LevelTestButton(
            level: user.currentLevel,
            onPressed: () {
              // Navigate to level test
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('اختبار المستوى قريباً...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'يمكنك تصفح الدروس المحلية. أنشئ حساباً لحفظ تقدمك!',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.go('/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('إنشاء حساب'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
