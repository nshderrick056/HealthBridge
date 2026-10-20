import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
    this.autofillHints,
    this.isPassword = false,
  });
  final String label, hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText, isPassword;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        autocorrect: false,
        enableSuggestions: !isPassword,
        textInputAction: isPassword
            ? TextInputAction.done
            : TextInputAction.next,
        onFieldSubmitted: onSubmitted,
        autofillHints: autofillHints,
        validator: (value) =>
            value == null || (isPassword ? value.isEmpty : value.trim().isEmpty)
            ? 'Enter your ${isPassword ? 'password' : 'CHW ID or phone number'}'
            : null,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: suffixIcon,
        ),
      ),
    ],
  );
}
