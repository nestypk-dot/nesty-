/// Immutable model for the full price breakdown of a booking.
/// Each field maps 1-to-1 to a Firestore sub-document field so that
/// the host dashboard, receipts, and analytics can read individual
/// components without recomputing them.
class PriceBreakdown {
  final int nights;
  final int pricePerNight;
  final int basePrice;      // pricePerNight × nights
  final int cleaningFee;
  final int serviceFee;     // 10 % of basePrice
  final int taxes;          // 16 % of basePrice
  final int total;

  const PriceBreakdown({
    required this.nights,
    required this.pricePerNight,
    required this.basePrice,
    required this.cleaningFee,
    required this.serviceFee,
    required this.taxes,
    required this.total,
  });

  // ─── Factory helpers ───────────────────────────────────────────────────────

  /// Compute from raw inputs – single source of truth for fee math.
  factory PriceBreakdown.compute({
    required int pricePerNight,
    required int nights,
    int cleaningFee = 1500,
    double serviceFeeRate = 0.10,
    double taxRate = 0.16,
  }) {
    final base = pricePerNight * nights;
    final svc = (base * serviceFeeRate).round();
    final tax = (base * taxRate).round();
    final tot = base + cleaningFee + svc + tax;
    return PriceBreakdown(
      nights: nights,
      pricePerNight: pricePerNight,
      basePrice: base,
      cleaningFee: cleaningFee,
      serviceFee: svc,
      taxes: tax,
      total: tot,
    );
  }

  /// Deserialise from a Firestore map.
  factory PriceBreakdown.fromJson(Map<String, dynamic> json) {
    return PriceBreakdown(
      nights: (json['nights'] ?? 0).toInt(),
      pricePerNight: (json['pricePerNight'] ?? 0).toInt(),
      basePrice: (json['basePrice'] ?? 0).toInt(),
      cleaningFee: (json['cleaningFee'] ?? 1500).toInt(),
      serviceFee: (json['serviceFee'] ?? 0).toInt(),
      taxes: (json['taxes'] ?? 0).toInt(),
      total: (json['total'] ?? 0).toInt(),
    );
  }

  /// Serialise to a Firestore map – stored as sub-document on each booking.
  Map<String, dynamic> toJson() => {
    'nights': nights,
    'pricePerNight': pricePerNight,
    'basePrice': basePrice,
    'cleaningFee': cleaningFee,
    'serviceFee': serviceFee,
    'taxes': taxes,
    'total': total,
  };

  @override
  String toString() =>
      'PriceBreakdown(nights: $nights, total: $total)';
}
