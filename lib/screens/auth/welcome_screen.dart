import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Logo and Animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.code,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Welcome Text
              Text(
                'مرحباً بك في',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Python in Arabic',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'تعلم البرمجة بلغة Python بطريقة تفاعلية وممتعة',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Features List
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      context,
                      Icons.school_outlined,
                      'دروس تفاعلية',
                      'تعلم من خلال أمثلة عملية وتطبيقات حقيقية',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context,
                      Icons.quiz_outlined,
                      'اختبارات تقييمية',
                      'اختبر معلوماتك واحصل على نقاط الخبرة',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context,
                      Icons.trending_up_outlined,
                      'تتبع التقدم',
                      'راقب تطورك وحقق إنجازات جديدة',
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () => context.go('/register'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  OutlinedButton(
                    onPressed: () => context.go('/login'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'لديك حساب بالفعل؟ تسجيل الدخول',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
