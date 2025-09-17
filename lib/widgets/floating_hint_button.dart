import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // إضافة استيراد cloud_firestore للحصول على FieldValue
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import 'hint_purchase_dialog.dart';

class FloatingHintButton extends StatefulWidget {
  final VoidCallback? onHintRequested;
  final bool isEnabled;

  const FloatingHintButton({
    super.key,
    this.onHintRequested,
    this.isEnabled = true,
  });

  @override
  State<FloatingHintButton> createState() => _FloatingHintButtonState();
}

class _FloatingHintButtonState extends State<FloatingHintButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  bool _isProcessing = false; // إضافة متغير لمنع التفعيل المتعدد

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleHintRequest() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (authProvider.isGuestUser) {
        _showGuestDialog();
        return;
      }

      final user = userProvider.user;
      if (user == null) return;

      if (user.availableHints > 0) {
        // استخدام تلميح متاح
        await _useHint();
        if (widget.onHintRequested != null) {
          widget.onHintRequested!();
        }
      } else {
        await _showPurchaseDialog();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _useHint() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    try {
      final success = await userProvider.useHint();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد تلميحات متاحة'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في استخدام التلميح: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGuestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('تسجيل الدخول مطلوب'),
          ],
        ),
        content: const Text(
          'يجب تسجيل الدخول لاستخدام التلميحات والاستفادة من جميع ميزات التطبيق.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPurchaseDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const HintPurchaseDialog(),
    );
    // المستخدم يحتاج للضغط على الزر مرة أخرى لاستخدام التلميح
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final hintsCount = user?.availableHints ?? 0;
        final hasHints = hintsCount > 0;

        if (!widget.isEnabled) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 100,
          right: 16,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: hasHints
                          ? [
                              Colors.amber.withOpacity(_glowAnimation.value),
                              Colors.orange.withOpacity(_glowAnimation.value),
                            ]
                          : [
                              Colors.grey.withOpacity(0.3),
                              Colors.grey.withOpacity(0.5),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: hasHints
                        ? [
                            BoxShadow(
                              color: Colors.amber.withOpacity(_glowAnimation.value * 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isProcessing ? null : _handleHintRequest, // تعطيل الزر أثناء المعالجة
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasHints ? Colors.amber : Colors.grey[400],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isProcessing)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            else
                              Icon(
                                Icons.lightbulb,
                                color: hasHints ? Colors.white : Colors.grey[600],
                                size: 28,
                              ),
                            if (hintsCount > 0 && !_isProcessing)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    '$hintsCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
