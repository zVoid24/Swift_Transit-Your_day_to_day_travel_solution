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

  // Form & keyboard integration
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  // Autovalidation mode (can be set to AutovalidateMode.onUserInteraction)
  final AutovalidateMode autovalidateMode;

  // Enable/disable field
  final bool enabled;

  const AppInputField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    this.isPassword = false,
    this.customPrefix,
    this.keyboardType,
    this.focusNode,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.enabled = true,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  late bool _obscure;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Helper to build prefix widget (HugeIcon or custom prefix)
  Widget? _buildPrefix() {
    if (widget.customPrefix != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 12, right: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [widget.customPrefix!],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 20,
        height: 20,
        child: HugeIcon(
          icon: widget.icon,
          size: 20,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget? _buildSuffix() {
    if (!widget.isPassword) return null;
    return IconButton(
      splashRadius: 18,
      icon: Icon(
        _obscure ? Feather.eye : Feather.eye_off,
        size: 20,
        color: Colors.grey,
      ),
      onPressed: () => setState(() => _obscure = !_obscure),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Outer column so we can show error above
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Error text above the field (if present)
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              _errorText!,
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        Container(
          margin: const EdgeInsets.only(bottom: 0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _errorText != null ? Colors.red : Colors.transparent,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            focusNode: widget.focusNode,
            textInputAction: widget.textInputAction ?? TextInputAction.done,
            onFieldSubmitted: widget.onFieldSubmitted,
            keyboardType: widget.keyboardType ?? TextInputType.text,
            obscureText: widget.isPassword ? _obscure : false,
            autovalidateMode: widget.autovalidateMode,
            style: GoogleFonts.poppins(fontSize: 14),

            // IMPORTANT: validator returns the result for Form.validate()
            // and we capture the result to show above the field.
            validator: (value) {
              final result = widget.validator != null ? widget.validator!(value) : null;

              // update state safely after validation run
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                // Only update when changed to avoid unnecessary rebuilds
                if (_errorText != result) {
                  setState(() {
                    _errorText = result;
                  });
                }
              });

              // Return the result (so Form.validate() sees it)
              return result;
            },

            // Better UX: clear error only when field becomes valid while typing
            onChanged: (v) {
              if (_errorText == null) return;
              final r = widget.validator?.call(v);
              if (r == null && _errorText != null) {
                setState(() => _errorText = null);
              }
            },

            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.black45),
              filled: true,
              fillColor: Colors.grey.shade100,
              prefixIcon: _buildPrefix(),
              prefixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 40),
              suffixIcon: _buildSuffix(),
              suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),

              // Hide default bottom error text visually while keeping maxLines > 0
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              errorMaxLines: 1,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
