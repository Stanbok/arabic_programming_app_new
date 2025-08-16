import 'package:flutter/material.dart';

class SmartRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String? refreshMessage;
  final bool showLastUpdated;

  const SmartRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshMessage,
    this.showLastUpdated = true,
  });

  @override
  State<SmartRefreshIndicator> createState() => _SmartRefreshIndicatorState();
}

class _SmartRefreshIndicatorState extends State<SmartRefreshIndicator> {
  DateTime? _lastUpdated;
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Column(
        children: [
          if (_isRefreshing && widget.refreshMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.refreshMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          if (widget.showLastUpdated && _lastUpdated != null && !_isRefreshing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Text(
                'آخر تحديث: ${_formatLastUpdated(_lastUpdated!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await widget.onRefresh();
      setState(() {
        _lastUpdated = DateTime.now();
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }
}
