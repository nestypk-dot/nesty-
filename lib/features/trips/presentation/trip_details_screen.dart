import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../booking/providers/bookings_provider.dart';
import '../domain/booking.dart';

class TripDetailsScreen extends ConsumerWidget {
  final Booking booking;

  const TripDetailsScreen({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = NumberFormat("#,##0", "en_US");
    
    // Watch single booking stream for real-time status updates
    final liveBookingAsync = ref.watch(singleBookingProvider(booking.id));
    
    // Fall back to initial booking snapshot if stream is loading or empty
    final currentBooking = liveBookingAsync.value ?? booking;

    // Status styling configurations
    Color statusBgColor = const Color(0xFFFEF9C3); // default yellow
    Color statusTextColor = const Color(0xFF854D0E);
    String statusLabel = 'Pending Approval';
    List<String> nextSteps = [
      'The host will review your booking request',
      'You\'ll receive a notification once the host accepts',
      'After approval, you can message the host and get check-in details',
    ];

    switch (currentBooking.status) {
      case BookingStatus.pending:
        statusBgColor = const Color(0xFFFEF9C3);
        statusTextColor = const Color(0xFF854D0E);
        statusLabel = 'Pending Approval';
        nextSteps = [
          'The host will review your booking request',
          'You\'ll receive a notification once the host accepts',
          'After approval, you can message the host and get check-in details',
        ];
        break;
      case BookingStatus.upcoming:
        statusBgColor = const Color(0xFFD1FAE5);
        statusTextColor = const Color(0xFF065F46);
        statusLabel = 'Confirmed';
        nextSteps = [
          'Get check-in instructions from the host',
          'Message the host for any questions about your stay',
          'Enjoy your trip!',
        ];
        break;
      case BookingStatus.current:
        statusBgColor = const Color(0xFFEFF6FF);
        statusTextColor = const Color(0xFF1E40AF);
        statusLabel = 'Active';
        nextSteps = [
          'You are currently checked in!',
          'Reach out to the host if you have any issues',
          'Check-out instructions will be available soon',
        ];
        break;
      case BookingStatus.past:
        statusBgColor = const Color(0xFFE2E8F0);
        statusTextColor = const Color(0xFF1E293B);
        statusLabel = 'Completed';
        nextSteps = [
          'We hope you had a great stay!',
          'Leave a review to help other guests',
          'Book this place again if you loved it!',
        ];
        break;
      case BookingStatus.cancelled:
        statusBgColor = const Color(0xFFFEE2E2);
        statusTextColor = const Color(0xFF991B1B);
        statusLabel = 'Cancelled';
        nextSteps = [
          'This booking request was cancelled',
          'Refund is processed back to your payment account',
          'Explore other properties on Nesty to find a stay',
        ];
        break;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
        title: Image.network(
          'https://nestypk.base44.app/assets/images/logo.png',
          height: 30,
          errorBuilder: (_, __, ___) => const Text(
            'Nesty',
            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: false,
        actions: [
          _buildTopProfile(ref),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: statusTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // 2. Total Amount Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  'PKR ${format.format(currentBooking.totalPrice)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // 3. What's Next Section (Blue Shield Style)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF), // Very soft blue
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE0EFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Color(0xFF1D4ED8), size: 24),
                      const SizedBox(width: 12),
                      Text(
                        currentBooking.status == BookingStatus.cancelled
                            ? 'Cancellation Info'
                            : 'What\'s Next?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildNextStepRow(1, nextSteps[0]),
                  _buildNextStepRow(2, nextSteps[1]),
                  _buildNextStepRow(3, nextSteps[2]),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 4. Action Buttons
            ElevatedButton(
              onPressed: () => context.go('/trips'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('View My Bookings', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/booking-receipt', extra: {
                        'property': currentBooking.property,
                        'startDate': currentBooking.checkInDate,
                        'endDate': currentBooking.checkOutDate,
                        'totalGuests': currentBooking.totalGuests,
                        'totalCost': currentBooking.totalPrice.toInt(),
                      });
                    },
                    icon: const Icon(Icons.download_rounded, size: 20, color: Colors.black87),
                    label: const Text('Receipt', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.black12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.black12),
                    ),
                    child: const Text('Back Home', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
            
            // Cancel booking request button (visible when booking is pending or upcoming)
            if (currentBooking.status == BookingStatus.pending || currentBooking.status == BookingStatus.upcoming) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _showCancelConfirmation(context, ref, currentBooking.id),
                icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 20),
                label: Text(
                  currentBooking.status == BookingStatus.upcoming ? 'Cancel Confirmed Booking' : 'Cancel Booking Request',
                  style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w900),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFFEE2E2)),
                  backgroundColor: const Color(0xFFFEF2F2),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildTopProfile(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final photoUrl = authState.photoUrl;
    final initial = authState.name?.isNotEmpty == true 
        ? authState.name![0].toLowerCase() 
        : 'u';

    return Row(
      children: [
        const Icon(Icons.notifications_none_rounded, color: Colors.black87),
        const SizedBox(width: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: photoUrl != null && photoUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: photoUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _buildInitialAvatar(initial),
                )
              : _buildInitialAvatar(initial),
        ),
      ],
    );
  }

  Widget _buildInitialAvatar(String initial) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildNextStepRow(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, WidgetRef ref, String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Request',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Are you sure you want to cancel this booking request?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No, Keep It',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black54,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(bookingsServiceProvider).updateBookingStatus(
                  bookingId,
                  BookingStatus.cancelled,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking request cancelled successfully.'),
                      backgroundColor: Colors.black87,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
