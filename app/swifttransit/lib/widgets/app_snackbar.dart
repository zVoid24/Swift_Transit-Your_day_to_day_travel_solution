import 'package:flutter/material.dart';

class AppSnackBar {
  static void success(BuildContext context, String message) {
    _show(
      context,
      message,
      Colors.green,
    );
  }

  static void error(BuildContext context, String message) {
    _show(
      context,
      message,
      Colors.red,
    );
  }

  static void warning(BuildContext context, String message) {
    _show(
      context,
      message,
      Colors.orange,
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context,
      message,
      Colors.blue,
    );
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
