import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class AdminGestureDetector extends StatefulWidget {
  final Widget child;

  const AdminGestureDetector({Key? key, required this.child}) : super(key: key);

  @override
  State<AdminGestureDetector> createState() => _AdminGestureDetectorState();
}

class _AdminGestureDetectorState extends State<AdminGestureDetector> {
  int _tapCount = 0;
  DateTime? _lastTapTime;
  static const Duration _tapTimeout = Duration(seconds: 2);
  static const int _requiredTaps = 7; // عدد النقرات المطلوبة
  static const String _adminUID = 'FkRMLu7IC3WLSD6jzujnJ79elUO2'; // UID المصرح له

  void _handleTap() {
    final now = DateTime.now();
    
    if (_lastTapTime == null || now.difference(_lastTapTime!) > _tapTimeout) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    
    _lastTapTime = now;

    if (_tapCount >= _requiredTaps) {
      _checkAdminAccess();
      _tapCount = 0;
      _lastTapTime = null;
    }
  }

  void _checkAdminAccess() {
    final authProvider = context.read<AuthProvider>();
    
    // التحقق من أن المستخدم مسجل دخول وليس ضيف
    if (authProvider.user == null || authProvider.isGuestUser) {
      _showLoginRequiredDialog();
      return;
    }

    // التحقق من UID المستخدم
    if (authProvider.user!.uid == _adminUID) {
      _showAdminAccessDialog();
    } else {
      _showUnauthorizedDialog();
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.login, color: Colors.blue),
            SizedBox(width: 8),
            Text('تسجيل الدخول مطلوب'),
          ],
        ),
        content: const Text('يجب تسجيل الدخول بحساب مصرح له للوصول إلى لوحة التحكم الإدارية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showAdminAccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.red),
            SizedBox(width: 8),
            Text('وضع الإدارة'),
          ],
        ),
        content: const Text('هل تريد الدخول إلى لوحة التحكم الإدارية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openAdminDashboard();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('دخول'),
          ),
        ],
      ),
    );
  }

  void _showUnauthorizedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('غير مصرح'),
          ],
        ),
        content: const Text('ليس لديك صلاحية للوصول إلى لوحة التحكم الإدارية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _openAdminDashboard() {
    // الانتقال إلى لوحة التحكم الإدارية
    context.go('/admin/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: widget.child,
    );
  }
}
