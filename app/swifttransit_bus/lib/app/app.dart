import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swifttransit_bus/app/routes/app_routes.dart';
import 'package:swifttransit_bus/core/theme/app_colors.dart';
import 'package:swifttransit_bus/features/auth/application/session_provider.dart';
import 'package:swifttransit_bus/features/auth/presentation/screens/login_screen.dart';
import 'package:swifttransit_bus/features/home/presentation/screens/home_screen.dart';

class SwiftTransitBusApp extends StatefulWidget {
  const SwiftTransitBusApp({super.key});

  @override
  State<SwiftTransitBusApp> createState() => _SwiftTransitBusAppState();
}

class _SwiftTransitBusAppState extends State<SwiftTransitBusApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SwiftTransit Bus',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
      ),
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
      },
      home: Consumer<SessionProvider>(
        builder: (context, sessionProvider, _) {
          if (sessionProvider.isRestoring) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (sessionProvider.session != null && sessionProvider.route != null) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
