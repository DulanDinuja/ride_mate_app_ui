/// Represents per-ride income breakdown for a driver
/// (maps to RideIncomeDetailResponseResource).
class RideIncomeDetail {
  final int? rideDetailId;
  final String? startCity;
  final double? totalRideDistance;
  final double? totalRideCost;
  final double? grossEarning;
  final double? commissionPercentage;
  final double? commissionAmount;
  final double? netEarning;
  final String? currency;
  final int? numberOfPassengers;
  final DateTime? rideDate;
  final DateTime? earnedDate;

  RideIncomeDetail({
    this.rideDetailId,
    this.startCity,
    this.totalRideDistance,
    this.totalRideCost,
    this.grossEarning,
    this.commissionPercentage,
    this.commissionAmount,
    this.netEarning,
    this.currency,
    this.numberOfPassengers,
    this.rideDate,
    this.earnedDate,
  });

  factory RideIncomeDetail.fromJson(Map<String, dynamic> json) {
    return RideIncomeDetail(
      rideDetailId: json['rideDetailId'] as int?,
      startCity: json['startCity'] as String?,
      totalRideDistance: (json['totalRideDistance'] as num?)?.toDouble(),
      totalRideCost: (json['totalRideCost'] as num?)?.toDouble(),
      grossEarning: (json['grossEarning'] as num?)?.toDouble(),
      commissionPercentage: (json['commissionPercentage'] as num?)?.toDouble(),
      commissionAmount: (json['commissionAmount'] as num?)?.toDouble(),
      netEarning: (json['netEarning'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      numberOfPassengers: json['numberOfPassengers'] as int?,
      rideDate: json['rideDate'] != null
          ? DateTime.tryParse(json['rideDate'].toString())
          : null,
      earnedDate: json['earnedDate'] != null
          ? DateTime.tryParse(json['earnedDate'].toString())
          : null,
    );
  }
}

