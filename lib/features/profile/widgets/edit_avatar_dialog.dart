import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../onboarding/widgets/avatar_widget.dart';

class EditAvatarDialog extends StatefulWidget {
  final int currentAvatarId;
  final void Function(int avatarId) onSave;

  const EditAvatarDialog({
    super.key,
    required this.currentAvatarId,
    required this.onSave,
  });

  @override
  State<EditAvatarDialog> createState() => _EditAvatarDialogState();
}

class _EditAvatarDialogState extends State<EditAvatarDialog> {
  late int _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentAvatarId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('اختر صورتك'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: 10,
          itemBuilder: (context, index) {
            final isSelected = _selectedId == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedId = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: AppColors.primary, width: 3)
                      : null,
                ),
                child: AvatarWidget(
                  avatarId: index,
                  size: 48,
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_selectedId);
            Navigator.pop(context);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
