import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:swifttransit_bus/main.dart';
import 'package:swifttransit_bus/services/api_service.dart';

class TicketScanScreen extends StatefulWidget {
  const TicketScanScreen({
    super.key,
    required this.apiService,
    required this.session,
    required this.currentStop,
  });

  final ApiService apiService;
  final SessionData session;
  final String currentStop;

  @override
  State<TicketScanScreen> createState() => _TicketScanScreenState();
}

class _TicketScanScreenState extends State<TicketScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  bool _processing = false;
  String? _status;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_processing) return;
      final code = scanData.code;
      if (code != null) {
        _handleScan(code);
      }
    });
  }

  Future<void> _handleScan(String data) async {
    setState(() {
      _processing = true;
      _status = 'Checking ticket...';
    });
    try {
      final result = await widget.apiService.checkTicket(
        qrData: data,
        token: widget.session.token,
        routeId: widget.session.routeId,
        currentStop: widget.currentStop,
      );
      setState(() {
        _status =
            result.isValid ? 'Valid ticket: ${result.message}' : 'Invalid: ${result.message}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan ticket'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Current stop: ${widget.currentStop}'),
                  const SizedBox(height: 8),
                  if (_status != null) Text(_status!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _processing ? null : () => _controller?.resumeCamera(),
                    child: const Text('Resume scanning'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
