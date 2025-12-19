import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NoInternetPopup extends StatefulWidget {
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const NoInternetPopup({
    super.key,
    required this.onRetry,
    required this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onRetry,
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) => NoInternetPopup(
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<NoInternetPopup> createState() => _NoInternetPopupState();
}

class _NoInternetPopupState extends State<NoInternetPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isRetrying = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;

    setState(() => _isRetrying = true);

    // محاولة فورية أولى
    await Future.delayed(const Duration(milliseconds: 500));

    // استراتيجية Exponential backoff مع حد أقصى 3 محاولات
    final maxRetries = 3;
    final delays = [1, 2, 4]; // بالثواني

    while (_retryCount < maxRetries) {
      try {
        widget.onRetry();
        // إذا نجحت، اغلق النافذة
        if (mounted) {
          await _controller.reverse();
          Navigator.of(context).pop();
        }
        return;
      } catch (e) {
        _retryCount++;
        if (_retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: delays[_retryCount - 1]));
        }
      }
    }

    // إذا فشلت جميع المحاولات
    if (mounted) {
      setState(() => _isRetrying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم نتمكن من الاتصال. تأكّد من الشبكة أو جرّب لاحقاً.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleDismiss() async {
    await _controller.reverse();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.84,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر الإغلاق
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _handleDismiss,
                    tooltip: 'إغلاق — العودة للرئيسية',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // أيقونة سحابة مع علامة قطع
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B6B6B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off,
                    size: 40,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // العنوان
                const Text(
                  'لا يوجد اتصال بالإنترنت',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // الرسالة التوضيحية
                const Text(
                  'تحقّق من اتصالك بالإنترنت ثم أعد المحاولة.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // الأزرار
                if (_isRetrying)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'جارٍ إعادة المحاولة...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handleDismiss,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('موافق'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleRetry,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
