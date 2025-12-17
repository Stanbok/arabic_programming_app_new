import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumBadge extends StatelessWidget {
  final double size;
  final bool showLabel;

  const PremiumBadge({
    super.key,
    this.size = 16,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 10 : 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.premium, Color(0xFFE8C547)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.premium.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            color: Colors.white,
            size: size,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              'VIP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.75,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
