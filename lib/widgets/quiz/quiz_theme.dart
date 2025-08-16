import 'package:flutter/material.dart';

class QuizTheme {
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color correctColor = Color(0xFF4CAF50);
  static const Color incorrectColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF212121);
  static const Color hintColor = Color(0xFF757575);

  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration selectedCardDecoration = BoxDecoration(
    color: primaryColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: primaryColor, width: 2),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration correctCardDecoration = BoxDecoration(
    color: correctColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: correctColor, width: 2),
    boxShadow: [
      BoxShadow(
        color: correctColor.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration incorrectCardDecoration = BoxDecoration(
    color: incorrectColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: incorrectColor, width: 2),
    boxShadow: [
      BoxShadow(
        color: incorrectColor.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static TextStyle questionTextStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textColor,
    height: 1.4,
  );

  static TextStyle optionTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textColor,
  );

  static TextStyle hintTextStyle = const TextStyle(
    fontSize: 14,
    color: hintColor,
    fontStyle: FontStyle.italic,
  );

  static TextStyle codeTextStyle = const TextStyle(
    fontSize: 14,
    fontFamily: 'monospace',
    color: textColor,
    backgroundColor: Color(0xFFF8F8F8),
  );
}
