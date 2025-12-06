import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:swifttransit_bus/main.dart';
import 'package:swifttransit_bus/models/route_models.dart';
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
  final RouteStop currentStop;

  @override
  State<TicketScanScreen> createState() => _TicketScanScreenState();
}

class _TicketScanScreenState extends State<TicketScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  String? _status;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _handleScan(barcode.rawValue!);
        break;
      }
    }
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
        currentStop: widget.currentStop.name,
        currentStopOrder: widget.currentStop.order,
      );
      setState(() {
        _status = result.isValid
            ? 'Valid ticket: ${result.message}'
            : 'Invalid: ${result.message}';
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
      appBar: AppBar(title: const Text('Scan ticket')),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(controller: _controller, onDetect: _onDetect),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Current stop: ${widget.currentStop.name}'),
                  const SizedBox(height: 8),
                  if (_status != null) Text(_status!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _processing ? null : () => _controller.start(),
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
