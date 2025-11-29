import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_fonts/google_fonts.dart';

class AppInputField extends StatefulWidget {
  final TextEditingController controller;
  final dynamic icon;
  final String hint;
  final bool isPassword;
  final Widget? customPrefix;
  final TextInputType? keyboardType;

  const AppInputField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    this.isPassword = false,
    this.customPrefix,
    this.keyboardType,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: widget.controller,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        obscureText: widget.isPassword ? _obscure : false,
        style: GoogleFonts.poppins(),
        decoration: InputDecoration(

          prefixIcon: widget.customPrefix != null
              ? SizedBox(
                  width: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.customPrefix!,
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: HugeIcon(
                    icon: widget.icon,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),

          prefixIconConstraints: const BoxConstraints(
            minWidth: 60,
            minHeight: 40,
          ),


          hintText: widget.hint,
          hintStyle: GoogleFonts.poppins(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),


          suffixIcon: widget.isPassword
              ? IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    _obscure ? Feather.eye : Feather.eye_off,
                    size: 22,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _obscure = !_obscure);
                  },
                )
              : null,
        ),
      ),
    );
  }
}
