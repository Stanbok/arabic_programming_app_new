import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/sync_repository.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isLinking = false;

  Future<void> _linkAccount() async {
    setState(() => _isLinking = true);

    final result = await AuthRepository.instance.linkWithGoogle();

    if (!mounted) return;
    setState(() => _isLinking = false);

    if (result.success) {
      // Update profile
      ref.read(profileProvider.notifier).linkAccount(
            email: result.user?.email ?? '',
            firebaseUid: result.user?.uid ?? '',
          );

      // Trigger initial sync
      SyncRepository.instance.fullSync();

      AppSnackBar.show(
        context,
        message: 'تم ربط حسابك بنجاح!',
        type: SnackBarType.success,
      );

      _navigateToHome();
    } else {
      AppSnackBar.show(
        context,
        message: result.error ?? 'حدث خطأ أثناء ربط الحساب',
        type: SnackBarType.error,
      );
    }
  }

  void _skipToHome() {
    ref.read(profileProvider.notifier).completeOnboarding();
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final userName = profile.name ?? 'متعلم';

    return LoadingOverlay(
      isLoading: _isLinking,
      message: 'جارٍ ربط حسابك...',
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                // Welcome illustration
                _WelcomeIllustration(avatarId: profile.avatarId),
                const SizedBox(height: 40),

                // Welcome message
                Text(
                  'مرحباً $userName!',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'أنت على بعد خطوة واحدة من بدء رحلتك في تعلم البرمجة',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Link account card
                _LinkAccountCard(
                  onLink: _linkAccount,
                  isLoading: _isLinking,
                ),

                const Spacer(),

                // Skip button
                TextButton(
                  onPressed: _isLinking ? null : _skipToHome,
                  child: Text(
                    'تخطي والبدء لاحقاً',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeIllustration extends StatelessWidget {
  final int avatarId;

  const _WelcomeIllustration({required this.avatarId});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.secondary.withOpacity(0.2),
                AppColors.secondary.withOpacity(0.0),
              ],
            ),
          ),
        ),
        // Inner circle
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.celebration_rounded,
            size: 70,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _LinkAccountCard extends StatelessWidget {
  final VoidCallback onLink;
  final bool isLoading;

  const _LinkAccountCard({
    required this.onLink,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon and text row
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.cloud_sync_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ربط حسابك',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'احفظ تقدمك وانتقل بين الأجهزة بسهولة',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Google sign-in button
          CustomButton(
            label: 'ربط عبر Google',
            onPressed: isLoading ? null : onLink,
            isFullWidth: true,
            isLoading: isLoading,
            icon: Icons.g_mobiledata_rounded,
          ),

          const SizedBox(height: 12),

          // Benefits list
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BenefitChip(icon: Icons.sync_rounded, label: 'مزامنة'),
              const SizedBox(width: 8),
              _BenefitChip(icon: Icons.devices_rounded, label: 'عدة أجهزة'),
              const SizedBox(width: 8),
              _BenefitChip(icon: Icons.backup_rounded, label: 'نسخ احتياطي'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
