import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'package:swifttransit_bus/data/services/api_service.dart';
import 'package:swifttransit_bus/features/auth/application/session_provider.dart';
import 'package:swifttransit_bus/features/routes/domain/models/route_models.dart';

class TicketScanScreen extends StatefulWidget {
  const TicketScanScreen({super.key, required this.currentStop});

  final RouteStop currentStop;

  @override
  State<TicketScanScreen> createState() => _TicketScanScreenState();
}

class _TicketScanScreenState extends State<TicketScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
    returnImage: false,
  );
  bool _processing = false;
  String? _statusMessage;
  bool? _isValid;
  String? _status;
  Map<String, dynamic>? _ticketData;

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
      _status = null;
      _ticketData = null;
    });
    try {
      final apiService = context.read<ApiService>();
      final session = context.read<SessionProvider>().session;

      if (session == null) {
        setState(() {
          _statusMessage = 'No active session found';
          _isValid = false;
          _status = 'ERROR';
        });
        return;
      }

      final result = await apiService.checkTicket(
        qrData: data,
        token: session.token,
        routeId: session.routeId,
        currentStop: widget.currentStop.name,
        currentStopOrder: widget.currentStop.order,
      );

      setState(() {
        _isValid = result.isValid;
        _status = result.status;
        _statusMessage = result.message;
        _ticketData = result.payload;
      });
    } catch (e) {
      setState(() {
        _isValid = false;
        _status = 'ERROR';
        _statusMessage = 'Error: $e';
      });
    } finally {
      // Don't auto-reset for over-travel, keep it visible
      if (_status != 'over_travel') {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() {
            _processing = false;
            _statusMessage = null;
            _isValid = null;
            _status = null;
            _ticketData = null;
          });
        }
      } else {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Future<void> _createOverTravelTicket(bool paymentCollected) async {
    if (_ticketData == null) return;

    setState(() {
      _processing = true;
      _statusMessage = 'Creating ticket...';
    });

    try {
      final apiService = context.read<ApiService>();
      final ticketIdRaw = _ticketData!['ticket']['id'];

      if (ticketIdRaw == null) {
        throw Exception('Ticket ID not found in response');
      }

      final ticketId = ticketIdRaw is int
          ? ticketIdRaw
          : (ticketIdRaw as num).toInt();

      await apiService.createOverTravelTicket(
        originalTicketId: ticketId,
        currentStop: widget.currentStop.name,
        paymentCollected: paymentCollected,
      );

      setState(() {
        _statusMessage = 'Ticket created successfully!';
        _isValid = true;
        _status = 'SUCCESS';
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _processing = false;
          _statusMessage = null;
          _isValid = null;
          _status = null;
          _ticketData = null;
        });
      }
    } catch (e) {
      setState(() {
        _processing = false;
        _statusMessage = 'Failed to create ticket: $e';
        _isValid = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Camera error: $error',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          ),

          // Custom Overlay
          Stack(
            children: [
              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    bottom: 16,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Scan Ticket',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Scanner Frame
              Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      // Corners
                      ...List.generate(4, (index) {
                        final isTop = index < 2;
                        final isLeft = index % 2 == 0;
                        return Positioned(
                          top: isTop ? -2 : null,
                          bottom: !isTop ? -2 : null,
                          left: isLeft ? -2 : null,
                          right: !isLeft ? -2 : null,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border(
                                top: isTop
                                    ? const BorderSide(
                                        color: Color(0xFF258BA1),
                                        width: 6,
                                      )
                                    : BorderSide.none,
                                bottom: !isTop
                                    ? const BorderSide(
                                        color: Color(0xFF258BA1),
                                        width: 6,
                                      )
                                    : BorderSide.none,
                                left: isLeft
                                    ? const BorderSide(
                                        color: Color(0xFF258BA1),
                                        width: 6,
                                      )
                                    : BorderSide.none,
                                right: !isLeft
                                    ? const BorderSide(
                                        color: Color(0xFF258BA1),
                                        width: 6,
                                      )
                                    : BorderSide.none,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: isTop && isLeft
                                    ? const Radius.circular(24)
                                    : Radius.zero,
                                topRight: isTop && !isLeft
                                    ? const Radius.circular(24)
                                    : Radius.zero,
                                bottomLeft: !isTop && isLeft
                                    ? const Radius.circular(24)
                                    : Radius.zero,
                                bottomRight: !isTop && !isLeft
                                    ? const Radius.circular(24)
                                    : Radius.zero,
                              ),
                            ),
                          ),
                        );
                      }),
                      // Scanning Line Animation (Optional - static for now)
                      Center(
                        child: Container(
                          height: 2,
                          color: const Color(0xFF258BA1).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Current Stop',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.currentStop.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Align the QR code within the frame',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Result Overlay
          if (_processing || _statusMessage != null)
            Container(
              color: Colors.black87,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isValid == null)
                        const SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            strokeWidth: 6,
                            color: Color(0xFF258BA1),
                          ),
                        )
                      else if (_status == 'over_travel')
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_rounded,
                            color: Colors.orange,
                            size: 64,
                          ),
                        )
                      else if (_isValid == true)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.green,
                            size: 64,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.red,
                            size: 64,
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        _isValid == null
                            ? 'Checking Ticket...'
                            : (_status == 'valid'
                                  ? 'Valid Ticket'
                                  : (_status == 'already_used'
                                        ? 'Already Used'
                                        : (_status == 'invalid_route'
                                              ? 'Wrong Route'
                                              : (_status == 'over_travel'
                                                    ? 'Over-Travel Detected'
                                                    : 'Invalid Ticket')))),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _isValid == null
                              ? Colors.black87
                              : (_status == 'over_travel'
                                    ? Colors.orange[700]
                                    : (_isValid == true
                                          ? Colors.green[700]
                                          : Colors.red[700])),
                        ),
                      ),
                      if (_statusMessage != null && _isValid != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _statusMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      if (_status == 'over_travel' && _ticketData != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Extra Fare: ৳${(_ticketData!['extra_fare'] as num?)?.toStringAsFixed(0) ?? '0'}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _createOverTravelTicket(false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Not Paid',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _createOverTravelTicket(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cash Paid',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (_isValid != null) ...[
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _processing = false;
                                _statusMessage = null;
                                _isValid = null;
                                _status = null;
                                _ticketData = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF258BA1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Scan Next',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
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
