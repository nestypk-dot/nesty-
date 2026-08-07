import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/nesty_image.dart';
import '../../home/domain/property.dart';

class BookingReceiptScreen extends StatelessWidget {
  final Property property;
  final DateTime startDate;
  final DateTime endDate;
  final int totalGuests;
  final int totalCost;

  const BookingReceiptScreen({
    super.key,
    required this.property,
    required this.startDate,
    required this.endDate,
    required this.totalGuests,
    required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "en_US");
    final dateFormat = DateFormat('MMM d, yyyy');
    final nightCount = endDate.difference(startDate).inDays;
    
    // Accurate calculations matching the booking flow
    final basePrice = property.price * nightCount;
    const cleaningFee = 1500;
    final serviceFee = (basePrice * 0.10).round();
    final taxes = (basePrice * 0.16).round();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 24, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Receipt',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(
                'https://nestypk.base44.app/assets/images/logo.png',
                height: 40,
                errorBuilder: (_, __, ___) => Text(
                  'Nesty',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your Receipt',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Receipt ID: NS-${DateFormat('yyyyMMdd').format(DateTime.now())}-8291',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w700,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 1. Property Brief
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: NestyImage(
                      src: property.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          property.location,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 2. Reservation Info
            _buildSectionTitle('Reservation details'),
            const SizedBox(height: 16),
            _buildInfoRow('Dates', '${dateFormat.format(startDate)} – ${dateFormat.format(endDate)}'),
            const SizedBox(height: 12),
            _buildInfoRow('Length of stay', '$nightCount nights'),
            const SizedBox(height: 12),
            _buildInfoRow('Guests', '$totalGuests guests'),
            
            const SizedBox(height: 32),
            const Divider(color: AppTheme.borderColor),
            const SizedBox(height: 32),
            
            // 3. Price Breakdown
            _buildSectionTitle('Price breakdown'),
            const SizedBox(height: 16),
            _buildPriceRow('PKR ${currencyFormat.format(property.price)} x $nightCount nights', 'PKR ${currencyFormat.format(basePrice)}'),
            const SizedBox(height: 12),
            _buildPriceRow('Cleaning fee', 'PKR ${currencyFormat.format(cleaningFee)}'),
            const SizedBox(height: 12),
            _buildPriceRow('Service fee (10%)', 'PKR ${currencyFormat.format(serviceFee)}'),
            const SizedBox(height: 12),
            _buildPriceRow('Taxes & Fees (16%)', 'PKR ${currencyFormat.format(taxes)}'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total paid (PKR)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'PKR ${currencyFormat.format(totalCost)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Divider(color: AppTheme.borderColor),
            const SizedBox(height: 32),
            
            // 4. Payment Info
            _buildSectionTitle('Payment information'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200, width: 2),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildPaymentRow('Payment method', 'EasyPaisa', Icons.account_balance_wallet_rounded),
                  const SizedBox(height: 12),
                  _buildPaymentRow('Payment date', dateFormat.format(DateTime.now()), Icons.calendar_today_rounded),
                  const SizedBox(height: 12),
                  _buildPaymentRow('Status', 'Paid', Icons.check_circle_rounded, color: Colors.green[700]),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // 5. Build Print Button
            ElevatedButton.icon(
              onPressed: () {
                // In a real app, this would trigger a PDF generation or standard print dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Preparing receipt for printing...'),
                    backgroundColor: AppTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              icon: const Icon(Icons.print_rounded),
              label: const Text('Print Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: Colors.black54,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
