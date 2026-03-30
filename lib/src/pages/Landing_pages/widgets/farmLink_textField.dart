import 'package:flutter/material.dart';

class FarmMateTextField extends StatefulWidget {
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

  const FarmMateTextField({
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
  });

  @override
  State<FarmMateTextField> createState() => _FarmMateTextFieldState();
}

class _FarmMateTextFieldState extends State<FarmMateTextField> {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      validator: widget.validator,
      style: const TextStyle(
        fontFamily: 'Poppins-SemiBold',
        fontSize: 14,
        color: Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        labelStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontFamily: 'Poppins-SemiBold',
          fontSize: 13,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFD1D5DB),
          fontFamily: 'Poppins-SemiBold',
          fontSize: 13,
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: const Color(0xFF337233), size: 20)
            : null,
        suffixIcon: widget.obscureText
            ? IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF6B7280),
            size: 20,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        )
            : widget.suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF337233), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
      ),
    );
  }
}

class FarmMateButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final double height;

  const FarmMateButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? const Color(0xFF337233);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          disabledBackgroundColor: bg.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          shadowColor: bg.withOpacity(0.4),
        ),
        child: isLoading
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins-SemiBold',
          ),
        ),
      ),
    );
  }
}