import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/user_model.dart';
import 'welcome_screen.dart';
import '../../home/screens/main_screen.dart';

class PersonalizationScreen extends StatefulWidget {
  final String userId;
  final bool isNewUser;

  const PersonalizationScreen({
    super.key,
    required this.userId,
    required this.isNewUser,
  });

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  final _nameController = TextEditingController();
  int _selectedAvatar = 1;
  bool _isLoading = false;

  final List<int> _avatarIds = List.generate(12, (i) => i + 1);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسمك'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestoreService = context.read<FirestoreService>();

      if (widget.isNewUser) {
        final newUser = UserModel(
          id: widget.userId,
          name: _nameController.text.trim(),
          avatarId: _selectedAvatar,
          isPremium: false,
          completedLessons: 0,
          createdAt: DateTime.now(),
        );
        await firestoreService.createUser(newUser);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => WelcomeScreen(
                userName: _nameController.text.trim(),
              ),
            ),
          );
        }
      } else {
        await firestoreService.updateUser(widget.userId, {
          'name': _nameController.text.trim(),
          'avatarId': _selectedAvatar,
        });
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ، يرجى المحاولة مرة أخرى'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              const Text(
                'أخبرنا عن نفسك',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'اختر صورتك الرمزية واسمك',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              const Text(
                'اختر صورتك الرمزية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _avatarIds.length,
                itemBuilder: (context, index) {
                  final avatarId = _avatarIds[index];
                  final isSelected = avatarId == _selectedAvatar;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = avatarId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getAvatarEmoji(avatarId),
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'ما اسمك؟',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'أدخل اسمك هنا',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textAlign: TextAlign.right,
              ),
              
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _continue,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('متابعة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAvatarEmoji(int id) {
    final emojis = [
      '👨‍💻', '👩‍💻', '🧑‍💻', '👨‍🎓', '👩‍🎓', '🧑‍🎓',
      '🦊', '🐱', '🐶', '🦁', '🐼', '🐨',
    ];
    return emojis[(id - 1) % emojis.length];
  }
}
