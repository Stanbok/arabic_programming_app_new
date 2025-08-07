import 'package:flutter/material.dart';

class XPBar extends StatelessWidget {
  final int currentXP;
  final int maxXP;
  final int level;

  const XPBar({
    super.key,
    required this.currentXP,
    required this.maxXP,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxXP > 0 ? currentXP / maxXP : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المستوى $level',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$currentXP / $maxXP XP',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
