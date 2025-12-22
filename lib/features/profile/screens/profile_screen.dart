import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../onboarding/widgets/avatar_widget.dart';
import '../../premium/screens/premium_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/edit_name_dialog.dart';
import '../widgets/edit_avatar_dialog.dart';
import '../widgets/stats_card.dart';
import '../widgets/link_account_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile header
            _buildProfileHeader(context, ref, profile),
            const SizedBox(height: 24),
            
            // Link account card (if not linked)
            if (!profile.isLinked)
              LinkAccountCard(
                onLink: () => _linkAccount(context, ref),
              ),
            
            if (!profile.isLinked) const SizedBox(height: 16),
            
            // Premium invitation (if not premium)
            if (!profile.isPremiumActive)
              _buildPremiumCard(context),
            
            if (!profile.isPremiumActive) const SizedBox(height: 16),
            
            // Statistics
            const StatsCard(),
            
            const SizedBox(height: 16),
            
            // Quick actions
            _buildQuickActions(context, ref, profile),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) {
    return Column(
      children: [
        // Avatar with edit button
        Stack(
          children: [
            AvatarWidget(
              avatarId: profile.avatarId,
              size: 100,
              showShadow: true,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: GestureDetector(
                onTap: () => _showEditAvatarDialog(context, ref),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Name with edit
        GestureDetector(
          onTap: () => _showEditNameDialog(context, ref, profile.name ?? ''),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profile.name ?? 'متعلم',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
            ],
          ),
        ),
        
        // Email if linked
        if (profile.isLinked && profile.email != null) ...[
          const SizedBox(height: 4),
          Text(
            profile.email!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
        
        // VIP badge
        if (profile.isPremiumActive) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.vipGold, AppColors.vipGoldLight],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.vipGold.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded, size: 18, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.premium),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.vipGold.withOpacity(0.15),
              AppColors.vipGoldLight.withOpacity(0.1),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.vipGold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.vipGold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اشترك في Premium',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تحميل غير محدود، بدون إعلانات',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.vipGold,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (profile.isLinked)
            _buildActionTile(
              context,
              icon: Icons.sync_rounded,
              title: 'مزامنة البيانات',
              subtitle: 'مزامنة يدوية مع السحابة',
              onTap: () => _syncData(context, ref),
            ),
          _buildActionTile(
            context,
            icon: Icons.share_rounded,
            title: 'مشاركة التطبيق',
            subtitle: 'شارك التطبيق مع أصدقائك',
            onTap: () => _shareApp(context),
          ),
          _buildActionTile(
            context,
            icon: Icons.help_outline_rounded,
            title: 'المساعدة والدعم',
            subtitle: 'تواصل معنا',
            onTap: () => _showHelp(context),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(title),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 56),
      ],
    );
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    showDialog(
      context: context,
      builder: (_) => EditNameDialog(
        currentName: currentName,
        onSave: (name) {
          ref.read(profileProvider.notifier).updateName(name);
        },
      ),
    );
  }

  void _showEditAvatarDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => EditAvatarDialog(
        currentAvatarId: ref.read(profileProvider).avatarId,
        onSave: (avatarId) {
          ref.read(profileProvider.notifier).updateAvatar(avatarId);
        },
      ),
    );
  }

  Future<void> _linkAccount(BuildContext context, WidgetRef ref) async {
    try {
      final result = await AuthRepository.instance.linkWithGoogle();
      if (result.success && context.mounted) {
        ref.read(profileProvider.notifier).setLinked(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم ربط الحساب بنجاح!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (!result.success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'فشل الربط'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الربط: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _syncData(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جارٍ المزامنة...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تنفيذ المشاركة قريباً'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(
              Icons.support_agent_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'كيف يمكننا مساعدتك؟',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.email_rounded, color: AppColors.primary),
              title: const Text('راسلنا عبر البريد'),
              subtitle: const Text('support@example.com'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_rounded, color: AppColors.warning),
              title: const Text('الإبلاغ عن مشكلة'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
