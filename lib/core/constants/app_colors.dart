import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary - Soft Blue (friendly, calm)
  static const Color primary = Color(0xFF5B9BD5);
  static const Color primaryLight = Color(0xFF8BBFEA);
  static const Color primaryDark = Color(0xFF3A7BB8);
  
  // Secondary - Warm Orange (energetic, fun)
  static const Color secondary = Color(0xFFFF9F43);
  static const Color secondaryLight = Color(0xFFFFBE7D);
  static const Color secondaryDark = Color(0xFFE67E22);
  
  // Accent - Soft Green (success, progress)
  static const Color accent = Color(0xFF26DE81);
  static const Color accentLight = Color(0xFF7BF5B5);
  static const Color accentDark = Color(0xFF20BF6B);
  
  // Neutrals
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  
  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  
  // States
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Lesson States
  static const Color lessonLocked = Color(0xFFCBD5E1);
  static const Color lessonAvailable = Color(0xFF5B9BD5);
  static const Color lessonDownloaded = Color(0xFF8B5CF6);
  static const Color lessonCompleted = Color(0xFF22C55E);
  
  // Premium
  static const Color premium = Color(0xFFFFD700);
  static const Color premiumGradientStart = Color(0xFFFFD700);
  static const Color premiumGradientEnd = Color(0xFFFFA500);
  
  static const Color starGold = Color(0xFFFFD700);
  static const Color divider = Color(0xFFE2E8F0);
}
