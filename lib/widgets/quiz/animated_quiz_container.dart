import 'package:flutter/material.dart';
import 'quiz_theme.dart';

class AnimatedQuizContainer extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final bool isCorrect;
  final bool isIncorrect;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const AnimatedQuizContainer({
    Key? key,
    required this.child,
    this.isSelected = false,
    this.isCorrect = false,
    this.isIncorrect = false,
    this.onTap,
    this.padding,
  }) : super(key: key);

  @override
  State<AnimatedQuizContainer> createState() => _AnimatedQuizContainerState();
}

class _AnimatedQuizContainerState extends State<AnimatedQuizContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  BoxDecoration _getDecoration() {
    if (widget.isCorrect) return QuizTheme.correctCardDecoration;
    if (widget.isIncorrect) return QuizTheme.incorrectCardDecoration;
    if (widget.isSelected) return QuizTheme.selectedCardDecoration;
    return QuizTheme.cardDecoration;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTapDown: (_) => _controller.forward(),
              onTapUp: (_) {
                _controller.reverse();
                widget.onTap?.call();
              },
              onTapCancel: () => _controller.reverse(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: _getDecoration(),
                padding: widget.padding ?? const EdgeInsets.all(16),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
