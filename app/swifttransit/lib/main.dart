import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swifttransit/providers/dashboard_provider.dart';
import 'package:swifttransit/screens/dashboard/dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/signup_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const SwiftTransit(),
    ),
  );
}

class SwiftTransit extends StatelessWidget {
  const SwiftTransit({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}
