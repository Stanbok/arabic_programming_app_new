import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class StatsRow extends StatelessWidget {
  final int correct;
  final int wrong;
  final int skipped;
  final String time;

  const StatsRow({
    super.key,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.check_circle,
            value: correct.toString(),
            label: AppStrings.correct,
            color: AppColors.success,
          ),
          _buildDivider(),
          _StatItem(
            icon: Icons.cancel,
            value: wrong.toString(),
            label: AppStrings.wrong,
            color: AppColors.error,
          ),
          _buildDivider(),
          _StatItem(
            icon: Icons.remove_circle,
            value: skipped.toString(),
            label: AppStrings.skipped,
            color: AppColors.textSecondary,
          ),
          _buildDivider(),
          _StatItem(
            icon: Icons.timer,
            value: time,
            label: AppStrings.time,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.divider,
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
