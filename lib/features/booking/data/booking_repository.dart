import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../trips/domain/booking.dart';
import '../../home/domain/property.dart';
import '../domain/price_breakdown.dart';

/// Exception thrown when the same guest tries to book an already-booked period.
class BookingConflictException implements Exception {
  final String message;
  const BookingConflictException(this.message);
  @override
  String toString() => message;
}

/// Exception thrown when required auth is missing.
class BookingAuthException implements Exception {
  const BookingAuthException();
  @override
  String toString() =>
      'You must be logged in to make a booking / بکنگ کے لیے لاگ ان ہونا ضروری ہے';
}

/// Pure data-layer class: all Firestore reads & writes for bookings live here.
///
/// Responsibilities:
///  - [createBooking]          → writes booking doc + notifies host
///  - [cancelBooking]          → sets status=cancelled + notifies guest
///  - [updateBookingStatus]    → host accepts / rejects
///  - [watchGuestBookings]     → real-time stream for guest trips screen
///  - [watchHostBookings]      → real-time stream for host dashboard
///  - [watchBooking]           → single booking live listener
///  - [checkDateConflict]      → guards against double-bookings
class BookingRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  BookingRepository({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ─── Collection ref helper ─────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  // ═══════════════════════════════════════════════════════════════════════════
  //  CREATE BOOKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a booking document in Firestore and triggers a host notification.
  ///
  /// Performs a **conflict check** before writing: if the same property already
  /// has an active booking whose dates overlap, throws [BookingConflictException].
  ///
  /// Returns the newly generated Firestore document ID.
  Future<String> createBooking(Booking booking) async {
    final user = _auth.currentUser;
    if (user == null) throw const BookingAuthException();

    // ── 1. Overlap guard ─────────────────────────────────────────────────────
    await _assertNoConflict(
      propertyId: booking.property.id,
      checkIn: booking.checkInDate,
      checkOut: booking.checkOutDate,
      excludeBookingId: null,
    );

    // ── 2. Write booking ─────────────────────────────────────────────────────
    final docRef = await _bookings.add(booking.toJson());

    // ── 3. Notify host ───────────────────────────────────────────────────────
    await _sendNotification(
      userId: booking.hostId,
      title: 'New Booking Request! 🏡',
      description:
          '${booking.guestName} wants to book "${booking.property.title}" '
          'for ${booking.totalGuests} guest${booking.totalGuests > 1 ? 's' : ''}.',
      category: 'booking',
    );

    return docRef.id;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  STATUS UPDATES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Updates the booking status (host accepts/rejects) and notifies the guest.
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    await _bookings.doc(bookingId).update({'status': status.name});

    // Fetch the booking to build a personalised notification.
    final snap = await _bookings.doc(bookingId).get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final guestId = data['guestId'] ?? '';
    final propName = data['property']?['title'] ?? 'your stay';

    String title = '';
    String desc = '';

    switch (status) {
      case BookingStatus.upcoming:
        title = 'Booking Confirmed! 🎉';
        desc = 'Your booking at "$propName" has been approved by the host.';
        break;
      case BookingStatus.cancelled:
        title = 'Booking Cancelled ❌';
        desc = 'Your booking at "$propName" was declined or cancelled.';
        break;
      case BookingStatus.current:
        title = 'Check-in Time! 🔑';
        desc = 'Your stay at "$propName" starts today. Enjoy your trip!';
        break;
      default:
        break;
    }

    if (title.isNotEmpty) {
      await _sendNotification(
        userId: guestId,
        title: title,
        description: desc,
        category: 'booking',
      );
    }
  }

  /// Guest cancels their own booking (only allowed while still `pending`).
  Future<void> cancelBooking(String bookingId) async {
    final user = _auth.currentUser;
    if (user == null) throw const BookingAuthException();

    final snap = await _bookings.doc(bookingId).get();
    if (!snap.exists) throw Exception('Booking not found / بکنگ نہیں ملی');

    final data = snap.data()!;
    if (data['guestId'] != user.uid) {
      throw Exception('Not authorised to cancel this booking');
    }

    await _bookings.doc(bookingId).update({'status': BookingStatus.cancelled.name});

    // Notify the host that the guest cancelled.
    final hostId = data['hostId'] ?? '';
    final guestName = data['guestName'] ?? 'Guest';
    final propName = data['property']?['title'] ?? 'a property';
    await _sendNotification(
      userId: hostId,
      title: 'Booking Cancelled 🚫',
      description: '$guestName cancelled their booking at "$propName".',
      category: 'booking',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  REAL-TIME STREAMS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream of all bookings made by the current guest.
  Stream<List<Booking>> watchGuestBookings() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _bookings
        .where('guestId', isEqualTo: user.uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => Booking.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Live stream of all bookings for properties owned by the current host.
  Stream<List<Booking>> watchHostBookings() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _bookings
        .where('hostId', isEqualTo: user.uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => Booking.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Live stream for a single booking document (used by trip-details screen).
  Stream<Booking?> watchBooking(String bookingId) {
    return _bookings.doc(bookingId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Booking.fromJson(doc.data()!, doc.id);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PRICE COMPUTATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stateless helper – compute the full price breakdown for a property + dates.
  /// Called from the UI to populate the review screen before creating a booking.
  PriceBreakdown computeBreakdown({
    required Property property,
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    final nights = checkOut.difference(checkIn).inDays;
    return PriceBreakdown.compute(
      pricePerNight: property.price.toInt(),
      nights: nights,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Throws [BookingConflictException] if the given property + date range
  /// overlaps with an existing active booking.
  Future<void> _assertNoConflict({
    required String propertyId,
    required DateTime checkIn,
    required DateTime checkOut,
    required String? excludeBookingId,
  }) async {
    // Active statuses that block a new booking.
    final activeStatuses = [
      BookingStatus.pending.name,
      BookingStatus.upcoming.name,
      BookingStatus.current.name,
    ];

    final snap = await _bookings
        .where('propertyId', isEqualTo: propertyId)
        .get();

    for (final doc in snap.docs) {
      if (doc.id == excludeBookingId) continue;
      final data = doc.data();
      final statusStr = data['status'] as String?;
      if (!activeStatuses.contains(statusStr)) continue;

      final existingIn =
          (data['checkInDate'] as Timestamp).toDate();
      final existingOut =
          (data['checkOutDate'] as Timestamp).toDate();

      // Overlap when newIn < existingOut AND newOut > existingIn
      final overlaps =
          checkIn.isBefore(existingOut) && checkOut.isAfter(existingIn);
      if (overlaps) {
        throw BookingConflictException(
          'These dates are already booked / یہ تاریخیں پہلے سے بک ہیں۔ '
          'Please choose different dates.',
        );
      }
    }
  }

  /// Writes a notification document to the `notifications` collection.
  Future<void> _sendNotification({
    required String userId,
    required String title,
    required String description,
    required String category,
  }) async {
    if (userId.isEmpty) return;
    try {
      await _notifications.add({
        'userId': userId,
        'title': title,
        'description': description,
        'time': 'Just now',
        'category': category,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Non-fatal – logging only; booking itself already succeeded.
      // ignore: avoid_print
      print('[BookingRepository] notification error: $e');
    }
  }
}
