import 'package:flutter/material.dart';
import 'adaptive_loading_button.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final String? loadingText;
  final double? progress;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.loadingText,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLoadingButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isOutlined: isOutlined,
      icon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
      loadingText: loadingText ?? (isLoading ? 'جاري التحميل...' : null),
      progress: progress,
    );
  }
}
