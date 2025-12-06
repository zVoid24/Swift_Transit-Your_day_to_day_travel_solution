import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swifttransit/core/constants.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isForgotLoading = false;
  bool isResettingPassword = false;
  bool isChangingPassword = false;

  final fullName = TextEditingController();
  final email = TextEditingController();
  final nid = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();

  // NEW: separate controller for confirm password
  final confirmPassword = TextEditingController();

  bool agreed = false;

  void toggleAgreement(bool? value) {
    agreed = value ?? false;
    notifyListeners();
  }

  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  Future<bool> initiateForgotPassword(String email) async {
    isForgotLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      isForgotLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      isForgotLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> verifyForgotOtp(String email, String otp) async {
    isForgotLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      isForgotLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['reset_token']?.toString();
      }
      return null;
    } catch (e) {
      isForgotLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> resetPasswordWithToken(String token, String newPassword) async {
    isResettingPassword = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'new_password': newPassword}),
      );

      isResettingPassword = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      isResettingPassword = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String mobile, String password) async {
    isLoading = true;
    notifyListeners();
    print("Login attempt for mobile $mobile");

    try {
      print(AppConstants.baseUrl);
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt', data['jwt']);
        await prefs.setString('user', jsonEncode(data['user']));
        _user = data['user'];

        isLoading = false;
        notifyListeners();
        return true;
      } else {
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    final userData = prefs.getString('user');

    if (jwt != null && userData != null) {
      _user = jsonDecode(userData);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> refreshProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    if (jwt == null) return false;

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _user = data;
      await prefs.setString('user', jsonEncode(data));
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String mobile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    if (jwt == null) return false;

    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({'name': name, 'email': email, 'mobile': mobile}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _user = data;
      await prefs.setString('user', jsonEncode(data));
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    isChangingPassword = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt');
      if (jwt == null) {
        isChangingPassword = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      isChangingPassword = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (_) {
      isChangingPassword = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _user = null;
    notifyListeners();
  }

  Future<bool> initiateSignup() async {
    isLoading = true;
    notifyListeners();

    // Basic guard: passwords must match before hitting API
    if (password.text.trim() != confirmPassword.text.trim()) {
      isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': fullName.text.trim(),
          'mobile': phone.text.trim(),
          'nid': nid.text.trim(),
          'email': email.text.trim(),
          'password': password.text,
          'is_student': false, // Default for now
          'balance': 200.0, // Default balance
        }),
      );

      if (response.statusCode == 200) {
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifySignup(String email, String otp) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/user/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOtp() async {
    // Re-use initiateSignup to resend OTP as it sends the same data
    return await initiateSignup();
  }

  void clearSignupFields() {
    fullName.clear();
    email.clear();
    nid.clear();
    phone.clear();
    password.clear();
    confirmPassword.clear();
    agreed = false;
    notifyListeners();
  }

  bool isSignupValid() {
    return fullName.text.trim().isNotEmpty &&
        email.text.trim().isNotEmpty &&
        nid.text.trim().isNotEmpty &&
        phone.text.trim().isNotEmpty &&
        password.text.length >= 6 &&
        confirmPassword.text.length >= 6 &&
        password.text == confirmPassword.text &&
        agreed == true;
  }

  Future<Map<String, dynamic>?> getRFIDStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    if (jwt == null) return null;

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/user/rfid'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> toggleRFIDStatus(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    if (jwt == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/user/rfid/toggle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'active': active}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    fullName.dispose();
    email.dispose();
    nid.dispose();
    phone.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }
}
