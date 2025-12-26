import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/settings_provider.dart';

/// A widget that displays code with syntax highlighting, copy button, and horizontal scroll.
/// Always displayed in LTR direction regardless of app direction.
class CodeBlockWidget extends ConsumerStatefulWidget {
  final String code;
  final String? language;

  const CodeBlockWidget({
    super.key,
    required this.code,
    this.language,
  });

  @override
  ConsumerState<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends ConsumerState<CodeBlockWidget> {
  bool _copied = false;

  void _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDarkTheme = settings.isCodeThemeDark;
    final theme = isDarkTheme ? atomOneDarkTheme : atomOneLightTheme;
    final backgroundColor = isDarkTheme 
        ? const Color(0xFF282C34) 
        : const Color(0xFFFAFAFA);
    final borderColor = isDarkTheme 
        ? Colors.white.withOpacity(0.1) 
        : Colors.black.withOpacity(0.1);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with language and copy button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkTheme 
                    ? Colors.white.withOpacity(0.05) 
                    : Colors.black.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Language badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.language ?? 'python',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDarkTheme ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  // Copy button
                  InkWell(
                    onTap: _copyCode,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _copied ? Icons.check_rounded : Icons.copy_rounded,
                            size: 14,
                            color: _copied 
                                ? AppColors.success 
                                : (isDarkTheme ? Colors.white60 : Colors.black54),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _copied ? 'تم النسخ' : 'نسخ',
                            style: TextStyle(
                              fontSize: 11,
                              color: _copied 
                                  ? AppColors.success 
                                  : (isDarkTheme ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Code content with horizontal scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: HighlightView(
                widget.code,
                language: widget.language ?? 'python',
                theme: theme,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.6,
                  letterSpacing: 0,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
