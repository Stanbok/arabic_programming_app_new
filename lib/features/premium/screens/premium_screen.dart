import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Back Button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
                
                // Premium Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.premium, Color(0xFFE8C547)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.premium.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Python Premium',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'احصل على تجربة تعلم متكاملة',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Features List
                _FeatureItem(
                  icon: Icons.download,
                  title: 'تحميل غير محدود',
                  description: 'حمّل جميع الدروس للتعلم بدون إنترنت',
                ),
                _FeatureItem(
                  icon: Icons.block,
                  title: 'بدون إعلانات',
                  description: 'تجربة تعلم سلسة بدون انقطاع',
                ),
                _FeatureItem(
                  icon: Icons.speed,
                  title: 'وصول مبكر',
                  description: 'احصل على الدروس الجديدة قبل الجميع',
                ),
                _FeatureItem(
                  icon: Icons.support_agent,
                  title: 'دعم مخصص',
                  description: 'أولوية في الدعم الفني',
                ),
                
                const SizedBox(height: 40),
                
                // Pricing Cards
                _PricingCard(
                  title: 'شهري',
                  price: '9.99',
                  period: '/شهر',
                  isPopular: false,
                  onTap: () => _subscribe(context, 'monthly'),
                ),
                
                const SizedBox(height: 16),
                
                _PricingCard(
                  title: 'سنوي',
                  price: '79.99',
                  period: '/سنة',
                  isPopular: true,
                  savings: 'وفّر 40%',
                  onTap: () => _subscribe(context, 'yearly'),
                ),
                
                const SizedBox(height: 24),
                
                // Terms
                const Text(
                  'بالاشتراك، أنت توافق على شروط الخدمة وسياسة الخصوصية',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () => _restorePurchases(context),
                  child: const Text('استعادة المشتريات'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _subscribe(BuildContext context, String plan) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري المعالجة...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Simulate payment processing
    // Replace with actual in-app purchase implementation
    await Future.delayed(const Duration(seconds: 2));

    // Update user to premium
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final userId = authService.currentUser?.uid;

    if (userId != null) {
      await firestoreService.upgradeToPremium(userId);
    }

    Navigator.pop(context); // Close loading
    Navigator.pop(context); // Close premium screen

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم الاشتراك بنجاح! مرحباً بك في Premium'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _restorePurchases(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري استعادة المشتريات...')),
    );
    
    await Future.delayed(const Duration(seconds: 1));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لم يتم العثور على مشتريات سابقة')),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.premium.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.premium),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final bool isPopular;
  final String? savings;
  final VoidCallback onTap;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    required this.isPopular,
    this.savings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isPopular
              ? const LinearGradient(
                  colors: [AppColors.premium, Color(0xFFE8C547)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPopular ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isPopular ? null : Border.all(color: AppColors.border),
          boxShadow: isPopular
              ? [
                  BoxShadow(
                    color: AppColors.premium.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isPopular ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'الأفضل',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (savings != null)
                    Text(
                      savings!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isPopular
                            ? Colors.white.withOpacity(0.8)
                            : AppColors.success,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$$price',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isPopular ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPopular
                        ? Colors.white.withOpacity(0.8)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
