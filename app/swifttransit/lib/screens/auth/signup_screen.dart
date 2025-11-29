import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';

import 'package:swifttransit/core/colors.dart';
import 'package:swifttransit/widgets/app_snackbar.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              SizedBox(
                height: 120,
                child: Lottie.asset("assets/signup.json", fit: BoxFit.contain),
              ),

              const SizedBox(height: 20),

              Text(
                "Sign Up",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Join Swift Transit and travel smarter",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.black),
              ),

              const SizedBox(height: 40),

              AppInputField(
                controller: auth.fullName,
                icon: HugeIcons.strokeRoundedUserCircle,
                hint: "Full Name (As Per NID)",
              ),

              AppInputField(
                controller: auth.email,
                icon: HugeIcons.strokeRoundedMail01,
                hint: "Email Address",
                keyboardType: TextInputType.emailAddress,
              ),

              AppInputField(
                controller: auth.nid,
                icon: HugeIcons.strokeRoundedIdentification,
                hint: "NID Number",
                keyboardType: TextInputType.number,
              ),

              AppInputField(
                controller: auth.phone,
                icon: HugeIcons.strokeRoundedCall,
                hint: "Contact Number",
                keyboardType: TextInputType.phone,
                customPrefix: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network("https://flagcdn.com/w40/bd.png", width: 20),
                    const SizedBox(width: 6),
                  ],
                ),
              ),

              AppInputField(
                controller: auth.password,
                icon: HugeIcons.strokeRoundedLockPassword,
                hint: "Create Password",
                isPassword: true,
              ),
              AppInputField(
                controller: auth.password,
                icon: HugeIcons.strokeRoundedLockPassword,
                hint: "Confirm Password",
                isPassword: true,
              ),

              Row(
                children: [
                  Checkbox(
                    value: auth.agreed,
                    onChanged: auth.toggleAgreement,
                    side: const BorderSide(color: Colors.black),
                    checkColor: Colors.white,
                    activeColor: AppColors.primary,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          "I agree to the ",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "Terms & Conditions",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF258BA1),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        Text(
                          " of Swift Transit.",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              PrimaryButton(
                text: auth.isLoading ? "Loading..." : "Sign Up",
                onTap: () async {
                  if (!auth.isSignupValid()) {
                    AppSnackBar.error(
                      context,
                      "Please fill up all fields correctly.",
                    );
                    return;
                  }

                  await auth.signup();

                  if (!auth.isLoading) {
                    AppSnackBar.success(
                      context,
                      "Account created successfully!",
                    );
                  }
                },
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: GoogleFonts.poppins(color: Colors.black),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
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
    );
  }
}
