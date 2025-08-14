import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'dart:io';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/reward_service.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  final ImagePicker _imagePicker = ImagePicker();
  int _currentIndex = 1;
  bool _isSharing = false;
  DateTime? _shareStartTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // التحقق من العودة للتطبيق بعد المشاركة
    if (state == AppLifecycleState.resumed && _isSharing && _shareStartTime != null) {
      final timeDifference = DateTime.now().difference(_shareStartTime!).inSeconds;
      
      // إذا كان المستخدم خارج التطبيق لأكثر من 3 ثوانٍ، نعتبر أنه شارك
      if (timeDifference > 3) {
        _handleShareReturn(true);
      } else {
        _handleShareReturn(false);
      }
    }
  }

  Future<void> _changeProfileImage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    
    if (user == null) return;
    
    // Check if user has enough gems
    if (userProvider.totalGems < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تحتاج إلى 100 جوهرة لتغيير صورة الملف الشخصي'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير صورة الملف الشخصي'),
        content: const Text('سيتم خصم 100 جوهرة من رصيدك. هل تريد المتابعة؟'),
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
              content: Text('تم تغيير صورة الملف الشخصي بنجاح'),
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

  Future<void> _shareApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (authProvider.isGuestUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول للحصول على مكافأة المشاركة'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    try {
      // التحقق من إمكانية الحصول على المكافأة
      final userId = authProvider.user?.uid ?? 'guest';
      final canClaim = await RewardService.canClaimShareReward(userId);
      
      if (!canClaim && !authProvider.isGuestUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحصول على مكافأة المشاركة مسبقاً (مرة واحدة كل 24 ساعة)'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // بدء عملية المشاركة
      setState(() {
        _isSharing = true;
        _shareStartTime = DateTime.now();
      });

      // تنفيذ المشاركة
      await Share.share(
        'تعلم البايثون بالعربية مع تطبيق Python in Arabic! 🐍\n'
        'تطبيق تفاعلي ممتع لتعلم البرمجة بطريقة سهلة ومبسطة.\n'
        'حمل التطبيق الآن واستمتع بالتعلم!',
        subject: 'Python in Arabic - تعلم البايثون بالعربية',
      );

      // إعطاء وقت للمشاركة
      Timer(const Duration(seconds: 1), () {
        if (_isSharing) {
          // إذا لم يتم استدعاء didChangeAppLifecycleState، نعتبر أنه لم يشارك
          _handleShareReturn(false);
        }
      });

    } catch (e) {
      setState(() {
        _isSharing = false;
        _shareStartTime = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ في المشاركة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleShareReturn(bool actuallyShared) async {
    if (!_isSharing) return;
    
    setState(() {
      _isSharing = false;
      _shareStartTime = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? 'guest';

    if (actuallyShared && !authProvider.isGuestUser) {
      try {
        // منح المكافأة
        final rewardInfo = await RewardService.claimShareReward(userId, true);
        
        if (rewardInfo != null) {
          final success = await userProvider.addReward(rewardInfo, userId);
          
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('شكراً لمشاركة التطبيق! حصلت على ${rewardInfo.gems} جوهرة 💎'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ في منح المكافأة'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (!actuallyShared && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم إكمال المشاركة'),
          backgroundColor: Colors.orange,
        ),
      );
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

          final stats = userProvider.userStats;

          return SingleChildScrollView(
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
                _buildStatsSection(user, stats),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                _buildActionButtons(),
                
                const SizedBox(height: 24),
                
                // Achievements Section
                _buildAchievementsSection(user),
              ],
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
        Text(
          'الإحصائيات',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
              value: '${user.completedLessons.length}',
              color: Colors.blue,
            ),
            _buildStatsCard(
              icon: Icons.quiz,
              title: 'الاختبارات',
              value: '${stats['totalQuizzes']}',
              color: Colors.green,
            ),
            _buildStatsCard(
              icon: Icons.trending_up,
              title: 'متوسط النتائج',
              value: '${stats['averageScore'].toStringAsFixed(1)}%',
              color: Colors.orange,
            ),
            _buildStatsCard(
              icon: Icons.timeline,
              title: 'معدل الإكمال',
              value: '${stats['completionRate'].toStringAsFixed(1)}%',
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
        
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: _isSharing ? 'جاري المشاركة...' : 'مشاركة التطبيق',
                onPressed: _isSharing ? null : _shareApp,
                icon: _isSharing ? Icons.hourglass_empty : Icons.share,
                isOutlined: true,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: CustomButton(
                text: 'الإعدادات',
                onPressed: () => context.push('/settings'),
                icon: Icons.settings,
                isOutlined: true,
              ),
            ),
          ],
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
    if (user.level >= 2) {
      achievements.add({
        'title': 'متعلم مبتدئ',
        'description': 'وصلت للمستوى الثاني',
        'icon': Icons.trending_up,
        'color': Colors.blue,
      });
    }

    if (user.level >= 5) {
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
