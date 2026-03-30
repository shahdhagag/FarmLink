import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/farmLink_textField.dart';

class FarmerSignup extends StatefulWidget {
  const FarmerSignup({super.key});

  @override
  State<FarmerSignup> createState() => _FarmerSignupState();
}

class _FarmerSignupState extends State<FarmerSignup> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (cred.user != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(cred.user!.uid)
            .set({
          "email": _emailController.text.trim(),
          "role": "farmer",
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Registered successfully! Please log in."),
            backgroundColor: const Color(0xFF337233),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Registration failed'),
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
                  "Create Account",
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
                  "Join FarmMate and start selling your crops today.",
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
                    if (v == null || v.isEmpty) return "Enter a password";
                    if (v.length < 6) return "Minimum 6 characters";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FarmMateTextField(
                  label: "Confirm Password",
                  controller: _confirmPasswordController,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  validator: (v) {
                    if (v != _passwordController.text) return "Passwords don't match";
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                FarmMateButton(
                  label: "Create Account",
                  onPressed: _signUp,
                  isLoading: _isLoading,
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