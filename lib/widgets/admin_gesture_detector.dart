import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';

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
    final adminProvider = context.read<AdminProvider>();
    
    if (adminProvider.isAuthorizedAdmin) {
      _showAdminAccessDialog();
    } else {
      _showUnauthorizedDialog();
    }
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
    final adminProvider = context.read<AdminProvider>();
    adminProvider.toggleAdminMode();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminDashboardScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: widget.child,
    );
  }
}
