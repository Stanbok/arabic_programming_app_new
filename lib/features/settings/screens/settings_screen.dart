import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../onboarding/widgets/avatar_widget.dart';
import '../../profile/widgets/edit_name_dialog.dart';
import '../../profile/widgets/edit_avatar_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        children: [
          // App Settings Section
          _SectionHeader(title: 'إعدادات التطبيق'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('المظهر'),
            subtitle: Text(_getThemeName(settings.themeModeIndex)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, ref, settings.themeModeIndex),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('حجم الخط'),
            subtitle: Text(_getFontSizeName(settings.fontSize)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFontSizeDialog(context, ref, settings.fontSize),
          ),
          
          // Notifications Section
          _SectionHeader(title: 'الإشعارات'),
          SwitchListTile(
            secondary: const Icon(Icons.alarm),
            title: const Text('تذكير يومي'),
            subtitle: const Text('تذكير للتعلم كل يوم'),
            value: settings.dailyReminderEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateDailyReminder(value);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.emoji_events),
            title: const Text('إشعارات الإنجازات'),
            value: settings.achievementNotificationsEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateAchievementNotifications(value);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.update),
            title: const Text('إشعارات التحديثات'),
            value: settings.updateNotificationsEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateUpdateNotifications(value);
            },
          ),
          
          // Account Section
          _SectionHeader(title: 'الحساب'),
          ListTile(
            leading: AvatarWidget(avatarId: profile.avatarId, size: 40),
            title: Text(profile.name ?? 'متعلم'),
            subtitle: Text(
              profile.isLinked
                  ? profile.email ?? 'حساب مربوط'
                  : 'حساب محلي',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAccountOptions(context, ref, profile),
          ),
          const Divider(height: 1),
          if (profile.isLinked)
            ListTile(
              leading: const Icon(Icons.sync_rounded),
              title: const Text('مزامنة الآن'),
              onTap: () => _syncNow(context),
            ),
          if (profile.isLinked) const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.delete_forever_rounded,
              color: AppColors.error,
            ),
            title: Text(
              'حذف الحساب',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),
          
          // About Section
          _SectionHeader(title: 'حول التطبيق'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('الإصدار'),
            subtitle: Text(AppConstants.appVersion),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('سياسة الخصوصية'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openPrivacyPolicy(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('الشروط والأحكام'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openTerms(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('تواصل معنا'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _contactUs(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.star_outline, color: AppColors.vipGold),
            title: const Text('قيّم التطبيق'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _rateApp(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getThemeName(int index) {
    switch (index) {
      case 1:
        return 'فاتح';
      case 2:
        return 'داكن';
      default:
        return 'تلقائي';
    }
  }

  String _getFontSizeName(double size) {
    if (size <= 0.9) return 'صغير';
    if (size >= 1.2) return 'كبير';
    return 'متوسط';
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, int current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر المظهر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              title: 'تلقائي',
              icon: Icons.brightness_auto,
              isSelected: current == 0,
              onTap: () {
                ref.read(settingsProvider.notifier).updateThemeMode(0);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              title: 'فاتح',
              icon: Icons.light_mode,
              isSelected: current == 1,
              onTap: () {
                ref.read(settingsProvider.notifier).updateThemeMode(1);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              title: 'داكن',
              icon: Icons.dark_mode,
              isSelected: current == 2,
              onTap: () {
                ref.read(settingsProvider.notifier).updateThemeMode(2);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, WidgetRef ref, double current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر حجم الخط'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FontSizeOption(
              title: 'صغير',
              size: 0.85,
              isSelected: current <= 0.9,
              onTap: () {
                ref.read(settingsProvider.notifier).updateFontSize(0.85);
                Navigator.pop(context);
              },
            ),
            _FontSizeOption(
              title: 'متوسط',
              size: 1.0,
              isSelected: current > 0.9 && current < 1.2,
              onTap: () {
                ref.read(settingsProvider.notifier).updateFontSize(1.0);
                Navigator.pop(context);
              },
            ),
            _FontSizeOption(
              title: 'كبير',
              size: 1.25,
              isSelected: current >= 1.2,
              onTap: () {
                ref.read(settingsProvider.notifier).updateFontSize(1.25);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountOptions(BuildContext context, WidgetRef ref, dynamic profile) {
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
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('تعديل الاسم'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => EditNameDialog(
                    currentName: profile.name ?? '',
                    onSave: (name) {
                      ref.read(profileProvider.notifier).updateName(name);
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.face_rounded),
              title: const Text('تغيير الصورة'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => EditAvatarDialog(
                    currentAvatarId: profile.avatarId,
                    onSave: (avatarId) {
                      ref.read(profileProvider.notifier).updateAvatar(avatarId);
                    },
                  ),
                );
              },
            ),
            if (!profile.isLinked)
              ListTile(
                leading: const Icon(Icons.link_rounded, color: AppColors.primary),
                title: const Text('ربط بحساب Google'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final result = await AuthRepository.instance.linkWithGoogle();
                    if (result.success && context.mounted) {
                      ref.read(profileProvider.notifier).setLinked(true);
                    }
                  } catch (e) {
                    // Handle error
                  }
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _syncNow(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جارٍ المزامنة...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text(
          'هل أنت متأكد من حذف حسابك؟ سيتم حذف جميع بياناتك وتقدمك ولا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthRepository.instance.deleteAccount();
                await ProgressRepository.instance.resetProgress();
                ref.read(profileProvider.notifier).clearProfile();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل الحذف: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'حذف',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم فتح سياسة الخصوصية'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openTerms(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم فتح الشروط والأحكام'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _contactUs(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('support@example.com'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _rateApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('شكراً لدعمك!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : null),
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: onTap,
    );
  }
}

class _FontSizeOption extends StatelessWidget {
  final String title;
  final double size;
  final bool isSelected;
  final VoidCallback onTap;

  const _FontSizeOption({
    required this.title,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: 16 * size)),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: onTap,
    );
  }
}
