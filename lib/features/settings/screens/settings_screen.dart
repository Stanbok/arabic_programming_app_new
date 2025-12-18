import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final isAnonymous = ref.watch(isAnonymousProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          AppStrings.settings,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // App Settings Section
          SettingsSection(
            title: 'إعدادات التطبيق',
            children: [
              SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'الإشعارات',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                  activeColor: AppColors.primary,
                ),
              ),
              SettingsTile(
                icon: Icons.volume_up_outlined,
                title: 'الأصوات',
                trailing: Switch(
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() => _soundEnabled = value);
                  },
                  activeColor: AppColors.primary,
                ),
              ),
              SettingsTile(
                icon: Icons.vibration,
                title: 'الاهتزاز',
                trailing: Switch(
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() => _vibrationEnabled = value);
                  },
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Account Section
          SettingsSection(
            title: 'الحساب',
            children: [
              if (isAnonymous)
                SettingsTile(
                  icon: Icons.link,
                  title: AppStrings.linkAccount,
                  subtitle: 'احفظ تقدمك للأبد',
                  onTap: () => _linkAccount(),
                ),
              userAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (user) {
                  if (user == null) return const SizedBox.shrink();
                  return SettingsTile(
                    icon: Icons.person_outline,
                    title: 'تعديل الملف الشخصي',
                    subtitle: user.displayName ?? 'ضيف',
                    onTap: () => _showEditProfileDialog(),
                  );
                },
              ),
              if (!ref.watch(isPremiumProvider))
                SettingsTile(
                  icon: Icons.workspace_premium_outlined,
                  title: AppStrings.getPremium,
                  subtitle: 'احصل على جميع المزايا',
                  iconColor: AppColors.accent,
                  onTap: () => context.push(RouteNames.premium),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          SettingsSection(
            title: 'حول التطبيق',
            children: [
              SettingsTile(
                icon: Icons.star_outline,
                title: 'قيّم التطبيق',
                onTap: () {
                  // TODO: Open app store rating
                },
              ),
              SettingsTile(
                icon: Icons.share_outlined,
                title: 'شارك التطبيق',
                onTap: () {
                  // TODO: Share app
                },
              ),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'سياسة الخصوصية',
                onTap: () {
                  // TODO: Open privacy policy
                },
              ),
              SettingsTile(
                icon: Icons.description_outlined,
                title: 'شروط الاستخدام',
                onTap: () {
                  // TODO: Open terms of service
                },
              ),
              const SettingsTile(
                icon: Icons.info_outline,
                title: 'الإصدار',
                trailing: Text(
                  '1.0.0',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Danger Zone
          if (!isAnonymous)
            SettingsSection(
              title: 'منطقة الخطر',
              titleColor: AppColors.error,
              children: [
                SettingsTile(
                  icon: Icons.logout,
                  title: 'تسجيل الخروج',
                  iconColor: AppColors.error,
                  textColor: AppColors.error,
                  onTap: () => _showLogoutDialog(),
                ),
              ],
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _linkAccount() async {
    try {
      await ref.read(userProvider.notifier).linkWithGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم ربط الحساب بنجاح!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل ربط الحساب: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final user = ref.read(userProvider).valueOrNull;
    if (user == null) return;

    final nameController = TextEditingController(text: user.displayName);
    int selectedAvatar = user.selectedAvatarIndex;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'تعديل الملف الشخصي',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'اسمك',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'اختر صورتك',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      const avatars = ['🦁', '🐼', '🦊', '🐸', '🐵', '🐰', '🐻', '🦄', '🐲', '🦋', '🐬', '🦉'];
                      final isSelected = selectedAvatar == index;

                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => selectedAvatar = index);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              avatars[index],
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(userProvider.notifier).updateProfile(
                    displayName: nameController.text.trim(),
                    selectedAvatarIndex: selectedAvatar,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'تسجيل الخروج',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(userProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.pop(context);
                context.go(RouteNames.splash);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
