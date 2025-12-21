import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../widgets/avatar_selector.dart';

class PersonalizationScreen extends ConsumerStatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  ConsumerState<PersonalizationScreen> createState() =>
      _PersonalizationScreenState();
}

class _PersonalizationScreenState extends ConsumerState<PersonalizationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  int _selectedAvatarIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'يرجى إدخال اسمك',
        type: SnackBarType.warning,
      );
      _nameFocusNode.requestFocus();
      return;
    }

    if (name.length < 2) {
      AppSnackBar.show(
        context,
        message: 'الاسم يجب أن يكون حرفين على الأقل',
        type: SnackBarType.warning,
      );
      return;
    }

    // Save profile
    ref.read(profileProvider.notifier).updateName(name);
    ref.read(profileProvider.notifier).updateAvatar(_selectedAvatarIndex);

    Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أخبرنا عنك'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name section
              _SectionTitle(title: 'ما اسمك؟'),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'أدخل اسمك هنا',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _continue(),
              ),
              const SizedBox(height: 32),

              // Avatar section
              _SectionTitle(title: 'اختر صورتك الرمزية'),
              const SizedBox(height: 16),
              AvatarSelector(
                selectedIndex: _selectedAvatarIndex,
                onSelected: (index) {
                  setState(() => _selectedAvatarIndex = index);
                },
              ),
              const SizedBox(height: 48),

              // Continue button
              CustomButton(
                label: 'متابعة',
                onPressed: _continue,
                isFullWidth: true,
                icon: Icons.arrow_back_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
