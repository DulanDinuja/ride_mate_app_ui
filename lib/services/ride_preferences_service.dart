import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gender preference for ride matching.
enum GenderPreference {
  both,
  male,
  female;

  String get label {
    switch (this) {
      case GenderPreference.both:
        return 'Both';
      case GenderPreference.male:
        return 'Male Only';
      case GenderPreference.female:
        return 'Female Only';
    }
  }

  String get shortLabel {
    switch (this) {
      case GenderPreference.both:
        return 'Both';
      case GenderPreference.male:
        return 'Male';
      case GenderPreference.female:
        return 'Female';
    }
  }

  String get storageKey => name.toUpperCase(); // BOTH, MALE, FEMALE

  static GenderPreference fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'MALE':
        return GenderPreference.male;
      case 'FEMALE':
        return GenderPreference.female;
      default:
        return GenderPreference.both;
    }
  }
}

/// Stores and retrieves ride preferences locally using secure storage.
class RidePreferencesService {
  static const _storage = FlutterSecureStorage();
  static const _keyGender = 'ride_pref_gender';

  /// Save the gender preference.
  static Future<void> saveGenderPreference(GenderPreference pref) async {
    await _storage.write(key: _keyGender, value: pref.storageKey);
  }

  /// Load the gender preference. Returns [GenderPreference.both] if not set.
  static Future<GenderPreference> loadGenderPreference() async {
    final value = await _storage.read(key: _keyGender);
    return GenderPreference.fromString(value);
  }
}

