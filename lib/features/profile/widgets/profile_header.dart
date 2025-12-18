import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

class ProfileHeader extends ConsumerWidget {
  final UserModel user;

  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnonymous = ref.watch(isAnonymousProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar with VIP badge
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(
                    color: user.isPremium ? AppColors.accent : AppColors.primary,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (user.isPremium ? AppColors.accent : AppColors.primary)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getAvatarEmoji(user.selectedAvatarIndex),
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              // VIP Badge
              if (user.isPremium)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'VIP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            user.displayName ?? AppStrings.guest,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          // Account status
          Text(
            isAnonymous ? 'حساب مؤقت' : user.email ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),

          // Link account button (if anonymous)
          if (isAnonymous) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _linkAccount(context, ref),
              icon: Image.asset(
                'assets/icons/google.png',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.link,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              label: const Text(AppStrings.linkAccount),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getAvatarEmoji(int index) {
    const avatars = ['🦁', '🐼', '🦊', '🐸', '🐵', '🐰', '🐻', '🦄', '🐲', '🦋', '🐬', '🦉'];
    if (index >= 0 && index < avatars.length) {
      return avatars[index];
    }
    return '🦁';
  }

  Future<void> _linkAccount(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(userProvider.notifier).linkWithGoogle();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم ربط الحساب بنجاح!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل ربط الحساب: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
