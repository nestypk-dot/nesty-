import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/nesty_bottom_nav.dart';
import '../../trips/domain/booking.dart';
import '../../booking/providers/bookings_provider.dart';

class HostBookingsScreen extends ConsumerStatefulWidget {
  const HostBookingsScreen({super.key});

  @override
  ConsumerState<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _HostBookingsScreenState extends ConsumerState<HostBookingsScreen> {
  int _activeTabIndex = 0; // 0: Requests, 1: Confirmed, 2: Completed

  void _approveBooking(Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Booking Approved!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have accepted ${booking.guestName}\'s booking request for ${booking.property.title}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      try {
                        await ref.read(hostBookingsProvider.notifier).updateStatus(
                          booking.id,
                          BookingStatus.upcoming,
                        );
                        setState(() {
                          _activeTabIndex = 1; // Auto shift to Confirmed tab
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Booking request approved!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                              backgroundColor: const Color(0xFF00674F),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error approving booking: $e'),
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00674F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Perfect',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _declineBooking(Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_rounded,
                    color: Color(0xFFEF4444),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Decline Request?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to decline ${booking.guestName}\'s booking request?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'No, Keep',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.black87,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          try {
                            await ref.read(hostBookingsProvider.notifier).updateStatus(
                              booking.id,
                              BookingStatus.cancelled,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Request declined successfully.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error declining request: $e'),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Yes, Decline',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(hostBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        // Filter bookings by active status tab
        final pendingBookings = bookings
            .where((b) => b.status == BookingStatus.pending)
            .toList();
        final confirmedBookings = bookings
            .where((b) => b.status == BookingStatus.upcoming || b.status == BookingStatus.current)
            .toList();
        final completedBookings = bookings
            .where((b) => b.status == BookingStatus.past || b.status == BookingStatus.cancelled)
            .toList();

        List<Booking> filteredList;
        String statusFilterStr = 'pending';
        switch (_activeTabIndex) {
          case 0:
            filteredList = pendingBookings;
            statusFilterStr = 'pending';
            break;
          case 1:
            filteredList = confirmedBookings;
            statusFilterStr = 'confirmed';
            break;
          case 2:
            filteredList = completedBookings;
            statusFilterStr = 'completed';
            break;
          default:
            filteredList = pendingBookings;
        }

        final pendingCount = pendingBookings.length;
        final confirmedCount = confirmedBookings.length;

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
            backgroundColor: const Color(0xFFFAFAFA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
              ),
              title: Text(
                'Bookings Manager',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Stats Counter banner (premium rounded card)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatPill('Pending', '$pendingCount Request${pendingCount == 1 ? '' : 's'}', const Color(0xFFFBBF24)),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _buildStatPill('Upcoming', '$confirmedCount Active', const Color(0xFF00674F)),
                      ],
                    ),
                  ),
                ),

                // 2. Custom Slider Tab selector
                Container(
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildSliderTab(0, 'Requests')),
                      Expanded(child: _buildSliderTab(1, 'Confirmed')),
                      Expanded(child: _buildSliderTab(2, 'Completed')),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Bookings List
                Expanded(
                  child: filteredList.isEmpty
                      ? _buildEmptyState(statusFilterStr)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final booking = filteredList[index];
                            return _buildBookingItemCard(context, booking);
                          },
                        ),
                ),
              ],
            ),
            bottomNavigationBar: const NestyBottomNav(currentIndex: 2),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00674F)),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('Error loading host bookings: $err'),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSliderTab(int index, String label) {
    final bool isSelected = _activeTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.black : Colors.black54,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingItemCard(BuildContext context, Booking booking) {
    final format = NumberFormat("#,##0", "en_US");
    final dateFormat = DateFormat('MMM d');
    final yearFormat = DateFormat('yyyy');
    
    final dateStr = '${dateFormat.format(booking.checkInDate)} - ${dateFormat.format(booking.checkOutDate)}, ${yearFormat.format(booking.checkInDate)}';

    // Status label mapping
    String statusLabel = booking.status.name.toUpperCase();
    Color statusBgColor = const Color(0xFFE2E8F0);
    Color statusTextColor = Colors.black54;

    if (booking.status == BookingStatus.pending) {
      statusLabel = 'PENDING';
      statusBgColor = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFD97706);
    } else if (booking.status == BookingStatus.upcoming || booking.status == BookingStatus.current) {
      statusLabel = booking.status == BookingStatus.current ? 'ACTIVE' : 'CONFIRMED';
      statusBgColor = const Color(0xFFD1FAE5);
      statusTextColor = const Color(0xFF059669);
    } else if (booking.status == BookingStatus.cancelled) {
      statusLabel = 'CANCELLED';
      statusBgColor = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFEF4444);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Guest profile & details
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: booking.guestAvatar.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: booking.guestAvatar,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey.shade200,
                            child: Text(
                              booking.guestName.isNotEmpty ? booking.guestName[0].toUpperCase() : 'G',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey.shade200,
                          child: Text(
                            booking.guestName.isNotEmpty ? booking.guestName[0].toUpperCase() : 'G',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.guestName,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_user_rounded, color: Color(0xFF00674F), size: 14),
                        ],
                      ),
                      Text(
                        'Requested ${booking.totalGuests} guest${booking.totalGuests > 1 ? 's' : ''}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: statusTextColor,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 14),

            // Middle: Property Info
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: booking.property.imageUrl,
                    width: 70,
                    height: 52,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 70,
                      height: 52,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.property.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dateStr,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 14),

            // Footer: Payout info and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PKR ${format.format(booking.totalPrice)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: const Color(0xFF00674F),
                      ),
                    ),
                    Text(
                      'Host payout',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                
                // Action Buttons based on status
                if (booking.status == BookingStatus.pending)
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _declineBooking(booking),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00674F), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Text(
                          'Decline',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF00674F),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _approveBooking(booking),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00674F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 36),
                          elevation: 0,
                        ),
                        child: Text(
                          'Approve',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          // Real details popup
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (context) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Booking Details',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildDetailRow('Guest', booking.guestName),
                                    if (booking.paymentPhone != null)
                                      _buildDetailRow('Payment Phone', booking.paymentPhone!),
                                    _buildDetailRow('Property', booking.property.title),
                                    _buildDetailRow('Dates', dateStr),
                                    _buildDetailRow('Total Paid', 'PKR ${format.format(booking.totalPrice)}'),
                                    _buildDetailRow('Status', statusLabel),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00674F),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        child: Text(
                                          'Close',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00674F), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Text(
                          'Details',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF00674F),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to chat screen. 
                          // Peer is the guest!
                          context.push('/chat', extra: {
                            'peerId': booking.guestId,
                            'peerName': booking.guestName,
                            'peerImageUrl': booking.guestAvatar,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00674F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 36),
                          elevation: 0,
                        ),
                        child: Text(
                          'Message',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                status == 'pending'
                    ? Icons.hourglass_empty_rounded
                    : status == 'confirmed'
                        ? Icons.upcoming_rounded
                        : Icons.check_circle_outline_rounded,
                size: 40,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No $status bookings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Any bookings with "$status" status will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
