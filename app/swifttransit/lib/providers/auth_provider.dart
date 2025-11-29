import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoading = false;

  final fullName = TextEditingController();
  final email = TextEditingController();
  final nid = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();

  bool agreed = false;

  void toggleAgreement(bool? value) {
    agreed = value ?? false;
    notifyListeners();
  }

  Future<void> login(String phone, String password) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    isLoading = false;
    notifyListeners();
  }

  Future<void> signup() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    isLoading = false;
    notifyListeners();
  }

  bool isSignupValid() {
    return fullName.text.isNotEmpty &&
        email.text.isNotEmpty &&
        nid.text.isNotEmpty &&
        phone.text.isNotEmpty &&
        password.text.length >= 6 &&
        agreed == true;
  }
}
