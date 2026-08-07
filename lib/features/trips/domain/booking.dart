import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home/domain/property.dart';
import '../../booking/domain/price_breakdown.dart';

enum BookingStatus {
  pending,
  upcoming,
  current,
  past,
  cancelled,
}

class Booking {
  final String id;
  final Property property;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final double totalPrice;
  final BookingStatus status;
  final int totalGuests;
  final String guestId;
  final String guestName;
  final String guestAvatar;
  final String hostId;
  final String? paymentMethod;
  final String? paymentPhone;
  final DateTime createdAt;

  // ── Guest breakdown (individually stored in Firestore) ─────────────────────
  /// Adults count (Ages 13+) — stored individually in Firestore.
  final int adultsCount;
  /// Children count (Ages 2–12) — stored individually in Firestore.
  final int childrenCount;
  /// Infants count (Under 2) — stored individually in Firestore.
  final int infantsCount;

  // ── New fields added for Payment & Review backend ──────────────────────────
  /// Structured fee breakdown stored in Firestore sub-document.
  final PriceBreakdown? priceBreakdown;
  /// Optional message the guest sends to the host at checkout.
  final String? messageToHost;
  /// Whether the guest checked the house-rules / terms checkbox.
  final bool termsAccepted;

  Booking({
    required this.id,
    required this.property,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalPrice,
    required this.status,
    required this.totalGuests,
    required this.guestId,
    required this.guestName,
    required this.guestAvatar,
    required this.hostId,
    this.paymentMethod,
    this.paymentPhone,
    required this.createdAt,
    this.adultsCount = 1,
    this.childrenCount = 0,
    this.infantsCount = 0,
    this.priceBreakdown,
    this.messageToHost,
    this.termsAccepted = false,
  });

  factory Booking.fromJson(Map<String, dynamic> json, String documentId) {
    return Booking(
      id: documentId,
      property: Property.fromJson(Map<String, dynamic>.from(json['property'] ?? {}), json['propertyId'] ?? ''),
      checkInDate: (json['checkInDate'] as Timestamp).toDate(),
      checkOutDate: (json['checkOutDate'] as Timestamp).toDate(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'pending'),
        orElse: () => BookingStatus.pending,
      ),
      totalGuests: (json['totalGuests'] ?? 1).toInt(),
      guestId: json['guestId'] ?? '',
      guestName: json['guestName'] ?? '',
      guestAvatar: json['guestAvatar'] ?? '',
      hostId: json['hostId'] ?? '',
      paymentMethod: json['paymentMethod'],
      paymentPhone: json['paymentPhone'],
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      adultsCount: (json['adultsCount'] ?? json['totalGuests'] ?? 1).toInt(),
      childrenCount: (json['childrenCount'] ?? 0).toInt(),
      infantsCount: (json['infantsCount'] ?? 0).toInt(),
      priceBreakdown: json['priceBreakdown'] != null
          ? PriceBreakdown.fromJson(Map<String, dynamic>.from(json['priceBreakdown']))
          : null,
      messageToHost: json['messageToHost'],
      termsAccepted: json['termsAccepted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': property.id,
      'property': property.toJson(),
      'checkInDate': Timestamp.fromDate(checkInDate),
      'checkOutDate': Timestamp.fromDate(checkOutDate),
      'totalPrice': totalPrice,
      'status': status.name,
      'totalGuests': totalGuests,
      'guestId': guestId,
      'guestName': guestName,
      'guestAvatar': guestAvatar,
      'hostId': hostId,
      'paymentMethod': paymentMethod,
      'paymentPhone': paymentPhone,
      'createdAt': Timestamp.fromDate(createdAt),
      // Store each guest category separately for host visibility
      'adultsCount': adultsCount,
      'childrenCount': childrenCount,
      'infantsCount': infantsCount,
      if (priceBreakdown != null) 'priceBreakdown': priceBreakdown!.toJson(),
      if (messageToHost != null && messageToHost!.isNotEmpty)
        'messageToHost': messageToHost,
      'termsAccepted': termsAccepted,
    };
  }
}

final List<Booking> mockBookings = [
  Booking(
    id: 'b1',
    property: mockProperties[0],
    checkInDate: DateTime.now().add(const Duration(days: 10)),
    checkOutDate: DateTime.now().add(const Duration(days: 15)),
    totalPrice: 77500,
    status: BookingStatus.upcoming,
    totalGuests: 4,
    guestId: 'mock_guest_id',
    guestName: 'Muhammad Haad',
    guestAvatar: 'https://i.pravatar.cc/150?u=haad',
    hostId: 'mock_host_id',
    createdAt: DateTime.now(),
  ),
  Booking(
    id: 'b2',
    property: mockProperties[1],
    checkInDate: DateTime.now().subtract(const Duration(days: 2)),
    checkOutDate: DateTime.now().add(const Duration(days: 3)),
    totalPrice: 60000,
    status: BookingStatus.current,
    totalGuests: 2,
    guestId: 'mock_guest_id',
    guestName: 'Muhammad Haad',
    guestAvatar: 'https://i.pravatar.cc/150?u=haad',
    hostId: 'mock_host_id',
    createdAt: DateTime.now(),
  ),
  Booking(
    id: 'b3',
    property: mockProperties[2],
    checkInDate: DateTime.now().subtract(const Duration(days: 20)),
    checkOutDate: DateTime.now().subtract(const Duration(days: 15)),
    totalPrice: 42500,
    status: BookingStatus.past,
    totalGuests: 2,
    guestId: 'mock_guest_id',
    guestName: 'Muhammad Haad',
    guestAvatar: 'https://i.pravatar.cc/150?u=haad',
    hostId: 'mock_host_id',
    createdAt: DateTime.now(),
  ),
  Booking(
    id: 'b4',
    property: mockProperties[3],
    checkInDate: DateTime.now().add(const Duration(days: 45)),
    checkOutDate: DateTime.now().add(const Duration(days: 50)),
    totalPrice: 30000,
    status: BookingStatus.cancelled,
    totalGuests: 4,
    guestId: 'mock_guest_id',
    guestName: 'Muhammad Haad',
    guestAvatar: 'https://i.pravatar.cc/150?u=haad',
    hostId: 'mock_host_id',
    createdAt: DateTime.now(),
  ),
  Booking(
    id: 'b5',
    property: mockProperties[5],
    checkInDate: DateTime.now().add(const Duration(days: 20)),
    checkOutDate: DateTime.now().add(const Duration(days: 25)),
    totalPrice: 90000,
    status: BookingStatus.upcoming,
    totalGuests: 2,
    guestId: 'mock_guest_id',
    guestName: 'Muhammad Haad',
    guestAvatar: 'https://i.pravatar.cc/150?u=haad',
    hostId: 'mock_host_id',
    createdAt: DateTime.now(),
  ),
];
