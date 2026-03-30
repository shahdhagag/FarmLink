
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Home_pages/Farmers_HomeScreen/Farmers_Main_Home.dart';
import '../widgets/farmLink_textField.dart';
import 'Farmer_SignUp.dart';

class FarmerLogin extends StatefulWidget {
  const FarmerLogin({super.key});

  @override
  State<FarmerLogin> createState() => _FarmerLoginState();
}

class _FarmerLoginState extends State<FarmerLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const FarmersMainHome()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Login failed'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF337233)),
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

                // Header
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF337233).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.agriculture_rounded,
                      color: Color(0xFF337233), size: 36),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Farmer Login",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    fontFamily: 'Poppins-SemiBold',
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Welcome back! Sign in to manage your crops.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins-SemiBold',
                  ),
                ),
                const SizedBox(height: 36),

                FarmMateTextField(
                  label: "Email Address",
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Enter your email";
                    if (!v.contains('@')) return "Enter a valid email";
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                FarmMateTextField(
                  label: "Password",
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Enter your password";
                    if (v.length < 6) return "Password must be at least 6 characters";
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                FarmMateButton(
                  label: "Log In",
                  onPressed: _login,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontFamily: 'Poppins-SemiBold',
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const FarmerSignup())),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Color(0xFF337233),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins-SemiBold',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}