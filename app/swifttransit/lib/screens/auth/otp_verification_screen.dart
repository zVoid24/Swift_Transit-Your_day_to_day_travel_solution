import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:swifttransit/core/colors.dart';
import 'package:swifttransit/widgets/app_snackbar.dart';
import 'package:swifttransit/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _timer;
  int _start = 59;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    // Auto-focus the input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void startTimer() {
    setState(() {
      _start = 59;
      _canResend = false;
    });
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

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onResend() async {
    if (!_canResend) return;

    // Call resend API (which is just initiate signup again essentially, or a specific resend endpoint)
    // For now, we can reuse initiateSignup logic or just assume it works if we had a resend endpoint.
    // Since the backend uses InitiateSignup to send OTP, we can call that.
    // But InitiateSignup requires all user data.
    // Ideally, we should have a 'resend-otp' endpoint.
    // Given the current backend, we might not be able to easily resend without the full payload.
    // I'll check if I can just call initiateSignup again with the data from AuthProvider.

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.resendOtp(); // We will implement this
    if (success) {
      AppSnackBar.success(context, "OTP resent successfully");
      startTimer();
    } else {
      AppSnackBar.error(context, "Failed to resend OTP");
    }
  }

  void _onVerify() async {
    final otp = _otpController.text;
    if (otp.length != 6) {
      AppSnackBar.error(context, "Please enter a valid 6-digit code");
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.verifySignup(widget.email, otp);

    if (success) {
      if (!mounted) return;
      AppSnackBar.success(context, "Account verified successfully!");

      // Clear fields and navigate to Login
      auth.clearSignupFields();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      AppSnackBar.error(context, "Invalid OTP. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
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
                "Verify your email",
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
                      text: "Enter the verification code sent to\n",
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
                  "Change email",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // OTP Input Area
              Center(
                child: Stack(
                  children: [
                    // Hidden TextField
                    Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _otpController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        onChanged: (val) {
                          setState(() {});
                          if (val.length == 6) {
                            // Optional: Auto-submit
                            // _onVerify();
                          }
                        },
                      ),
                    ),
                    // Visible Boxes
                    GestureDetector(
                      onTap: () {
                        if (_focusNode.hasFocus) {
                          _focusNode.unfocus();
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _focusNode.requestFocus();
                          });
                        } else {
                          _focusNode.requestFocus();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          final code = _otpController.text;
                          final char = index < code.length ? code[index] : "";
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
                    _canResend ? "Code expired" : "Resend in $_start s",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: _canResend ? _onResend : null,
                    child: Text(
                      "Resend Code",
                      style: GoogleFonts.poppins(
                        color: _canResend ? AppColors.primary : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              Consumer<AuthProvider>(
                builder: (context, ap, _) => PrimaryButton(
                  text: ap.isLoading ? "Verifying..." : "Verify",
                  onTap: _onVerify,
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
