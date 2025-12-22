import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../data/repositories/auth_repository.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isLinking = false;
  int _selectedPlan = 0; // 0 = monthly, 1 = annual

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If not linked, show link gate first
    if (!profile.isLinked) {
      return _buildLinkGate(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.vipGold, AppColors.vipGoldLight],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Python Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اشترك الآن واستمتع بتجربة تعلم بلا حدود',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Features comparison
            _buildFeatureComparison(context),
            
            const SizedBox(height: 24),
            
            // Plan selection
            _buildPlanSelection(context),
            
            const SizedBox(height: 24),
            
            // Subscribe button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _subscribe(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vipGold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _selectedPlan == 0 ? 'اشترك شهرياً' : 'اشترك سنوياً',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Restore purchases
            TextButton(
              onPressed: () => _restorePurchases(context),
              child: const Text('استعادة المشتريات'),
            ),
            
            const SizedBox(height: 8),
            
            // Skip
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'لاحقاً',
                style: TextStyle(color: AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkGate(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ربط الحساب'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_rounded,
                color: AppColors.primary,
                size: 64,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'ربط الحساب مطلوب',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'للاشتراك في Premium، يجب ربط حسابك بـ Google أولاً. هذا يضمن حفظ اشتراكك ومزامنة تقدمك عبر جميع أجهزتك.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLinking ? null : () => _linkAccount(context),
                icon: _isLinking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.g_mobiledata_rounded),
                label: Text(_isLinking ? 'جارٍ الربط...' : 'ربط بحساب Google'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لاحقاً'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureComparison(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مقارنة المميزات',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureRow('الدروس الأساسية', true, true),
        _buildFeatureRow('تحميل غير محدود', false, true),
        _buildFeatureRow('بدون إعلانات', false, true),
        _buildFeatureRow('مسارات VIP', false, true),
        _buildFeatureRow('شهادات إتمام', false, true),
        _buildFeatureRow('دعم أولوي', false, true),
      ],
    );
  }

  Widget _buildFeatureRow(String feature, bool inFree, bool inPremium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(feature),
          ),
          Expanded(
            child: Center(
              child: Icon(
                inFree ? Icons.check_circle_rounded : Icons.close_rounded,
                color: inFree ? AppColors.success : AppColors.locked,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                inPremium ? Icons.check_circle_rounded : Icons.close_rounded,
                color: inPremium ? AppColors.vipGold : AppColors.locked,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildPlanCard(
            context,
            index: 0,
            title: 'شهري',
            price: '4.99\$',
            period: '/شهر',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPlanCard(
            context,
            index: 1,
            title: 'سنوي',
            price: '39.99\$',
            period: '/سنة',
            badge: 'وفر 33%',
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required int index,
    required String title,
    required String price,
    required String period,
    String? badge,
  }) {
    final isSelected = _selectedPlan == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.vipGold.withOpacity(0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.vipGold : AppColors.dividerLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: price,
                    style: TextStyle(
                      color: isSelected ? AppColors.vipGold : AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: period,
                    style: TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _linkAccount(BuildContext context) async {
    setState(() => _isLinking = true);
    
    try {
      final result = await AuthRepository.instance.linkWithGoogle();
      if (result.success && mounted) {
        ref.read(profileProvider.notifier).setLinked(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم ربط الحساب بنجاح!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (!result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'فشل الربط'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الربط: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLinking = false);
    }
  }

  void _subscribe(BuildContext context) {
    // TODO: Implement in-app purchase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تنفيذ الاشتراك في مرحلة لاحقة'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _restorePurchases(BuildContext context) {
    // TODO: Implement restore purchases
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جارٍ البحث عن مشتريات سابقة...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
