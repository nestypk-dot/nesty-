import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../trips/domain/booking.dart';
import '../../home/domain/property.dart';
import '../data/booking_repository.dart';
import '../domain/price_breakdown.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  REPOSITORY PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Singleton [BookingRepository] – injected into all other providers.
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

/// Kept for backward compatibility with any existing references.
final bookingsServiceProvider = bookingRepositoryProvider;

// ═══════════════════════════════════════════════════════════════════════════════
//  PRICE BREAKDOWN PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Computes [PriceBreakdown] given a property, check-in, and check-out.
/// Returns null if dates are not yet set.
final priceBreakdownProvider = Provider.family<PriceBreakdown?, ({
  Property property,
  DateTime? checkIn,
  DateTime? checkOut,
})>((ref, args) {
  if (args.checkIn == null || args.checkOut == null) return null;
  return ref.read(bookingRepositoryProvider).computeBreakdown(
    property: args.property,
    checkIn: args.checkIn!,
    checkOut: args.checkOut!,
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
//  BOOKING CREATION STATE
// ═══════════════════════════════════════════════════════════════════════════════

/// Represents the state of a booking-creation attempt.
sealed class BookingCreationState {
  const BookingCreationState();
}

class BookingCreationIdle extends BookingCreationState {
  const BookingCreationIdle();
}

class BookingCreationLoading extends BookingCreationState {
  const BookingCreationLoading();
}

class BookingCreationSuccess extends BookingCreationState {
  final String bookingId;
  const BookingCreationSuccess(this.bookingId);
}

class BookingCreationError extends BookingCreationState {
  final String message;
  const BookingCreationError(this.message);
}

/// Notifier that drives the "Pay" button on Step 3.
///
/// Usage from UI:
/// ```dart
/// final notifier = ref.read(bookingCreationProvider.notifier);
/// await notifier.submit(booking);
/// ```
class BookingCreationNotifier extends Notifier<BookingCreationState> {
  @override
  BookingCreationState build() => const BookingCreationIdle();

  /// Submits the booking to Firebase. Updates state reactively so the UI
  /// can show loading / success / error without callbacks.
  Future<void> submit(Booking booking) async {
    state = const BookingCreationLoading();
    try {
      final id = await ref
          .read(bookingRepositoryProvider)
          .createBooking(booking);
      state = BookingCreationSuccess(id);
    } on BookingConflictException catch (e) {
      state = BookingCreationError(e.toString());
    } on BookingAuthException catch (e) {
      state = BookingCreationError(e.toString());
    } catch (e) {
      state = BookingCreationError(
        'Something went wrong / کچھ غلط ہوا۔ Please try again.',
      );
    }
  }

  /// Resets state back to idle (called when user edits payment info).
  void reset() => state = const BookingCreationIdle();
}

final bookingCreationProvider =
    NotifierProvider<BookingCreationNotifier, BookingCreationState>(
  BookingCreationNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════════
//  BOOKING CANCELLATION STATE
// ═══════════════════════════════════════════════════════════════════════════════

sealed class BookingCancellationState {
  const BookingCancellationState();
}

class BookingCancellationIdle extends BookingCancellationState {
  const BookingCancellationIdle();
}

class BookingCancellationLoading extends BookingCancellationState {
  const BookingCancellationLoading();
}

class BookingCancellationSuccess extends BookingCancellationState {
  const BookingCancellationSuccess();
}

class BookingCancellationError extends BookingCancellationState {
  final String message;
  const BookingCancellationError(this.message);
}

class BookingCancellationNotifier
    extends Notifier<BookingCancellationState> {
  @override
  BookingCancellationState build() => const BookingCancellationIdle();

  Future<void> cancel(String bookingId) async {
    state = const BookingCancellationLoading();
    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(bookingId);
      state = const BookingCancellationSuccess();
    } catch (e) {
      state = BookingCancellationError(e.toString());
    }
  }

  void reset() => state = const BookingCancellationIdle();
}

final bookingCancellationProvider = NotifierProvider<
    BookingCancellationNotifier, BookingCancellationState>(
  BookingCancellationNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════════
//  GUEST BOOKINGS STREAM
// ═══════════════════════════════════════════════════════════════════════════════

final guestBookingsProvider = StreamProvider<List<Booking>>((ref) {
  return ref.watch(bookingRepositoryProvider).watchGuestBookings();
});

// ═══════════════════════════════════════════════════════════════════════════════
//  HOST BOOKINGS NOTIFIER  (optimistic UI updates)
// ═══════════════════════════════════════════════════════════════════════════════

class HostBookingsNotifier
    extends Notifier<AsyncValue<List<Booking>>> {
  late final BookingRepository _repo;
  StreamSubscription<List<Booking>>? _sub;
  List<Booking> _cache = [];

  @override
  AsyncValue<List<Booking>> build() {
    _repo = ref.watch(bookingRepositoryProvider);
    _startListening();
    ref.onDispose(() => _sub?.cancel());
    return const AsyncValue.loading();
  }

  void _startListening() {
    _sub?.cancel();
    _sub = _repo.watchHostBookings().listen(
      (bookings) {
        _cache = bookings;
        state = AsyncValue.data(bookings);
      },
      onError: (err, stack) {
        // Keep last known state so the UI never goes blank.
        if (_cache.isEmpty) {
          state = AsyncValue.error(err, stack);
        }
        // ignore: avoid_print
        print('[HostBookingsNotifier] stream error: $err');
      },
    );
  }

  /// Optimistically updates a booking's status locally, then persists.
  Future<void> updateStatus(String bookingId, BookingStatus status) async {
    // 1. Immediate local update (no loading flicker)
      _cache = _cache.map((b) {
      if (b.id != bookingId) return b;
      return Booking(
        id: b.id,
        property: b.property,
        checkInDate: b.checkInDate,
        checkOutDate: b.checkOutDate,
        totalPrice: b.totalPrice,
        status: status,
        totalGuests: b.totalGuests,
        guestId: b.guestId,
        guestName: b.guestName,
        guestAvatar: b.guestAvatar,
        hostId: b.hostId,
        createdAt: b.createdAt,
        paymentMethod: b.paymentMethod,
        paymentPhone: b.paymentPhone,
        adultsCount: b.adultsCount,
        childrenCount: b.childrenCount,
        infantsCount: b.infantsCount,
        priceBreakdown: b.priceBreakdown,
        messageToHost: b.messageToHost,
        termsAccepted: b.termsAccepted,
      );
    }).toList();
    state = AsyncValue.data(_cache);

    // 2. Persist to Firestore + send notification
    try {
      await _repo.updateBookingStatus(bookingId, status);
    } catch (e) {
      // ignore: avoid_print
      print('[HostBookingsNotifier] update error: $e');
    }
  }
}

final hostBookingsProvider =
    NotifierProvider<HostBookingsNotifier, AsyncValue<List<Booking>>>(
  HostBookingsNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════════
//  SINGLE BOOKING STREAM
// ═══════════════════════════════════════════════════════════════════════════════

final singleBookingProvider =
    StreamProvider.family<Booking?, String>((ref, bookingId) {
  return ref.watch(bookingRepositoryProvider).watchBooking(bookingId);
});
