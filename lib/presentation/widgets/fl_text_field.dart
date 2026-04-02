import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:farmlink/core/theme/app_theme.dart';

class FLTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final Color? color; // Added this to handle Farmer/Buyer colors

  const FLTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.textInputAction,
    this.focusNode,
    this.nextFocus,
    this.color,
  });

  @override
  State<FLTextField> createState() => _FLTextFieldState();
}

class _FLTextFieldState extends State<FLTextField> {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  void _handleSubmit() {
    if (widget.nextFocus != null) {
      FocusScope.of(context).requestFocus(widget.nextFocus);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default to primary green if no color is passed
    final activeColor = widget.color ?? AppColors.primary;

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      validator: widget.validator,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      textInputAction: widget.textInputAction ?? TextInputAction.done,
      onFieldSubmitted: (_) => _handleSubmit(),

      // Styling the text user types
      style: TextStyle(fontSize: 15.sp, color: AppColors.textPrimary, fontWeight: FontWeight.w500),

      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14.sp),
        hintText: widget.hint,

        // Background and Fill
        filled: true,
        fillColor: AppColors.surface,

        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20, color: AppColors.textTertiary)
            : null,

        suffixIcon: widget.obscureText
            ? IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: AppColors.textTertiary,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        )
            : widget.suffixIcon,

        // --- BORDERS ---

        // Idle Border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.textTertiary.withOpacity(0.1), width: 1),
        ),

        // THE BORDER YOU WANTED (Active/Typing)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: activeColor, width: 1.8),
        ),

        // Error Border
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),

        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      ),
    );
  }
}