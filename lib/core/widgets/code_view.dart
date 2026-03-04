import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' as hi;
import 'package:highlight/languages/python.dart' as python;

class CodeView extends StatelessWidget {
  final String code;

  const CodeView({super.key, required this.code});

  TextSpan _convert(hi.Node node, TextStyle baseStyle) {
    if (node.value != null) {
      return TextSpan(text: node.value, style: baseStyle.copyWith(color: _colorFor(node.className)));
    }
    if (node.children != null) {
      return TextSpan(
          children: node.children!.map((n) => _convert(n, baseStyle)).toList(),
          style: baseStyle.copyWith(color: _colorFor(node.className)));
    }
    return const TextSpan(text: '');
  }

  Color? _colorFor(String? className) {
    if (className == null) return Colors.black;
    if (className.contains('keyword')) return Colors.purple;
    if (className.contains('string')) return Colors.green.shade700;
    if (className.contains('number')) return Colors.teal;
    if (className.contains('comment')) return Colors.grey;
    if (className.contains('built_in')) return Colors.orange;
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final result = hi.highlight.parse(code, language: 'python', autoDetection: false, grammar: python.python);
    final baseStyle = const TextStyle(fontFamily: 'monospace', fontSize: 14.0);
    final span = TextSpan(children: result.nodes?.map((n) => _convert(n, baseStyle)).toList() ?? [TextSpan(text: code, style: baseStyle)]);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: RichText(text: span),
      ),
    );
  }
}
