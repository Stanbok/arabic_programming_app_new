import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _resetAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين الحساب'),
        content: const Text(
          'هذا الإجراء سيحذف جميع بياناتك (التقدم، النتائج، النقاط، الجواهر) '
          'ولكن سيحتفظ بالبيانات الأساسية (الاسم، البريد الإلكتروني).\n\n'
          'هل أنت متأكد من أنك تريد المتابعة؟'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.resetProgress();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إعادة تعيين الحساب بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back to home
          context.go('/home');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في إعادة تعيين الحساب: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Stop listening to user data
      userProvider.stopListening();
      
      // Sign out
      await authProvider.signOut();
      
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Section
            _buildSectionTitle(context, 'المظهر'),
            _buildThemeSettings(context),
            
            const SizedBox(height: 32),
            
            // Account Section
            _buildSectionTitle(context, 'الحساب'),
            _buildAccountSettings(context),
            
            const SizedBox(height: 32),
            
            // About Section
            _buildSectionTitle(context, 'حول التطبيق'),
            _buildAboutSettings(context),
            
            const SizedBox(height: 32),
            
            // Danger Zone
            _buildSectionTitle(context, 'منطقة الخطر', color: Colors.red),
            _buildDangerZone(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildThemeSettings(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                context: context,
                icon: Icons.light_mode,
                title: 'الوضع الفاتح',
                subtitle: 'استخدام المظهر الفاتح',
                trailing: Radio<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
              ),
              
              const Divider(height: 1),
              
              _buildSettingsTile(
                context: context,
                icon: Icons.dark_mode,
                title: 'الوضع المظلم',
                subtitle: 'استخدام المظهر المظلم',
                trailing: Radio<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
              ),
              
              const Divider(height: 1),
              
              _buildSettingsTile(
                context: context,
                icon: Icons.auto_mode,
                title: 'تلقائي',
                subtitle: 'يتبع إعدادات النظام',
                trailing: Radio<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.user;
              return _buildSettingsTile(
                context: context,
                icon: Icons.person,
                title: 'معلومات الحساب',
                subtitle: user?.email ?? 'جاري التحميل...',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to account info screen (if implemented)
                },
              );
            },
          ),
          
          const Divider(height: 1),
          
          _buildSettingsTile(
            context: context,
            icon: Icons.notifications,
            title: 'الإشعارات',
            subtitle: 'إدارة إشعارات التطبيق',
            trailing: Switch(
              value: true, // This would come from user settings
              onChanged: (value) {
                // Save notification preference
              },
            ),
          ),
          
          const Divider(height: 1),
          
          _buildSettingsTile(
            context: context,
            icon: Icons.language,
            title: 'اللغة',
            subtitle: 'العربية',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Language selection (if multiple languages supported)
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context: context,
            icon: Icons.info,
            title: 'حول التطبيق',
            subtitle: 'الإصدار 1.0.0',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Python in English',
                applicationVersion: '1.0.0',
                applicationIcon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.code,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                children: [
                  const Text(
                    'تطبيق تفاعلي لتعلم البايثون بالعربية بطريقة ممتعة ومبسطة. '
                    'يحتوي على دروس تفاعلية واختبارات ونظام نقاط وجواهر لتحفيز التعلم.',
                  ),
                ],
              );
            },
          ),
          
          const Divider(height: 1),
          
          _buildSettingsTile(
            context: context,
            icon: Icons.privacy_tip,
            title: 'سياسة الخصوصية',
            subtitle: 'اطلع على سياسة الخصوصية',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to privacy policy
            },
          ),
          
          const Divider(height: 1),
          
          _buildSettingsTile(
            context: context,
            icon: Icons.description,
            title: 'شروط الاستخدام',
            subtitle: 'اطلع على شروط الاستخدام',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to terms of service
            },
          ),
          
          const Divider(height: 1),
          
          _buildSettingsTile(
            context: context,
            icon: Icons.support,
            title: 'الدعم الفني',
            subtitle: 'تواصل معنا للحصول على المساعدة',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to support or open email
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context: context,
            icon: Icons.refresh,
            title: 'إعادة تعيين الحساب',
            subtitle: 'حذف جميع البيانات والتقدم',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _resetAccount(context),
            titleColor: Colors.red,
          ),
          
          const Divider(height: 1),
          
          _buildSettingsTile(
            context: context,
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            subtitle: 'الخروج من الحساب الحالي',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _signOut(context),
            titleColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (titleColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: titleColor ?? Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
