import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/premium_badge.dart';
import '../../onboarding/screens/auth_screen.dart';
import '../../premium/screens/premium_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  int _lessonsCompleted = 0;
  int _totalLearningTime = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final userId = authService.currentUser?.uid;

    if (userId == null) return;

    final user = await firestoreService.getUser(userId);
    final progress = await firestoreService.getUserProgress(userId);
    
    setState(() {
      _user = user;
      _lessonsCompleted = progress.values.where((p) => p.completed).length;
      _totalLearningTime = _lessonsCompleted * 5; // Estimate 5 mins per lesson
      _isLoading = false;
    });
  }

  String _getAvatarEmoji(int id) {
    final emojis = [
      '👨‍💻', '👩‍💻', '🧑‍💻', '👨‍🎓', '👩‍🎓', '🧑‍🎓',
      '🦊', '🐱', '🐶', '🦁', '🐼', '🐨',
    ];
    return emojis[(id - 1) % emojis.length];
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = context.read<AuthService>();
      await authService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return const Scaffold(body: LoadingWidget());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar with Premium Badge
                  Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: _user!.isPremium
                              ? Border.all(color: AppColors.premium, width: 3)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            _getAvatarEmoji(_user!.avatarId),
                            style: const TextStyle(fontSize: 44),
                          ),
                        ),
                      ),
                      if (_user!.isPremium)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const PremiumBadge(size: 18, showLabel: false),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Name with VIP Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _user!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_user!.isPremium) ...[
                        const SizedBox(width: 8),
                        const PremiumBadge(size: 14),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Member Since
                  Text(
                    'عضو منذ ${_formatDate(_user!.createdAt)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Premium Upgrade Card (if not premium)
            if (!_user!.isPremium)
              _buildPremiumCard(),
            
            if (!_user!.isPremium)
              const SizedBox(height: 24),
            
            // Stats Grid (2x2)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  icon: Icons.school_outlined,
                  value: _lessonsCompleted.toString(),
                  label: 'دروس مكتملة',
                  color: AppColors.primary,
                ),
                _StatCard(
                  icon: Icons.timer_outlined,
                  value: '${_totalLearningTime}د',
                  label: 'وقت التعلم',
                  color: AppColors.accentGreen,
                ),
                _StatCard(
                  icon: Icons.route_outlined,
                  value: '1',
                  label: 'مسارات',
                  color: AppColors.accent,
                ),
                _StatCard(
                  icon: Icons.download_done_outlined,
                  value: '${_user!.completedLessons}',
                  label: 'دروس محملة',
                  color: AppColors.accentPurple,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Settings
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline,
                    title: 'تعديل الاسم',
                    onTap: _showEditNameDialog,
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.face,
                    title: 'تغيير الصورة الرمزية',
                    onTap: _showAvatarPicker,
                  ),
                  if (_user!.isPremium) ...[
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.workspace_premium,
                      title: 'إدارة الاشتراك',
                      subtitle: 'Premium نشط',
                      onTap: () {},
                      trailing: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                  ],
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.logout,
                    title: 'تسجيل الخروج',
                    onTap: _logout,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.premium, Color(0xFFE8C547)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.premium.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                'Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'احصل على تجربة تعلم بدون حدود',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _PremiumFeature(icon: Icons.download, label: 'تحميل غير محدود'),
              const SizedBox(width: 16),
              _PremiumFeature(icon: Icons.block, label: 'بدون إعلانات'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                ).then((_) => _loadData());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.premium,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('اشترك الآن'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _user!.name);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل الاسم'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'أدخل اسمك الجديد'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final firestoreService = context.read<FirestoreService>();
                await firestoreService.updateUser(_user!.id, {
                  'name': controller.text.trim(),
                });
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر صورتك الرمزية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final avatarId = index + 1;
                final isSelected = _user!.avatarId == avatarId;
                return GestureDetector(
                  onTap: () async {
                    final firestoreService = context.read<FirestoreService>();
                    await firestoreService.updateUser(_user!.id, {
                      'avatarId': avatarId,
                    });
                    Navigator.pop(context);
                    _loadData();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(_getAvatarEmoji(avatarId), style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

class _PremiumFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PremiumFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_left, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
