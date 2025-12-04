import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../providers/auth_provider.dart';
import '../../../core/colors.dart';
// import path below — adjust if your file is in a different folder
import '../../../widgets/app_snackbar.dart'; // <- change path to where app_snacbar.dart actually is
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isRememberMe = false;
  bool _isPasswordVisible = false;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lottie.asset(
              //   'assets/login.json',
              //   width: 300,
              //   height: 240,
              //   repeat: true,
              //   fit: BoxFit.contain,
              // ),
              const SizedBox(height: 14),

              Text(
                "Welcome Back!",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 10),

              Text(
                "Login to Swift Transit",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 50),

              buildInputField(
                controller: phoneController,
                hint: "Enter mobile number",
                icon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCall,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
                isPassword: false,
              ),

              const SizedBox(height: 16),

              buildInputField(
                controller: passwordController,
                hint: "Enter password",
                icon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedLockPassword,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
                isPassword: true,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Checkbox(
                    value: isRememberMe,
                    onChanged: (val) {
                      setState(() => isRememberMe = val ?? false);
                    },
                    activeColor: AppColors.primary,
                    side: const BorderSide(color: Colors.black54),
                  ),
                  Text("Remember Me", style: GoogleFonts.poppins(fontSize: 14)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Forgot Password?",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            // validation
                            if (phoneController.text.isEmpty ||
                                passwordController.text.isEmpty) {
                              AppSnackBar.warning(
                                context,
                                "Please fill all fields",
                              );
                              return;
                            }

                            final success = await auth.login(
                              phoneController.text.trim(),
                              passwordController.text,
                            );

                            if (success) {
                              if (!context.mounted) return;
                              AppSnackBar.success(context, "Login successful");
                              Navigator.pushReplacementNamed(
                                context,
                                '/dashboard',
                              );
                            } else {
                              if (!context.mounted) return;
                              AppSnackBar.error(context, "Invalid credentials");
                            }
                          },
                    child: auth.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Log In",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don’t have an account? ",
                    style: GoogleFonts.poppins(color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                    child: Text(
                      "Register",
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String hint,
    required Widget icon,
    required bool isPassword,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !_isPasswordVisible : false,
        style: GoogleFonts.poppins(),
        decoration: InputDecoration(
          prefixIcon: icon,
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Feather.eye : Feather.eye_off,
                    size: 22,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                  },
                )
              : null,
        ),
      ),
    );
  }
}
