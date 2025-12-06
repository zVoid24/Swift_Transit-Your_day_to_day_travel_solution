import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/forgot_password_otp_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/ticket/presentation/screens/buy_ticket_screen.dart';
import '../../features/ticket/presentation/screens/live_bus_location_screen.dart';
import '../../features/ticket/presentation/screens/payment_webview_screen.dart';
import '../../features/ticket/presentation/screens/ticket_detail_screen.dart';
import '../../features/ticket/presentation/screens/ticket_list_screen.dart';
import '../../features/transaction/presentation/screens/transaction_screen.dart';

class AppRoutes {
  static const root = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const dashboard = '/dashboard';
  static const search = '/search';
  static const profile = '/profile';
  static const transactions = '/transactions';
  static const tickets = '/tickets';
  static const buyTicket = '/buy-ticket';
  static const ticketDetail = '/ticket-detail';
  static const liveBus = '/live-bus';
  static const payment = '/payment';
  static const forgotPassword = '/forgot-password';
  static const forgotPasswordOtp = '/forgot-password-otp';
  static const resetPassword = '/reset-password';
  static const otpVerification = '/otp-verification';

  static Map<String, WidgetBuilder> get routes => {
    root: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    signup: (_) => const SignupScreen(),
    dashboard: (_) => const DashboardScreen(),
    search: (_) => const SearchScreen(),
    profile: (_) => const DemoProfileScreen(),
    transactions: (_) => const TransactionScreen(),
    tickets: (_) => const TicketListScreen(),
    buyTicket: (_) => const BuyTicketScreen(),
    ticketDetail: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
          {};
      return TicketDetailScreen(
        tickets:
            (args['tickets'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [],
        initialIndex: args['initialIndex'] as int? ?? 0,
      );
    },
    liveBus: (_) => const LiveBusLocationScreen(routeId: 0, title: ''),
    payment: (_) => const PaymentWebViewScreen(paymentUrl: ''),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    forgotPasswordOtp: (context) => ForgotPasswordOtpScreen(
      email: ModalRoute.of(context)?.settings.arguments as String? ?? '',
    ),
    otpVerification: (context) => OtpVerificationScreen(
      email: ModalRoute.of(context)?.settings.arguments as String? ?? '',
    ),
  };
}
