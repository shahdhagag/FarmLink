import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:farmlink/core/theme/app_theme.dart';

import '../../../data/services/auth_services.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/fl_text_field.dart';

class SignupScreen extends StatefulWidget {
  final String role;
  const SignupScreen({super.key, required this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _loading = false;

  bool get isFarmer => widget.role == 'farmer';
  Color get roleColor => isFarmer ? AppColors.primary : AppColors.secondary;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await _authService.signUpWithEmail(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        name: _nameCtrl.text,
        role: widget.role,
        phone: _phoneCtrl.text,
      );
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/login/${widget.role}'),
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
                  'Create Account',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.3, end: 0),
                const SizedBox(height: 6),
                Text(
                  isFarmer
                      ? 'Join FarmLink and start selling your crops today.'
                      : 'Join FarmLink and buy fresh produce directly from farmers.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate(delay: 150.ms).fadeIn(),
                const SizedBox(height: 32),
                FLTextField(
                  label: 'Full Name',
                  controller: _nameCtrl,
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  color: roleColor, // Dynamic color (Green/Blue)
                  validator: (v) =>
                      v == null || v.trim().length < 2 ? 'Enter your full name' : null,
                ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.2, end: 0),
                const SizedBox(height: 14),
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
                ).animate(delay: 250.ms).fadeIn().slideX(begin: -0.2, end: 0),
                const SizedBox(height: 14),
                FLTextField(
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  color: roleColor, // Dynamic color (Green/Blue)
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Enter phone number';
                    }

                    // Egyptian Mobile Regex:
                    // Starts with 01 followed by 0, 1, 2, or 5, then 8 more digits.
                    final egyptRegex = RegExp(r'^01[0125]\d{8}$');

                    if (!egyptRegex.hasMatch(v)) {
                      return 'Enter a valid Egyptian phone number (e.g., 010...)';
                    }
                    return null;
                  },
                ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.2, end: 0),
                const SizedBox(height: 14),
                FLTextField(
                  label: 'Password',
                  controller: _passwordCtrl,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  color: roleColor, // Dynamic color (Green/Blue)
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ).animate(delay: 350.ms).fadeIn().slideX(begin: -0.2, end: 0),
                const SizedBox(height: 14),
                FLTextField(
                  label: 'Confirm Password',
                  controller: _confirmCtrl,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  color: roleColor, // Dynamic color (Green/Blue)
                  validator: (v) {
                    if (v != _passwordCtrl.text) return "Passwords don't match";
                    return null;
                  },
                ).animate(delay: 400.ms).fadeIn().slideX(begin: -0.2, end: 0),
                const SizedBox(height: 28),
                FLButton(
                  label: 'Create Account',
                  onPressed: _signUp,
                  isLoading: _loading,
                  color: roleColor,
                ).animate(delay: 450.ms).fadeIn().slideY(begin: 0.3, end: 0),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login/${widget.role}'),
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 500.ms).fadeIn(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

