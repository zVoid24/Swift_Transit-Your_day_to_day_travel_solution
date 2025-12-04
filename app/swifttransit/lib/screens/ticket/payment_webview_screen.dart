import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    this.ticketId,
    this.onSuccess,
    this.onFailure,
  });

  final String paymentUrl;
  final int? ticketId;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _resultStatus; // 'success' or 'failure'
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null && uri.path.contains('/ticket')) {
              if (uri.path.contains('success')) {
                // Allow the page to load so user sees the backend HTML
                // We can still trigger the success callback in the background or after a delay
                Future.delayed(const Duration(seconds: 1), () {
                  widget.onSuccess?.call();
                });
                return NavigationDecision.navigate;
              }
              if (uri.path.contains('fail') || uri.path.contains('cancel')) {
                widget.onFailure?.call();
                return NavigationDecision.navigate;
              }
              if (uri.path.contains('download')) {
                launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));

    if (widget.ticketId != null) {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_resultStatus != null) {
        timer.cancel();
        return;
      }
      await _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt');
      if (jwt == null) return;

      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseUrl}/ticket/status?id=${widget.ticketId}',
        ),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];
        if (status == 'paid') {
          _showResult(success: true);
        } else if (status == 'failed') {
          _showResult(success: false);
        }
      }
    } catch (e) {
      debugPrint("Error polling payment status: $e");
    }
  }

  void _showResult({required bool success}) {
    if (_resultStatus != null) return; // Already shown

    _pollTimer?.cancel();
    setState(() {
      _isLoading = false;
      _resultStatus = success ? 'success' : 'failure';
    });

    if (success) {
      widget.onSuccess?.call();
    } else {
      widget.onFailure?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}
