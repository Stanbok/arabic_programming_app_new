import 'package:flutter/material.dart';

class MixedTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const MixedTextWidget({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        text,
        style: style,
        textAlign: textAlign ?? TextAlign.right,
        maxLines: maxLines,
        overflow: overflow,
        textDirection: TextDirection.rtl,
        textWidthBasis: TextWidthBasis.longestLine,
      ),
    );
  }
}

class MixedRichTextWidget extends StatelessWidget {
  final List<TextSpan> children;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const MixedRichTextWidget({
    super.key,
    required this.children,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: textAlign ?? TextAlign.right,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.clip,
        text: TextSpan(
          style: style ?? DefaultTextStyle.of(context).style,
          children: children,
        ),
      ),
    );
  }
}
