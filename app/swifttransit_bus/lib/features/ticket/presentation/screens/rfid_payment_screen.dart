import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swifttransit_bus/features/auth/application/session_provider.dart';

class RFIDPaymentScreen extends StatefulWidget {
  const RFIDPaymentScreen({super.key});

  @override
  State<RFIDPaymentScreen> createState() => _RFIDPaymentScreenState();
}

class _RFIDPaymentScreenState extends State<RFIDPaymentScreen> {
  final _rfidController = TextEditingController();
  final _focusNode = FocusNode();
  String? _startDestination;
  String? _endDestination;
  bool _processing = false;
  String? _statusMessage;
  bool? _success;
  double? _fare;
  double? _balance;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    // Auto-focus the RFID input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _rfidController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _processPayment(String rfid) async {
    if (rfid.isEmpty) return;
    if (_processing) return; // Prevent double submission

    // Cooldown check
    if (_lastScanTime != null &&
        DateTime.now().difference(_lastScanTime!) <
            const Duration(seconds: 2)) {
      return; // Ignore scans within 2 seconds
    }

    if (_startDestination == null || _endDestination == null) {
      setState(() {
        _statusMessage = 'Please select start and end destinations';
        _success = false;
      });
      _rfidController.clear();
      _focusNode.requestFocus();
      return;
    }

    setState(() {
      _processing = true;
      _statusMessage = 'Processing payment...';
      _success = null;
    });

    try {
      final sessionProvider = context.read<SessionProvider>();
      final session = sessionProvider.session;
      final route = sessionProvider.route;

      if (session == null || route == null) {
        throw Exception('Session or route not found');
      }

      final result = await sessionProvider.apiService.processRFIDPayment(
        rfid: rfid,
        routeId: session.routeId,
        busName: route.name, // Use route name as requested
        startDestination: _startDestination!,
        endDestination: _endDestination!,
      );

      setState(() {
        _success = result.success;
        _statusMessage = result.message;

        // Handle Duplicate specifically
        if (result.status == 'DUPLICATE') {
          _success = null; // Neutral/Warning state
          _statusMessage = '⚠️ ${result.message}';
        }

        if (result.success || result.status == 'DUPLICATE') {
          _fare = result.fare;
          _balance = result.balance;
          _lastScanTime = DateTime.now();
        }
      });
    } catch (e) {
      setState(() {
        _success = false;
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _processing = false;
      });
      _rfidController.clear();
      _focusNode.requestFocus();

      if (_success == true || _statusMessage?.contains('⚠️') == true) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _statusMessage = null;
              _success = null;
              _fare = null;
              _balance = null;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final stops = sessionProvider.route?.stops ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('RFID Payment'),
        backgroundColor: const Color(0xFF258BA1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF258BA1),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _startDestination,
                      decoration: InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          Icons.trip_origin,
                          color: Color(0xFF258BA1),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: stops.map((stop) {
                        return DropdownMenuItem(
                          value: stop.name,
                          child: Text(stop.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _startDestination = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _endDestination,
                      decoration: InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: stops.map((stop) {
                        return DropdownMenuItem(
                          value: stop.name,
                          child: Text(stop.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _endDestination = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // RFID Input
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.nfc, size: 48, color: Color(0xFF258BA1)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _rfidController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        labelText: 'Scan RFID Card',
                        hintText: 'Waiting for scan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.credit_card),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onSubmitted: _processPayment,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status Display
            if (_processing)
              const Center(child: CircularProgressIndicator())
            else if (_statusMessage != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _success == true
                      ? Colors.green[50]
                      : (_success == false ? Colors.red[50] : Colors.grey[50]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _success == true
                        ? Colors.green
                        : (_success == false ? Colors.red : Colors.grey),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _success == true
                          ? Icons.check_circle
                          : (_success == false
                                ? Icons.error
                                : Icons.hourglass_empty),
                      size: 64,
                      color: _success == true
                          ? Colors.green
                          : (_success == false ? Colors.red : Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _success == true
                            ? Colors.green[800]
                            : (_success == false
                                  ? Colors.red[800]
                                  : Colors.grey[800]),
                      ),
                    ),
                    if (_success == true && _fare != null) ...[
                      const SizedBox(height: 16),
                      Divider(color: Colors.green[200]),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fare Paid:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green[900],
                            ),
                          ),
                          Text(
                            '৳${_fare!.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Balance:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green[900],
                            ),
                          ),
                          Text(
                            '৳${_balance!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.green[900],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
