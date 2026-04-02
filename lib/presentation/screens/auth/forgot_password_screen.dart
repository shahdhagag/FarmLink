import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:farmlink/core/theme/app_theme.dart';

import '../../../data/services/auth_services.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/fl_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String role;
  const ForgotPasswordScreen({super.key, required this.role});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _loading = false;

  bool get isFarmer => widget.role == 'farmer';
  Color get roleColor => isFarmer ? AppColors.primary : AppColors.secondary;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _authService.sendPasswordResetEmail(_emailCtrl.text.trim());

      if (!mounted) return;

      // Show success state or dialog
      _showSuccessDialog();
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Check Your Email',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'We sent a password reset link to ${_emailCtrl.text}. Please check your inbox.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                context.pop(); // Go back to login
              },
              child: Text('Back to Login', style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: roleColor,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Icon Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    color: roleColor,
                    size: 36,
                  ),
                ).animate().scale(duration: 400.ms).rotate(begin: -0.1, end: 0),

                const SizedBox(height: 24),

                Text(
                  'Forgot Password?',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),

                const SizedBox(height: 8),

                Text(
                  "No worries! Enter the email address associated with your account and we'll send you a reset link.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 40),

                FLTextField(
                  label: 'Email Address',
                  controller: _emailCtrl,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  color: roleColor, // Dynamic color (Green/Blue)
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 32),

                FLButton(
                  label: 'Send Reset Link',
                  onPressed: _resetPassword,
                  isLoading: _loading,
                  color: roleColor,
                ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),

                const Spacer(),

                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Remember password? Login',
                      style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}