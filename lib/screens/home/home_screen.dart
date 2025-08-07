import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/user_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../widgets/xp_bar.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/level_test_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    await lessonProvider.loadLessons();
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
      body: Consumer2<UserProvider, LessonProvider>(
        builder: (context, userProvider, lessonProvider, child) {
          final user = userProvider.user;
          
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final availableLessons = lessonProvider.getAvailableLessons(
            user.completedLessons,
            user.currentLevel,
          );

          return RefreshIndicator(
            onRefresh: _loadData,
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
                  _buildLessonsSection(availableLessons, user),
                  
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
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Image
              CircleAvatar(
                radius: 30,
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
                    ),
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
    
    if (timeOfDay < 12) {
      greeting = 'صباح الخير';
    } else if (timeOfDay < 17) {
      greeting = 'مساء الخير';
    } else {
      greeting = 'مساء الخير';
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting، ${user.name}! 👋',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أنت في المستوى ${user.level}. استمر في التعلم لتصل إلى المستوى التالي!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsSection(List availableLessons, user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الدروس المتاحة',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (availableLessons.isEmpty)
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
                Text(
                  'أكمل الدروس الحالية لفتح دروس جديدة',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
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
    final isLevelCompleted = currentLevelLessons.every((l) => user.completedLessons.contains(l.id));
    
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
            // This would be implemented based on your level test logic
          },
        ),
      ],
    );
  }
}
