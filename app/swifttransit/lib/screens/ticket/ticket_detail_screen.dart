import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/constants.dart';
import '../../core/colors.dart';

class TicketDetailScreen extends StatelessWidget {
  final Map<String, dynamic> ticket;

  const TicketDetailScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ticketId = ticket['id'];
    final busName = ticket['bus_name'] ?? 'Swift Bus';
    final route =
        '${ticket['start_destination']} → ${ticket['end_destination']}';
    final fare = ticket['fare'];
    final date = ticket['created_at'];
    final qrData =
        ticket['qr_code'] ??
        'TICKET-$ticketId'; // Use actual QR code or fallback
    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=$qrData';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ticket Details',
          style: GoogleFonts.poppins(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Ticket Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                busName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Ticket #$ticketId',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _infoRow('Route', route),
                        const Divider(height: 30),
                        _infoRow('Date', date ?? 'N/A'),
                        const Divider(height: 30),
                        _infoRow('Fare', '৳$fare'),
                        const Divider(height: 30),

                        // QR Code
                        const SizedBox(height: 10),
                        Text(
                          'Scan to Verify',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Image.network(
                          qrUrl,
                          width: 150,
                          height: 150,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 150,
                              height: 150,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(
                              width: 150,
                              height: 150,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Download Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final downloadUrl =
                      '${AppConstants.baseUrl}/ticket/download?id=$ticketId';
                  final success = await Provider.of<DashboardProvider>(
                    context,
                    listen: false,
                  ).downloadTicket(downloadUrl);

                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open download link.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  'Download PDF',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
