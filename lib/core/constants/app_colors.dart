import 'package:flutter/material.dart';

/// App color palette
/// Primary: Deep Blue
/// Accent: Coral/Orange
/// Style: Modern Minimal + Soft Pop
class AppColors {
  AppColors._();

  // Primary - Deep Blue
  static const Color primary = Color(0xFF1A365D);
  static const Color primaryLight = Color(0xFF2D4A7C);
  static const Color primaryDark = Color(0xFF0F2442);

  // Accent - Coral/Orange (Soft Pop)
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFF8E8E);
  static const Color accentDark = Color(0xFFE85555);

  // Secondary - Teal
  static const Color secondary = Color(0xFF38B2AC);
  static const Color secondaryLight = Color(0xFF4FD1C5);

  // Success/Error/Warning
  static const Color success = Color(0xFF48BB78);
  static const Color error = Color(0xFFFC8181);
  static const Color warning = Color(0xFFF6AD55);

  // Neutrals - Light Theme
  static const Color backgroundLight = Color(0xFFF7FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A202C);
  static const Color textSecondaryLight = Color(0xFF718096);
  static const Color dividerLight = Color(0xFFE2E8F0);

  // Neutrals - Dark Theme
  static const Color backgroundDark = Color(0xFF1A202C);
  static const Color surfaceDark = Color(0xFF2D3748);
  static const Color textPrimaryDark = Color(0xFFF7FAFC);
  static const Color textSecondaryDark = Color(0xFFA0AEC0);
  static const Color dividerDark = Color(0xFF4A5568);

  // Code block colors
  static const Color codeBackground = Color(0xFF2D3748);
  static const Color codeText = Color(0xFFE2E8F0);

  // VIP/Premium
  static const Color vipGold = Color(0xFFD69E2E);
  static const Color vipGoldLight = Color(0xFFF6E05E);

  // Lock states
  static const Color locked = Color(0xFFA0AEC0);
  static const Color available = Color(0xFF38B2AC);
  static const Color completed = Color(0xFF48BB78);
}
