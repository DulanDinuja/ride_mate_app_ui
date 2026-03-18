import 'dart:typed_data';

/// Accumulates all data collected during the multi-screen driver registration flow.
/// Passed between screens as a route argument.
class DriverRegistrationData {
  // ─── Vehicle Registration Screen ──────────────────────────────────
  int? vehicleTypeId;
  int? vehicleMakeId;
  int? vehicleModelId;
  String? model;
  String? registrationNumber;
  int? year;
  String? color;

  // ─── Vehicle Photos Upload Screen ─────────────────────────────────
  Uint8List? vehicleImageBytes1;
  Uint8List? vehicleImageBytes2;
  Uint8List? vehicleImageBytes3;
  Uint8List? vehicleImageBytes4;

  // ─── Driving License Upload Screen ────────────────────────────────
  String? driverLicenseNumber;
  String? driverLicenseExpiry;
  Uint8List? driverLicenseFrontBytes;
  Uint8List? driverLicenseBackBytes;

  // ─── Vehicle Insurance Upload Screen ──────────────────────────────
  String? insuranceNumber;
  String? insuranceProvider;
  String? insuranceExpiry;
  Uint8List? insuranceDocumentFrontBytes;
  Uint8List? insuranceDocumentBackBytes;

  // ─── Revenue License Upload Screen ────────────────────────────────
  Uint8List? registrationCertificateBytes;
  Uint8List? revenueLicenseFrontBytes;
  Uint8List? revenueLicenseBackBytes;

  DriverRegistrationData();

  /// Builds the JSON body for POST /driver-profile/save/{userId}
  Map<String, dynamic> toSaveBody({
    required int driverLicenseFrontDocumentId,
    required int driverLicenseBackDocumentId,
    required int vehicleImageDocumentId1,
    required int vehicleImageDocumentId2,
    required int vehicleImageDocumentId3,
    required int vehicleImageDocumentId4,
    required int registrationCertificateDocumentId,
    required int insuranceDocumentId1,
    required int insuranceDocumentId2,
    required int revenueLicenseDocumentId1,
    required int revenueLicenseDocumentId2,
  }) {
    return {
      'driverLicenseNumber': driverLicenseNumber ?? '',
      'driverLicenseExpiry': driverLicenseExpiry ?? '',
      'driverLicenseFrontDocumentId': driverLicenseFrontDocumentId,
      'driverLicenseBackDocumentId': driverLicenseBackDocumentId,
      'vehicleDetails': {
        'vehicleTypeId': vehicleTypeId ?? 0,
        'vehicleMakeId': vehicleMakeId ?? 0,
        'vehicleModelId': vehicleModelId ?? 0,
        'registrationNumber': registrationNumber ?? '',
        'model': model ?? '',
        'year': year ?? 0,
        'color': color ?? '',
        'vehicleImageDocumentId1': vehicleImageDocumentId1,
        'vehicleImageDocumentId2': vehicleImageDocumentId2,
        'vehicleImageDocumentId3': vehicleImageDocumentId3,
        'vehicleImageDocumentId4': vehicleImageDocumentId4,
        'registrationCertificateDocumentId': registrationCertificateDocumentId,
        'insuranceDocumentId1': insuranceDocumentId1,
        'insuranceDocumentId2': insuranceDocumentId2,
        'insuranceNumber': insuranceNumber ?? '',
        'insuranceProvider': insuranceProvider ?? '',
        'insuranceExpiry': insuranceExpiry ?? '',
        'revenueLicenseDocumentId1': revenueLicenseDocumentId1,
        'revenueLicenseDocumentId2': revenueLicenseDocumentId2,
      },
    };
  }
}
