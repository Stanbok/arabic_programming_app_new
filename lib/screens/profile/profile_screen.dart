import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../services/statistics_service.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  int _currentIndex = 1;
  Map<String, dynamic> _userStats = {};
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadUserStatistics();
  }

  /// إصلاح المشكلة الثانية - تحديث الإحصائيات (تحسين آلية التحديث)
  Future<void> _loadUserStatistics() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingStats = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? 'guest';
      
      print('📊 تحميل إحصائيات المستخدم: $userId');
      
      // تحديث الإحصائيات من Firebase أولاً
      await StatisticsService.refreshStatisticsFromFirebase(userId);
      
      // ثم جلب الإحصائيات المحدثة
      final stats = await StatisticsService.getUserStatistics(userId);
      
      if (mounted) {
        setState(() {
          _userStats = stats;
          _isLoadingStats = false;
        });
        
        print('✅ تم تحميل الإحصائيات: $stats');
      }
    } catch (e) {
      print('❌ خطأ في تحميل الإحصائيات: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  /// تحديث الإحصائيات عند العودة للشاشة - تحسين التوقيت
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحديث الإحصائيات فقط إذا لم تكن قيد التحميل
    if (!_isLoadingStats) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadUserStatistics();
        }
      });
    }
  }

  Future<void> _changeProfileImage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    
    if (user == null) return;
    
    // Show confirmation dialog with actual gem count
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير صورة الملف الشخصي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('سيتم خصم 100 جوهرة من رصيدك.'),
            const SizedBox(height: 8),
            Text('الجواهر الحالية: ${user.gems}'),
            if (userProvider.hasPendingRewards)
              Text('الجواهر مع المعلقة: ${userProvider.totalGems}'),
            const SizedBox(height: 8),
            const Text('هل تريد المتابعة؟'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('موافق'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final imageUrl = await userProvider.uploadProfileImage(image.path);
        
        if (imageUrl != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تغيير صورة الملف الشخصي بنجاح وخصم 100 جوهرة'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تغيير الصورة: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// إعادة تعيين الحساب مع إعادة تعيين LessonProvider أيضاً
  Future<void> _resetAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين الحساب'),
        content: const Text('سيتم حذف جميع التقدم والإحصائيات. هذا الإجراء لا يمكن التراجع عنه. هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
      
      // إعادة تعيين UserProvider
      await userProvider.resetProgress();
      
      // إعادة تعيين LessonProvider
      await lessonProvider.resetLocalProgress();
      
      // إعادة تحميل الإحصائيات
      await _loadUserStatistics();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعادة تعيين الحساب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إعادة تعيين الحساب: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: _isLoadingStats 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoadingStats ? null : _loadUserStatistics,
            tooltip: 'تحديث الإحصائيات',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadUserStatistics,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(user, userProvider),
                  
                  const SizedBox(height: 24),
                  
                  // Pending Rewards Indicator
                  if (userProvider.hasPendingRewards)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sync, color: Colors.blue),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'يتم مزامنة المكافآت مع الخادم...',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ),
                    ),
                  
                  // Stats Cards
                  _buildStatsSection(user, _userStats),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  _buildActionButtons(),
                  
                  const SizedBox(height: 24),
                  
                  // Achievements Section
                  _buildAchievementsSection(user),
                ],
              ),
            ),
          );
        },
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
          if (index == 0) {
            context.go('/home');
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
  }

  Widget _buildProfileHeader(user, UserProvider userProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Profile Image
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: user.profileImageUrl != null
                    ? CachedNetworkImageProvider(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    onPressed: _changeProfileImage,
                    tooltip: 'تغيير الصورة (100 جوهرة)',
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // User Name
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Level Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'المستوى ${userProvider.currentLevel}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // XP and Gems
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.star,
                label: 'نقاط الخبرة',
                value: '${userProvider.totalXP}',
                color: Colors.white,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                icon: Icons.diamond,
                label: 'الجواهر',
                value: '${userProvider.totalGems}',
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(user, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الإحصائيات',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isLoadingStats)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildStatsCard(
              icon: Icons.school,
              title: 'الدروس المكتملة',
              value: '${stats['totalLessonsCompleted'] ?? 0}',
              color: Colors.blue,
            ),
            _buildStatsCard(
              icon: Icons.quiz,
              title: 'إجمالي المحاولات',
              value: '${stats['totalAttempts'] ?? 0}',
              color: Colors.green,
            ),
            _buildStatsCard(
              icon: Icons.trending_up,
              title: 'متوسط النتائج',
              value: '${(stats['averageScore'] ?? 0.0).toStringAsFixed(1)}%',
              color: Colors.orange,
            ),
            _buildStatsCard(
              icon: Icons.speed,
              title: 'متوسط وقت الحساب',
              value: '${(stats['averageScoringTime'] ?? 0.0).round()}ms',
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإجراءات',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'الإعدادات',
            onPressed: () => context.push('/settings'),
            icon: Icons.settings,
            isOutlined: true,
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'إعادة تعيين الحساب',
            onPressed: _resetAccount,
            icon: Icons.refresh,
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(user) {
    final achievements = _getAchievements(user);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإنجازات',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (achievements.isEmpty)
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
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد إنجازات بعد',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'استمر في التعلم لفتح إنجازات جديدة!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...achievements.map((achievement) => _buildAchievementCard(achievement)),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: achievement['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              achievement['icon'],
              color: achievement['color'],
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['title'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement['description'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 24,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAchievements(user) {
    List<Map<String, dynamic>> achievements = [];

    // First lesson achievement
    if (user.completedLessons.isNotEmpty) {
      achievements.add({
        'title': 'أول خطوة',
        'description': 'أكملت أول درس لك',
        'icon': Icons.play_arrow,
        'color': Colors.green,
      });
    }

    // Level achievements
    if (user.currentLevel >= 2) {
      achievements.add({
        'title': 'متعلم مبتدئ',
        'description': 'وصلت للمستوى الثاني',
        'icon': Icons.trending_up,
        'color': Colors.blue,
      });
    }

    if (user.currentLevel >= 5) {
      achievements.add({
        'title': 'متعلم متقدم',
        'description': 'وصلت للمستوى الخامس',
        'icon': Icons.school,
        'color': Colors.purple,
      });
    }

    // XP achievements
    if (user.xp >= 1000) {
      achievements.add({
        'title': 'جامع النقاط',
        'description': 'حصلت على 1000 نقطة خبرة',
        'icon': Icons.star,
        'color': Colors.amber,
      });
    }

    // Gems achievements
    if (user.gems >= 100) {
      achievements.add({
        'title': 'جامع الجواهر',
        'description': 'جمعت 100 جوهرة',
        'icon': Icons.diamond,
        'color': Colors.cyan,
      });
    }

    return achievements;
  }
}
