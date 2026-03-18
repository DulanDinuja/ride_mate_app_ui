import 'dart:typed_data';

/// Accumulates all data collected during the multi-screen driver registration flow.
/// Passed between screens as a route argument.
class DriverRegistrationData {
  // ─── Vehicle Registration Screen ──────────────────────────────────
  int? vehicleTypeId;
  int? vehicleMakeId;
  String? vehicleModelId;
  String? registrationNumber;
  int? year;
  String? color;

  // ─── Vehicle Photos Upload Screen ─────────────────────────────────
  Uint8List? vehicleImageBytes;

  // ─── Driving License Upload Screen ────────────────────────────────
  String? driverLicenseNumber;
  String? driverLicenseExpiry;
  Uint8List? driverLicenseFrontBytes;
  Uint8List? driverLicenseBackBytes;

  // ─── Vehicle Insurance Upload Screen ──────────────────────────────
  String? insuranceNumber;
  String? insuranceProvider;
  String? insuranceExpiry;
  Uint8List? insuranceDocumentBytes;

  // ─── Revenue License Upload Screen ────────────────────────────────
  Uint8List? registrationCertificateBytes;

  DriverRegistrationData();

  /// Builds the JSON body for POST /driver-profile/save/{userId}
  Map<String, dynamic> toSaveBody({
    required int driverLicenseFrontDocumentId,
    required int driverLicenseBackDocumentId,
    required int vehicleImageDocumentId,
    required int registrationCertificateDocumentId,
    required int insuranceDocumentId,
  }) {
    return {
      'driverLicenseNumber': driverLicenseNumber ?? '',
      'driverLicenseExpiry': driverLicenseExpiry ?? '',
      'driverLicenseFrontDocumentId': driverLicenseFrontDocumentId,
      'driverLicenseBackDocumentId': driverLicenseBackDocumentId,
      'vehicleDetails': {
        'vehicleTypeId': vehicleTypeId ?? 0,
        'vehicleMakeId': vehicleMakeId ?? 0,
        'registrationNumber': registrationNumber ?? '',
        'vehicleModelId': vehicleModelId ?? '',
        'year': year ?? 0,
        'color': color ?? '',
        'vehicleImageDocumentId': vehicleImageDocumentId,
        'registrationCertificateDocumentId': registrationCertificateDocumentId,
        'insuranceNumber': insuranceNumber ?? '',
        'insuranceProvider': insuranceProvider ?? '',
        'insuranceExpiry': insuranceExpiry ?? '',
        'insuranceDocumentId': insuranceDocumentId,
      },
    };
  }
}
