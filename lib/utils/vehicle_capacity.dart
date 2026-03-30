/// Utility to derive the maximum passenger capacity from a vehicle type name.
///
/// Rules (as per product spec):
///   BIKE / MOTORCYCLE / TWO-WHEELER  → 1 passenger
///   TUK / THREE-WHEELER              → 3 passengers
///   CAR / SEDAN / HATCHBACK / SUV
///   CROSSOVER / COUPE / WAGON        → 4 passengers
///   VAN / MINIVAN / MINIBUS          → 6 passengers
///   BUS                              → 10 passengers
///   Default (unknown)                → 3 passengers
class VehicleCapacityUtils {
  VehicleCapacityUtils._();

  /// Returns the maximum number of passengers (not counting the driver)
  /// allowed for [vehicleTypeName].
  static int maxSeats(String? vehicleTypeName) {
    if (vehicleTypeName == null || vehicleTypeName.trim().isEmpty) return 3;

    final name = vehicleTypeName.trim().toUpperCase();

    // ── Two-wheelers ──────────────────────────────────────────────
    if (_containsAny(name, ['BIKE', 'MOTORCYCLE', 'MOTORBIKE', 'TWO WHEEL', 'TWO-WHEEL', 'TWOWHEEL', 'SCOOTER', 'MOPED'])) {
      return 1;
    }

    // ── Three-wheelers / Tuk ──────────────────────────────────────
    if (_containsAny(name, ['TUK', 'THREE WHEEL', 'THREE-WHEEL', 'THREEWHEEL', 'TRISHAW', 'AUTO RICK', 'AUTORICK'])) {
      return 3;
    }

    // ── Vans / Minibuses ──────────────────────────────────────────
    if (_containsAny(name, ['VAN', 'MINIVAN', 'MINIBUS', 'MICRO'])) {
      return 6;
    }

    // ── Buses ─────────────────────────────────────────────────────
    if (_containsAny(name, ['BUS', 'COACH'])) {
      return 10;
    }

    // ── Cars (broad fallback after more-specific checks) ──────────
    if (_containsAny(name, ['CAR', 'SEDAN', 'HATCHBACK', 'SUV', 'CROSSOVER', 'COUPE', 'WAGON', 'PICKUP', 'JEEP', 'FOUR WHEEL', 'FOUR-WHEEL'])) {
      return 4;
    }

    // Default — treat as a small car
    return 3;
  }

  /// Returns a human-readable label for the vehicle type (used in UI).
  static String vehicleLabel(String? vehicleTypeName) {
    if (vehicleTypeName == null || vehicleTypeName.trim().isEmpty) return 'Vehicle';
    return vehicleTypeName
        .trim()
        .split(RegExp(r'[\s_]+'))
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  /// Returns the appropriate icon for the vehicle type.
  static const Map<String, String> _typeIconMap = {
    'BIKE': '🏍️',
    'MOTORCYCLE': '🏍️',
    'TUK': '🛺',
    'THREE': '🛺',
    'CAR': '🚗',
    'VAN': '🚐',
    'BUS': '🚌',
  };

  static String vehicleEmoji(String? vehicleTypeName) {
    if (vehicleTypeName == null || vehicleTypeName.trim().isEmpty) return '🚗';
    final upper = vehicleTypeName.trim().toUpperCase();
    for (final entry in _typeIconMap.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    return '🚗';
  }

  static bool _containsAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));
}

