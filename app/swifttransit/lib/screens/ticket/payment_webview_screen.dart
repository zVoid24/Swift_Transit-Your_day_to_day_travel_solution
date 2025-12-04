import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    this.onSuccess,
    this.onFailure,
  });

  final String paymentUrl;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _resultStatus; // 'success' or 'failure'

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
                _showResult(success: true);
                return NavigationDecision.prevent;
              }
              if (uri.path.contains('fail') || uri.path.contains('cancel')) {
                _showResult(success: false);
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _showResult({required bool success}) {
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

  void _closeResult() {
    Navigator.of(context).pop(_resultStatus == 'success');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
            ),
          if (_resultStatus != null)
            Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _resultStatus == 'success'
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: _resultStatus == 'success'
                        ? Colors.green
                        : Colors.red,
                    size: 96,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _resultStatus == 'success'
                        ? 'Payment successful'
                        : 'Payment failed or cancelled',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _closeResult,
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
