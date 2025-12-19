import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_screen.dart';

class CarouselScreen extends StatefulWidget {
  const CarouselScreen({super.key});

  @override
  State<CarouselScreen> createState() => _CarouselScreenState();
}

class _CarouselScreenState extends State<CarouselScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_SlideData> _slides = [
    _SlideData(
      icon: Icons.school,
      title: 'تعلم بايثون بسهولة',
      description: 'دروس تفاعلية مصممة للمبتدئين باللغة العربية',
    ),
    _SlideData(
      icon: Icons.emoji_events,
      title: 'اكسب نقاط ومكافآت',
      description: 'أكمل الدروس واجمع الجواهر لفتح محتوى جديد',
    ),
    _SlideData(
      icon: Icons.offline_bolt,
      title: 'تعلم بدون إنترنت',
      description: 'حمّل الدروس وتعلم في أي وقت وأي مكان',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topLeft,
              child: TextButton(
                onPressed: _navigateToAuth,
                child: const Text('تخطي'),
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _SlideWidget(data: _slides[index]);
                },
              ),
            ),
            
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Next/Start button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _navigateToAuth();
                    }
                  },
                  child: Text(
                    _currentPage < _slides.length - 1 ? 'التالي' : 'ابدأ الآن',
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String description;

  _SlideData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _SlideWidget extends StatelessWidget {
  final _SlideData data;

  const _SlideWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
