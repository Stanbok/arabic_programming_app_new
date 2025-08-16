import 'package:flutter/material.dart';
import 'enhanced_loading_widget.dart';

class AdaptiveLoadingButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final String? loadingText;
  final LoadingType loadingType;
  final double? progress;

  const AdaptiveLoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.loadingText,
    this.loadingType = LoadingType.circular,
    this.progress,
  });

  @override
  State<AdaptiveLoadingButton> createState() => _AdaptiveLoadingButtonState();
}

class _AdaptiveLoadingButtonState extends State<AdaptiveLoadingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    if (widget.isOutlined) {
      return OutlinedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        child: _buildButtonContent(),
      );
    }

    return ElevatedButton(
      onPressed: widget.isLoading ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor: widget.textColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: widget.isLoading ? 0 : 2,
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EnhancedLoadingWidget(
            size: 20,
            type: widget.loadingType,
            color: widget.textColor ?? Colors.white,
            showProgress: widget.progress != null,
            progress: widget.progress,
          ),
          if (widget.loadingText != null) ...[
            const SizedBox(width: 12),
            Text(
              widget.loadingText!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 20),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
