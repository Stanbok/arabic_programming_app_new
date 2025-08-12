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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
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

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);

    if (authProvider.user == null) {
      // إذا لم يكن المستخدم مسجل دخول، انتقل لصفحة تسجيل الدخول
      if (mounted) {
        context.go('/login');
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      print('🚀 بدء تهيئة البيانات...');
      print('👤 المستخدم: ${authProvider.user!.uid}');

      // بدء الاستماع لبيانات المستخدم
      userProvider.startListening(authProvider.user!.uid);
      
      // تحميل بيانات المستخدم إذا لم تكن محملة
      if (userProvider.user == null) {
        print('📥 تحميل بيانات المستخدم...');
        await userProvider.loadUserData(authProvider.user!.uid);
      }

      // تحميل الدروس
      print('📚 تحميل الدروس...');
      await lessonProvider.loadLessons();

      if (lessonProvider.lessons.isEmpty) {
        print('⚠️ لم يتم تحميل أي دروس!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تحذير: لم يتم العثور على دروس في قاعدة البيانات'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      
      print('✅ تم تهيئة البيانات بنجاح');
    } catch (e) {
      print('❌ خطأ في تحميل البيانات: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              onPressed: _initializeData,
            ),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);

    if (authProvider.user == null) return;

    try {
      // إعادة تحميل بيانات المستخدم
      await userProvider.loadUserData(authProvider.user!.uid);
      
      // إعادة تحميل الدروس
      await lessonProvider.loadLessons();
    } catch (e) {
      print('خطأ في تحديث البيانات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
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
                  Text('جاري تحميل البيانات...'),
                ],
              ),
            )
          : Consumer3<UserProvider, LessonProvider, AuthProvider>(
              builder: (context, userProvider, lessonProvider, authProvider, child) {
                final user = userProvider.user;
                
                // إذا لم تكن بيانات المستخدم محملة بعد
                if (user == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحميل بيانات المستخدم...'),
                      ],
                    ),
                  );
                }

                final availableLessons = lessonProvider.getAvailableLessons(
                  user.completedLessons,
                  user.currentLevel,
                );

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Section - Profile & XP
                        _buildTopSection(user),
                        
                        const SizedBox(height: 24),
                        
                        // Welcome Message
                        _buildWelcomeMessage(user),
                        
                        const SizedBox(height: 24),
                        
                        // Lessons Grid
                        _buildLessonsSection(availableLessons, user, lessonProvider.isLoading),
                        
                        const SizedBox(height: 24),
                        
                        // Level Test Button
                        _buildLevelTestSection(user, availableLessons),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTopSection(user) {
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
              
              // Gems
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
                      '${user.gems}',
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
          
          // XP Bar
          XPBar(
            currentXP: user.currentLevelProgress,
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
        color: Theme.of(context).colorScheme.surface,
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
                  '$greeting، ${user.name}!',
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
            'أنت في المستوى ${user.level}. لديك ${user.completedLessons.length} درس مكتمل. استمر في التعلم لتصل إلى المستوى التالي!',
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
    return Column(
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
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (availableLessons.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
                            'لم يتم العثور على دروس في قاعدة البيانات',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _initializeData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة تحميل'),
                          ),
                        ],
                      );
                    } else {
                      return Text(
                        'أكمل الدروس الحالية لفتح دروس جديدة\n(المستوى الحالي: ${user.currentLevel})',
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
          GridView.builder(
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
              final isCompleted = user.completedLessons.contains(lesson.id);
              
              return LessonCard(
                lesson: lesson,
                isCompleted: isCompleted,
                onTap: () => context.push('/lesson/${lesson.id}'),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLevelTestSection(user, availableLessons) {
    // Check if current level is completed
    final currentLevelLessons = availableLessons.where((l) => l.level == user.currentLevel).toList();
    final isLevelCompleted = currentLevelLessons.isNotEmpty && 
                            currentLevelLessons.every((l) => user.completedLessons.contains(l.id));
    
    if (!isLevelCompleted) return const SizedBox.shrink();
    
    return Column(
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
    );
  }
}
