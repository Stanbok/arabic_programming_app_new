import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class StarsDisplay extends StatefulWidget {
  final int starsEarned;
  final int totalStars;

  const StarsDisplay({
    super.key,
    required this.starsEarned,
    this.totalStars = 3,
  });

  @override
  State<StarsDisplay> createState() => _StarsDisplayState();
}

class _StarsDisplayState extends State<StarsDisplay>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.totalStars,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    // Stagger the animations
    for (int i = 0; i < widget.starsEarned; i++) {
      Future.delayed(Duration(milliseconds: 300 + (i * 200)), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.totalStars, (index) {
        final isEarned = index < widget.starsEarned;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AnimatedBuilder(
            animation: _scaleAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: isEarned ? _scaleAnimations[index].value : 1.0,
                child: Icon(
                  isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 48,
                  color: isEarned ? AppColors.starGold : AppColors.divider,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
