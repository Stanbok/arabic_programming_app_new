import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/statistics_service.dart';
import '../../widgets/xp_bar.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userStats;
  bool _isLoadingStats = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserStatistics();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحديث الإحصائيات عند تغيير التبعيات
    if (!_isLoadingStats) {
      _loadUserStatistics();
    }
  }

  Future<void> _loadUserStatistics() async {
    if (_isLoadingStats) return; // منع الاستدعاءات المتكررة
    
    setState(() {
      _isLoadingStats = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? 'guest';
      
      // تحديث الإحصائيات من Firebase أولاً
      await StatisticsService.refreshStatisticsFromFirebase(userId);
      
      // ثم جلب الإحصائيات المحدثة
      final stats = await StatisticsService.getUserStatistics(userId);
      
      if (mounted) {
        setState(() {
          _userStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('خطأ في تحميل الإحصائيات: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (userProvider.totalGems < 100) {
      _showInsufficientGemsDialog();
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _isUploadingImage = true;
        });

        final imageUrl = await userProvider.uploadProfileImage(image.path);
        
        if (imageUrl != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث صورة الملف الشخصي بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _showInsufficientGemsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('جواهر غير كافية'),
        content: const Text('تحتاج إلى 100 جوهرة لتغيير صورة الملف الشخصي.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, UserProvider>(
        builder: (context, authProvider, userProvider, child) {
          final user = userProvider.user;
          
          if (user == null && !authProvider.isGuestUser) {
            return const Center(
              child: Text('لا توجد بيانات مستخدم'),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadUserStatistics,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(authProvider, userProvider),
                  
                  const SizedBox(height: 24),
                  
                  // XP Progress
                  _buildXPSection(userProvider),
                  
                  const SizedBox(height: 24),
                  
                  // Statistics Section
                  _buildStatisticsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Pending Rewards Section
                  if (userProvider.hasPendingRewards)
                    _buildPendingRewardsSection(userProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider, UserProvider userProvider) {
    final user = userProvider.user;
    final isGuest = authProvider.isGuestUser;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Image
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user?.profileImageUrl != null
                      ? NetworkImage(user!.profileImageUrl!)
                      : null,
                  child: user?.profileImageUrl == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                if (!isGuest)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingImage ? null : _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: _isUploadingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // User Info
            Text(
              isGuest ? 'ضيف' : (user?.name ?? 'مستخدم'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            if (!isGuest && user?.email != null)
              Text(
                user!.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Gems and Level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  icon: Icons.diamond,
                  label: 'الجواهر',
                  value: '${userProvider.totalGems}',
                  color: Colors.purple,
                ),
                _buildStatCard(
                  icon: Icons.star,
                  label: 'المستوى',
                  value: '${userProvider.currentLevel}',
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXPSection(UserProvider userProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نقاط الخبرة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            XPBar(
              currentXP: userProvider.totalXP,
              currentLevel: userProvider.currentLevel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإحصائيات',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLoadingStats)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadUserStatistics,
                    tooltip: 'تحديث الإحصائيات',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_userStats != null) ...[
              _buildStatRow('إجمالي المحاولات', '${_userStats!['totalAttempts']}'),
              _buildStatRow('الدروس المكتملة', '${_userStats!['totalLessonsCompleted']}'),
              _buildStatRow('متوسط النتائج', '${_userStats!['averageScore'].toStringAsFixed(1)}%'),
              _buildStatRow('إجمالي XP المكتسب', '${_userStats!['totalXPEarned']}'),
              _buildStatRow('إجمالي الجواهر المكتسبة', '${_userStats!['totalGemsEarned']}'),
              _buildStatRow('معدل الإكمال', '${_userStats!['completionRate'].toStringAsFixed(1)}%'),
            ] else if (!_isLoadingStats) ...[
              const Text('لا توجد إحصائيات متاحة'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRewardsSection(UserProvider userProvider) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pending, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'مكافآت معلقة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'لديك ${userProvider.pendingRewards.length} مكافأة في انتظار المزامنة',
              style: TextStyle(color: Colors.orange[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'المجموع: +${userProvider.pendingRewards.fold(0, (sum, r) => sum + r.xp)} XP, +${userProvider.pendingRewards.fold(0, (sum, r) => sum + r.gems)} جوهرة',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
