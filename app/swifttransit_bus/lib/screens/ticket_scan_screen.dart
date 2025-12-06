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
  String? _statusMessage;
  bool? _isValid;

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
      _statusMessage = 'Checking ticket...';
      _isValid = null;
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
        _isValid = result.isValid;
        _statusMessage = result.message;
      });
    } catch (e) {
      setState(() {
        _isValid = false;
        _statusMessage = 'Error: $e';
      });
    } finally {
      // Auto-reset after delay if valid, or keep error visible longer
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _processing = false;
          _statusMessage = null;
          _isValid = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Ticket')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Text(
                  'Camera error: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            },
          ),
          // Overlay for scanning area
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: const Color(0xFF258BA1),
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          // Status Overlay
          if (_processing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isValid == null)
                        const CircularProgressIndicator(
                          color: Color(0xFF258BA1),
                        )
                      else if (_isValid == true)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 64,
                        )
                      else
                        const Icon(Icons.cancel, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage ?? 'Processing...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isValid == null
                              ? Colors.black87
                              : (_isValid == true ? Colors.green : Colors.red),
                        ),
                      ),
                      if (_isValid != null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _processing = false;
                              _statusMessage = null;
                              _isValid = null;
                            });
                          },
                          child: const Text('Scan Next'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          // Bottom Info Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Current Stop: ${widget.currentStop.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Align QR code within the frame',
                    style: TextStyle(color: Colors.grey[600]),
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

// Helper class for overlay shape (simplified version of what libraries usually provide)
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _cutOutSize = cutOutSize;
    final _borderLength = borderLength;
    final _borderRadius = borderRadius;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - _cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - _cutOutSize / 2 + borderOffset,
      _cutOutSize - borderOffset * 2,
      _cutOutSize - borderOffset * 2,
    );

    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(_borderRadius)),
        Paint()..blendMode = BlendMode.clear,
      )
      ..restore();

    final borderPath = Path()
      ..moveTo(cutOutRect.left, cutOutRect.top + _borderLength)
      ..lineTo(cutOutRect.left, cutOutRect.top + _borderRadius)
      ..arcToPoint(
        Offset(cutOutRect.left + _borderRadius, cutOutRect.top),
        radius: Radius.circular(_borderRadius),
      )
      ..lineTo(cutOutRect.left + _borderLength, cutOutRect.top)
      ..moveTo(cutOutRect.right - _borderLength, cutOutRect.top)
      ..lineTo(cutOutRect.right - _borderRadius, cutOutRect.top)
      ..arcToPoint(
        Offset(cutOutRect.right, cutOutRect.top + _borderRadius),
        radius: Radius.circular(_borderRadius),
      )
      ..lineTo(cutOutRect.right, cutOutRect.top + _borderLength)
      ..moveTo(cutOutRect.right, cutOutRect.bottom - _borderLength)
      ..lineTo(cutOutRect.right, cutOutRect.bottom - _borderRadius)
      ..arcToPoint(
        Offset(cutOutRect.right - _borderRadius, cutOutRect.bottom),
        radius: Radius.circular(_borderRadius),
      )
      ..lineTo(cutOutRect.right - _borderLength, cutOutRect.bottom)
      ..moveTo(cutOutRect.left + _borderLength, cutOutRect.bottom)
      ..lineTo(cutOutRect.left + _borderRadius, cutOutRect.bottom)
      ..arcToPoint(
        Offset(cutOutRect.left, cutOutRect.bottom - _borderRadius),
        radius: Radius.circular(_borderRadius),
      )
      ..lineTo(cutOutRect.left, cutOutRect.bottom - _borderLength);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
    );
  }
}
