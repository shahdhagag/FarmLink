import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:farmlink/core/theme/app_theme.dart';

import '../../../data/services/auth_services.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/fl_text_field.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _loading = false;

  bool get isFarmer => widget.role == 'farmer';
  Color get roleColor => isFarmer ? AppColors.primary : AppColors.secondary;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await _authService.signInWithEmail(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      
      if (!mounted) return;
      
      if (user.role != widget.role) {
        await _authService.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('This email is registered as a ${user.role}, not a ${widget.role}.'),
            backgroundColor: AppColors.error,
          ));
        }
        return;
      }

      if (user.isFarmer) {
        context.go('/farmer');
      } else {
        context.go('/buyer');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

// Inside _LoginScreenState in login_screen.dart
  Future<void> _forgotPassword() async {
    // Option 1: Navigate to the new screen (Recommended)
    context.push('/forgot-password/${widget.role}');

    /* Option 2: If you aren't using deep linking yet, use:
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => ForgotPasswordScreen(role: widget.role)
  ));
  */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/welcome'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: roleColor,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Role icon badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    isFarmer
                        ? Icons.agriculture_rounded
                        : Icons.shopping_basket_rounded,
                    color: roleColor,
                    size: 36,
                  ),
                ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms),

                const SizedBox(height: 22),

                Text(
                  '${isFarmer ? "Farmer" : "Buyer"} Login',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.3, end: 0),

                const SizedBox(height: 6),

                Text(
                  isFarmer
                      ? 'Welcome back! Manage your crops and orders.'
                      : 'Welcome back! Find fresh produce near you.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate(delay: 150.ms).fadeIn(),

                const SizedBox(height: 36),

                FLTextField(
                  label: 'Email Address',
                  controller: _emailCtrl,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  color: roleColor, // Dynamic color (Green/Blue)
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.2, end: 0),

                const SizedBox(height: 16),

                FLTextField(
                  label: 'Password',
                  controller: _passwordCtrl,
                  color: roleColor, // Dynamic color (Green/Blue)
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your password';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ).animate(delay: 250.ms).fadeIn().slideX(begin: -0.2, end: 0),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: roleColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ).animate(delay: 300.ms).fadeIn(),

                const SizedBox(height: 8),

                FLButton(
                  label: 'Log In',
                  onPressed: _login,
                  isLoading: _loading,
                  color: roleColor,
                ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.3, end: 0),

                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.go('/signup/${widget.role}'),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 400.ms).fadeIn(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}