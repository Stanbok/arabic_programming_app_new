import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../widgets/feature_page.dart';
import '../widgets/page_indicator.dart';

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<FeatureData> _features = const [
    FeatureData(
      icon: '🎯',
      title: 'دروس تفاعلية',
      description: 'تعلم البرمجة بطريقة ممتعة وسهلة مع دروس مصممة خصيصاً للمبتدئين',
      color: AppColors.primary,
    ),
    FeatureData(
      icon: '🏆',
      title: 'اختبارات وتحديات',
      description: 'اختبر معلوماتك واكسب النقاط والشارات مع كل إنجاز',
      color: AppColors.secondary,
    ),
    FeatureData(
      icon: '📱',
      title: 'تعلم بدون إنترنت',
      description: 'حمّل الدروس وتعلم في أي وقت وأي مكان حتى بدون اتصال',
      color: AppColors.accent,
    ),
  ];

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _goToNext() {
    if (_currentPage < _features.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.goNamed(RouteNames.onboardingPersonalize);
    }
  }

  void _skip() {
    context.goNamed(RouteNames.onboardingPersonalize);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'تخطي',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Feature pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  return FeaturePage(data: _features[index]);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: PageIndicator(
                count: _features.length,
                currentIndex: _currentPage,
              ),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _goToNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == _features.length - 1 ? 'ابدأ الآن' : 'التالي',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureData {
  final String icon;
  final String title;
  final String description;
  final Color color;

  const FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
