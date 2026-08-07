import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/nesty_bottom_nav.dart';
import '../domain/booking.dart';
import '../../booking/providers/bookings_provider.dart';

class TripsScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const TripsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  late int _selectedIndex;
  final List<String> _tabs = ['Upcoming', 'Past', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant TripsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedIndex = widget.initialTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(guestBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        final upcomingBookings = bookings
            .where((b) => b.status == BookingStatus.pending || b.status == BookingStatus.upcoming || b.status == BookingStatus.current)
            .toList();
        final pastBookings = bookings
            .where((b) => b.status == BookingStatus.past)
            .toList();
        final cancelledBookings = bookings
            .where((b) => b.status == BookingStatus.cancelled)
            .toList();

        final upcomingCount = upcomingBookings.where((b) => b.status == BookingStatus.pending).length;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (GoRouter.of(context).canPop()) {
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
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 22),
                onPressed: () {
                  if (GoRouter.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              title: Text(
                'My Trips',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              centerTitle: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      _buildSegment(0, _tabs[0], upcomingCount),
                      _buildSegment(1, _tabs[1], 0),
                      _buildSegment(2, _tabs[2], 0),
                    ],
                  ),
                ),
              ),
            ),
            body: _buildTripsList(upcomingBookings, pastBookings, cancelledBookings),
            bottomNavigationBar: const NestyBottomNav(currentIndex: 2),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('Error loading trips: $err'),
        ),
      ),
    );
  }

  Widget _buildSegment(int index, String title, int count) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.grey.shade200) : Border.all(color: Colors.transparent),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripsList(List<Booking> upcoming, List<Booking> past, List<Booking> cancelled) {
    List<Booking> activeList;
    switch (_selectedIndex) {
      case 0:
        activeList = upcoming;
        break;
      case 1:
        activeList = past;
        break;
      case 2:
        activeList = cancelled;
        break;
      default:
        activeList = upcoming;
    }

    if (activeList.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: activeList.length,
      itemBuilder: (context, index) {
        final booking = activeList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildBookingCard(booking),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message = '';
    switch (_selectedIndex) {
      case 0:
        message = 'No upcoming trips booked yet.';
        break;
      case 1:
        message = 'No past trips found.';
        break;
      case 2:
        message = 'No cancelled trips.';
        break;
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_takeoff_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final format = NumberFormat("#,##0", "en_US");
    final dateFormat = DateFormat('MMM d');
    final yearFormat = DateFormat('yyyy');
    
    final dateStr = '${dateFormat.format(booking.checkInDate)} - ${dateFormat.format(booking.checkOutDate)}, ${yearFormat.format(booking.checkInDate)}';
    
    // Status color configurations
    Color statusBgColor = const Color(0xFFD1FAE5); // default green
    Color statusTextColor = const Color(0xFF065F46);
    String statusLabel = 'Confirmed';

    if (booking.status == BookingStatus.pending) {
      statusBgColor = const Color(0xFFFEF3C7); // yellow
      statusTextColor = const Color(0xFFB45309);
      statusLabel = 'Pending';
    } else if (booking.status == BookingStatus.cancelled) {
      statusBgColor = const Color(0xFFFEE2E2); // red
      statusTextColor = const Color(0xFF991B1B);
      statusLabel = 'Cancelled';
    } else if (booking.status == BookingStatus.current) {
      statusBgColor = const Color(0xFFEFF6FF); // blue
      statusTextColor = const Color(0xFF1E40AF);
      statusLabel = 'Active';
    } else if (booking.status == BookingStatus.past) {
      statusBgColor = const Color(0xFFE2E8F0); // grey
      statusTextColor = const Color(0xFF1E293B);
      statusLabel = 'Completed';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Image Section
            SizedBox(
              width: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                    child: CachedNetworkImage(
                      imageUrl: booking.property.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: Colors.grey.shade100, child: const Icon(Icons.broken_image)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            booking.status == BookingStatus.pending 
                                ? Icons.access_time_rounded 
                                : booking.status == BookingStatus.cancelled
                                    ? Icons.cancel_rounded
                                    : Icons.check_circle_rounded, 
                            size: 10, 
                            color: statusTextColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              statusLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: statusTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Right Details Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            booking.property.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_alt_rounded, size: 12, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.totalGuests} guest${booking.totalGuests > 1 ? 's' : ''}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'PKR ${format.format(booking.totalPrice)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  booking.status == BookingStatus.cancelled ? 'Refunded' : 'total price',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: booking.status == BookingStatus.cancelled ? const Color(0xFF059669) : Colors.black54,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Action buttons
                            if (booking.status == BookingStatus.pending || booking.status == BookingStatus.upcoming)
                              OutlinedButton(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Cancel Booking', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
                                      content: Text('Are you sure you want to cancel your booking for "${booking.property.title}"?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('No', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.black54))),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Yes, Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: const Color(0xFFEF4444)))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await ref.read(bookingsServiceProvider).updateBookingStatus(booking.id, BookingStatus.cancelled);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Booking cancelled successfully.')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 32),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFEF4444),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              )
                            else ...[
                              OutlinedButton(
                                onPressed: () {
                                  context.push('/trip-details', extra: booking);
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 32),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  'Details',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
