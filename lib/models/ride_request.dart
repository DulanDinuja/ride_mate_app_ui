/// Model for a ride request (passenger → driver).
/// Matches backend RideRequestResponse.
class RideRequest {
  final int id;
  final int rideDetailId;
  final int userId;
  final String passengerFirstName;
  final String passengerLastName;
  final String? passengerEmail;
  final String? passengerPhone;
  final String? passengerProfileImageUrl;
  final double passengerStartLat;
  final double passengerStartLng;
  final double passengerEndLat;
  final double passengerEndLng;
  final String? startCity;
  final String? endCity;
  final double passengerRideDistance;
  final String status;
  final String? createdDate;

  const RideRequest({
    required this.id,
    required this.rideDetailId,
    required this.userId,
    required this.passengerFirstName,
    required this.passengerLastName,
    this.passengerEmail,
    this.passengerPhone,
    this.passengerProfileImageUrl,
    required this.passengerStartLat,
    required this.passengerStartLng,
    required this.passengerEndLat,
    required this.passengerEndLng,
    this.startCity,
    this.endCity,
    required this.passengerRideDistance,
    required this.status,
    this.createdDate,
  });

  String get passengerFullName => '$passengerFirstName $passengerLastName';

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isRejected => status == 'REJECTED';

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] as int,
      rideDetailId: json['rideDetailId'] as int,
      userId: json['userId'] as int,
      passengerFirstName: json['passengerFirstName'] as String? ?? '',
      passengerLastName: json['passengerLastName'] as String? ?? '',
      passengerEmail: json['passengerEmail'] as String?,
      passengerPhone: json['passengerPhone'] as String?,
      passengerProfileImageUrl: json['passengerProfileImageUrl'] as String?,
      passengerStartLat: (json['passengerStartLat'] as num?)?.toDouble() ?? 0.0,
      passengerStartLng: (json['passengerStartLng'] as num?)?.toDouble() ?? 0.0,
      passengerEndLat: (json['passengerEndLat'] as num?)?.toDouble() ?? 0.0,
      passengerEndLng: (json['passengerEndLng'] as num?)?.toDouble() ?? 0.0,
      startCity: json['startCity'] as String?,
      endCity: json['endCity'] as String?,
      passengerRideDistance: (json['passengerRideDistance'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      createdDate: json['createdDate'] as String?,
    );
  }
}

