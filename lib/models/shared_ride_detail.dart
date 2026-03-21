/// Response model for GET /shared-ride/details/{id} and GET /shared-ride/history/{userId}
/// Matches backend ShareRideDetailResponse.
class SharedRideDetail {
  final int id;
  final int rideDetailId;
  final int userId;
  final String? userEmail;
  final String? passengerName;
  final double passengerStartLat;
  final double passengerStartLng;
  final double passengerEndLat;
  final double passengerEndLng;
  final String? startCity;
  final String? endCity;
  final double passengerRideDistance;
  final double? passengerCost;
  final String? status;
  final String? createdDate;

  const SharedRideDetail({
    required this.id,
    required this.rideDetailId,
    required this.userId,
    this.userEmail,
    this.passengerName,
    required this.passengerStartLat,
    required this.passengerStartLng,
    required this.passengerEndLat,
    required this.passengerEndLng,
    this.startCity,
    this.endCity,
    required this.passengerRideDistance,
    this.passengerCost,
    this.status,
    this.createdDate,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isActive => status == 'ACTIVE' || status == 'CONFIRMED';

  factory SharedRideDetail.fromJson(Map<String, dynamic> json) {
    return SharedRideDetail(
      id: (json['id'] as num).toInt(),
      rideDetailId: (json['rideDetailId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      userEmail: json['userEmail'] as String?,
      passengerName: json['passengerName'] as String?,
      passengerStartLat:
          (json['passengerStartLat'] as num?)?.toDouble() ?? 0.0,
      passengerStartLng:
          (json['passengerStartLng'] as num?)?.toDouble() ?? 0.0,
      passengerEndLat: (json['passengerEndLat'] as num?)?.toDouble() ?? 0.0,
      passengerEndLng: (json['passengerEndLng'] as num?)?.toDouble() ?? 0.0,
      startCity: json['startCity'] as String?,
      endCity: json['endCity'] as String?,
      passengerRideDistance:
          (json['passengerRideDistance'] as num?)?.toDouble() ?? 0.0,
      passengerCost: (json['passengerCost'] as num?)?.toDouble(),
      status: json['status'] as String?,
      createdDate: json['createdDate']?.toString(),
    );
  }
}

