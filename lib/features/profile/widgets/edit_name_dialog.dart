import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class EditNameDialog extends StatefulWidget {
  final String currentName;
  final void Function(String name) onSave;

  const EditNameDialog({
    super.key,
    required this.currentName,
    required this.onSave,
  });

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل الاسم'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: 'أدخل اسمك',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              widget.onSave(name);
              Navigator.pop(context);
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
