import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../core/colors.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/input_field.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _nidFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    _nidFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width > 700 ? 520.0 : double.infinity;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  CircleAvatar(
                    radius: 46,
                    backgroundImage: const AssetImage('assets/stlogo.png'),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sign Up',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Join Swift Transit and travel smarter',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Form card
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 0,
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          AppInputField(
                            controller: auth.fullName,
                            icon: HugeIcons.strokeRoundedUserCircle,
                            hint: 'Full Name (As Per NID)',
                            focusNode: _nameFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Enter full name';
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),

                          AppInputField(
                            controller: auth.email,
                            icon: HugeIcons.strokeRoundedMail01,
                            hint: 'Email Address',
                            keyboardType: TextInputType.emailAddress,
                            focusNode: _emailFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _nidFocus.requestFocus(),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Enter email';
                              final regex = RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );
                              if (!regex.hasMatch(v.trim()))
                                return 'Enter valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),

                          AppInputField(
                            controller: auth.nid,
                            icon: HugeIcons.strokeRoundedIdentification,
                            hint: 'NID Number',
                            keyboardType: TextInputType.number,
                            focusNode: _nidFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Enter NID';
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),

                          AppInputField(
                            controller: auth.phone,
                            icon: HugeIcons.strokeRoundedCall,
                            hint: 'Contact Number',
                            keyboardType: TextInputType.phone,
                            focusNode: _phoneFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                _passwordFocus.requestFocus(),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Enter contact number';
                              if (v.trim().length < 8)
                                return 'Enter valid phone';
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),

                          AppInputField(
                            controller: auth.password,
                            icon: HugeIcons.strokeRoundedLockPassword,
                            hint: 'Create Password',
                            isPassword: true,
                            focusNode: _passwordFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                _confirmFocus.requestFocus(),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Enter password';
                              if (v.length < 6)
                                return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),

                          AppInputField(
                            controller: auth.confirmPassword,
                            icon: HugeIcons.strokeRoundedLockPassword,
                            hint: 'Confirm Password',
                            isPassword: true,
                            focusNode: _confirmFocus,
                            textInputAction: TextInputAction.done,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Confirm your password';
                              if (v != auth.password.text)
                                return 'Passwords do not match';
                              return null;
                            },
                          ),

                          // Agreement
                          Row(
                            children: [
                              Consumer<AuthProvider>(
                                builder: (context, ap, _) => Checkbox(
                                  value: ap.agreed,
                                  onChanged: (val) => ap.toggleAgreement(val),
                                  activeColor: AppColors.primary,
                                ),
                              ),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'I agree to the ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Terms & Conditions',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' of Swift Transit.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Consumer<AuthProvider>(
                    builder: (context, ap, _) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: ap.isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) {
                                  AppSnackBar.error(
                                    context,
                                    'Fix the highlighted errors.',
                                  );
                                  return;
                                }
                                if (!ap.agreed) {
                                  AppSnackBar.warning(
                                    context,
                                    'Please accept Terms & Conditions.',
                                  );
                                  return;
                                }

                                final ok = await ap.initiateSignup();
                                if (ok) {
                                  AppSnackBar.success(
                                    context,
                                    'OTP sent to your email!',
                                  );
                                  if (!context.mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OtpVerificationScreen(
                                        email: ap.email.text,
                                      ),
                                    ),
                                  );
                                } else {
                                  AppSnackBar.error(
                                    context,
                                    'Failed to initiate signup. Try again.',
                                  );
                                }
                              },
                        child: ap.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Sign Up',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: GoogleFonts.poppins(color: Colors.black87),
                      ),
                      GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    child: Text(
                      "Login",
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
