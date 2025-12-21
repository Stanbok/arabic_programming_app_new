import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/carousel_page.dart';

class CarouselScreen extends StatefulWidget {
  const CarouselScreen({super.key});

  @override
  State<CarouselScreen> createState() => _CarouselScreenState();
}

class _CarouselScreenState extends State<CarouselScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<CarouselItemData> _items = [
    CarouselItemData(
      icon: Icons.code_rounded,
      iconColor: AppColors.primary,
      backgroundColor: AppColors.primary,
      title: 'تعلم Python بالعربي',
      description: 'ابدأ رحلتك في تعلم البرمجة بلغتك الأم مع دروس تفاعلية وممتعة',
    ),
    CarouselItemData(
      icon: Icons.offline_bolt_rounded,
      iconColor: AppColors.secondary,
      backgroundColor: AppColors.secondary,
      title: 'تعلم بدون إنترنت',
      description: 'حمّل الدروس مرة واحدة وتعلم في أي وقت وأي مكان بدون اتصال',
    ),
    CarouselItemData(
      icon: Icons.emoji_events_rounded,
      iconColor: AppColors.accent,
      backgroundColor: AppColors.accent,
      title: 'اختبر معلوماتك',
      description: 'أسئلة تفاعلية متنوعة تثبت المعلومات وتقيس مستوى فهمك',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToPersonalization();
    }
  }

  void _navigateToPersonalization() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.personalization);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _navigateToPersonalization,
                  child: Text(
                    'تخطي',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return CarouselPage(item: _items[index]);
                },
              ),
            ),
            // Dots indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? _items[_currentPage].backgroundColor
                          : (isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            // Next/Start button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: CustomButton(
                label: _currentPage == _items.length - 1 ? 'ابدأ الآن' : 'التالي',
                onPressed: _nextPage,
                isFullWidth: true,
                icon: _currentPage == _items.length - 1
                    ? Icons.rocket_launch_rounded
                    : Icons.arrow_back_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CarouselItemData {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String description;

  const CarouselItemData({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.description,
  });
}
