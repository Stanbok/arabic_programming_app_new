import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import 'personalization_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final result = await authService.signInWithGoogle();
      if (result != null && mounted) {
        _checkAndNavigate(result.user!.uid);
      }
    } catch (e) {
      _showError('فشل تسجيل الدخول بجوجل');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final result = _isLogin
          ? await authService.signInWithEmail(
              _emailController.text.trim(),
              _passwordController.text,
            )
          : await authService.signUpWithEmail(
              _emailController.text.trim(),
              _passwordController.text,
            );
      
      if (mounted) {
        _checkAndNavigate(result.user!.uid);
      }
    } catch (e) {
      _showError(_isLogin ? 'فشل تسجيل الدخول' : 'فشل إنشاء الحساب');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final result = await authService.signInAnonymously();
      if (mounted) {
        _checkAndNavigate(result.user!.uid);
      }
    } catch (e) {
      _showError('فشل الدخول كضيف');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAndNavigate(String userId) async {
    final firestoreService = context.read<FirestoreService>();
    final user = await firestoreService.getUser(userId);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PersonalizationScreen(
            userId: userId,
            isNewUser: user == null,
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
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
              
              // Header
              const Text(
                'مرحباً بك',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'سجل دخولك للمتابعة' : 'أنشئ حسابك الجديد',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Google Sign In
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: const Text('المتابعة بحساب جوجل'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Divider
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'أو',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Email Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال البريد الإلكتروني';
                        }
                        if (!value.contains('@')) {
                          return 'بريد إلكتروني غير صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: Icon(Icons.lock_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال كلمة المرور';
                        }
                        if (value.length < 6) {
                          return 'كلمة المرور قصيرة جداً';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleEmailAuth,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isLogin ? 'تسجيل الدخول' : 'إنشاء حساب'),
              ),
              
              const SizedBox(height: 16),
              
              // Toggle Login/Register
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? 'ليس لديك حساب؟ سجل الآن' : 'لديك حساب؟ سجل دخولك',
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Anonymous Sign In
              TextButton.icon(
                onPressed: _isLoading ? null : _handleAnonymousSignIn,
                icon: const Icon(Icons.person_outline),
                label: const Text('الدخول كضيف'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
