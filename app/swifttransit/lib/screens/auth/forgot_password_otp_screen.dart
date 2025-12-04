import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  final String email;
  const ForgotPasswordOtpScreen({super.key, required this.email});

  @override
  State<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _timer;
  int _start = 59;
  bool _canResend = false;
  bool _otpVerified = false;
  String? _resetToken;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _start = 59;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _timer?.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  Future<void> _onResend() async {
    if (!_canResend) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final sent = await auth.initiateForgotPassword(widget.email);
    if (!mounted) return;

    if (sent) {
      AppSnackBar.success(context, 'OTP resent');
      _startTimer();
    } else {
      AppSnackBar.error(context, 'Could not resend OTP');
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      AppSnackBar.error(context, 'Please enter the 6-digit OTP');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = await auth.verifyForgotOtp(widget.email, _otpController.text);
    if (!mounted) return;

    if (token != null) {
      setState(() {
        _otpVerified = true;
        _resetToken = token;
      });
      AppSnackBar.success(context, 'OTP verified');
    } else {
      AppSnackBar.error(context, 'Invalid or expired OTP');
    }
  }

  Future<void> _resetPassword() async {
    final newPassword = _passwordController.text;
    final confirm = _confirmController.text;

    if (!_otpVerified || _resetToken == null) {
      AppSnackBar.warning(context, 'Please verify the OTP first');
      return;
    }
    if (newPassword.length < 6) {
      AppSnackBar.warning(context, 'Password should be at least 6 characters');
      return;
    }
    if (newPassword != confirm) {
      AppSnackBar.error(context, 'Passwords do not match');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.resetPasswordWithToken(_resetToken!, newPassword);
    if (!mounted) return;

    if (success) {
      AppSnackBar.success(context, 'Password updated successfully');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      AppSnackBar.error(context, 'Unable to update password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Reset password',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  children: [
                    const TextSpan(
                      text: 'Enter the verification code sent to\n',
                    ),
                    TextSpan(
                      text: widget.email,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Change email',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Stack(
                  children: [
                    Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _otpController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _focusNode.requestFocus(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          final code = _otpController.text;
                          final char = index < code.length ? code[index] : '';
                          final isFocused = index == code.length;

                          return Container(
                            width: 45,
                            height: 55,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isFocused
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                                width: isFocused ? 2 : 1,
                              ),
                              boxShadow: [
                                if (isFocused)
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                char,
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _canResend ? 'Code expired' : 'Resend in $_start s',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: _canResend ? _onResend : null,
                    child: Text(
                      'Resend Code',
                      style: GoogleFonts.poppins(
                        color: _canResend ? AppColors.primary : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_otpVerified) ...[
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'New password',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirm new password',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (!_otpVerified)
                Consumer<AuthProvider>(
                  builder: (context, ap, _) => PrimaryButton(
                    text: ap.isForgotLoading ? 'Verifying...' : 'Verify OTP',
                    onTap: ap.isForgotLoading ? null : _verifyOtp,
                  ),
                )
              else
                Consumer<AuthProvider>(
                  builder: (context, ap, _) => PrimaryButton(
                    text:
                        ap.isResettingPassword ? 'Updating...' : 'Update Password',
                    onTap: ap.isResettingPassword ? null : _resetPassword,
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
