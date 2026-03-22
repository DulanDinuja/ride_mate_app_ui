import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/routes/app_routes.dart';
import '../models/driver_profile.dart';
import '../models/ride_detail_request.dart';
import '../models/ride_price_calculation_response.dart';
import '../models/user_profile.dart';
import '../models/driver_vehicles_response.dart';
import '../services/driver_service.dart';
import '../services/ride_service.dart';
import '../services/token_service.dart';
import '../services/user_service.dart';
import 'ride_start_screen.dart';
import 'user_home_map_screen.dart';

/// Mixin that encapsulates all driver-specific state, logic, and widgets
/// for [UserHomeMapScreen]. The host State must implement the abstract
/// getters so the mixin can read shared state without reaching into private fields.
mixin DriverHomeMixin on State<UserHomeMapScreen> {
  // ── interface: host must provide ──────────────────────────────────
  UserProfile? get currentUserProfile;
  LatLng? get currentPickupLatLng;
  LatLng? get currentDropLatLng;
  String get currentPickupAddress;
  String get currentDropAddress;
  double? get currentRouteDistanceKm;
  String? get currentRouteDuration;
  List<LatLng> get currentPolylinePoints;

  /// Called when backend says "already have an active ride" — host should
  /// switch to the Active Rides tab.
  void onActiveRideConflict();

  // ── driver state ─────────────────────────────────────────────────
  bool isDriverAvailable = false;
  bool _isOfferingRide = false;
  bool get isOfferingRide => _isOfferingRide;
  DriverProfile? driverProfile;
  int driverAvailableSeats = 1;
  final TextEditingController driverNoteController = TextEditingController();
  bool showDriverProfileCard = false;
  RidePriceCalculationResponse? ridePrice;
  int? activeRideDetailId;

  // ── vehicle selection state ──────────────────────────────────────
  List<DriverVehicle> _driverVehicles = [];
  DriverVehicle? _selectedVehicle;
  bool _isLoadingVehicles = false;

  bool get hasMultipleDriverVehicles => _driverVehicles.length > 1;
  DriverVehicle? get selectedVehicle => _selectedVehicle;

  /// Whether the current user has the DRIVER role.
  bool get isDriver => currentUserProfile?.role.toUpperCase() == 'DRIVER';

  // ── lifecycle helpers ────────────────────────────────────────────

  void disposeDriverState() {
    driverNoteController.dispose();
  }

  void resetDriverState() {
    setState(() {
      isDriverAvailable = false;
      driverProfile = null;
      driverAvailableSeats = 1;
      driverNoteController.clear();
    });
  }

  // ── driver data helpers ──────────────────────────────────────────

  Future<void> fetchDriverProfile(String userId) async {
    try {
      final profile = await DriverService.getDriverProfileByUserId(userId);
      if (mounted) setState(() => driverProfile = profile);
    } catch (e) {
      debugPrint('[DriverMixin] fetchDriverProfile error: $e');
    }
  }

  Future<void> checkDriverProfileStatus(String userId) async {
    try {
      final dp = await DriverService.getDriverProfileByUserId(userId);
      if (mounted && !dp.isDriverProfileCompleted) {
        setState(() => showDriverProfileCard = true);
      }
    } catch (_) {
      if (mounted) setState(() => showDriverProfileCard = true);
    }
  }

  /// Load vehicles for the driver and pre-select the primary one.
  /// Should be called after [fetchDriverProfile] when the user is in Driver mode.
  Future<void> loadDriverVehicles(int driverProfileId) async {
    if (_isLoadingVehicles) return;
    setState(() => _isLoadingVehicles = true);
    try {
      final resp = await DriverService.getDriverVehicles(driverProfileId);
      if (!mounted) return;
      // Find primary vehicle or fall back to first
      DriverVehicle? primary;
      if (resp.vehicles.isNotEmpty) {
        try {
          primary = resp.vehicles.firstWhere((v) => v.isPrimary == 'YES');
        } catch (_) {
          primary = resp.vehicles.first;
        }
      }
      setState(() {
        _driverVehicles = resp.vehicles;
        _selectedVehicle = primary;
      });
    } catch (e) {
      debugPrint('[DriverMixin] loadDriverVehicles error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingVehicles = false);
    }
  }

  /// Shows a bottom sheet for the driver to pick a vehicle.
  /// Returns the selected [DriverVehicle], or null if dismissed.
  Future<DriverVehicle?> _pickVehicle(List<DriverVehicle> vehicles) {
    return showModalBottomSheet<DriverVehicle>(
      context: context,
      backgroundColor: const Color(0xFF1A2332),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Vehicle',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...vehicles.map(
              (v) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF03AF74).withOpacity(0.15),
                  ),
                  child: const Icon(Icons.directions_car,
                      color: Color(0xFF03AF74), size: 22),
                ),
                title: Text(
                  '${v.vehicleMakeName} ${v.vehicleModelName}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${v.registrationNumber} · ${v.color} · ${v.year}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: v.isPrimary == 'YES'
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF03AF74).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Primary',
                            style: TextStyle(
                                color: Color(0xFF03AF74),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      )
                    : null,
                onTap: () => Navigator.pop(ctx, v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Offer-ride: check vehicles → calculate price → create ride → navigate.
  Future<void> onOfferRide() async {
    final pickup = currentPickupLatLng;
    final drop = currentDropLatLng;
    final dp = driverProfile;
    final distanceKm = currentRouteDistanceKm;
    final duration = currentRouteDuration;

    if (pickup == null || drop == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please set pickup and destination first.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (dp == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Driver profile not loaded. Please try again.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (distanceKm == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Route not calculated yet. Please wait.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isOfferingRide = true);
    try {
      // 0. Use pre-selected vehicle from the ride panel selector.
      //    If somehow no vehicle is selected but driver has multiple, show picker as fallback.
      int? selectedVehicleId = _selectedVehicle?.id;
      if (_driverVehicles.length > 1 && _selectedVehicle == null) {
        if (!mounted) return;
        setState(() => _isOfferingRide = false);
        final picked = await _pickVehicle(_driverVehicles);
        if (!mounted) return;
        if (picked == null) return; // user dismissed
        selectedVehicleId = picked.id;
        setState(() {
          _selectedVehicle = picked;
          _isOfferingRide = true;
        });
      }

      // 1. Calculate price
      final priceResp = await RideService.calculateRidePrice(
        driverProfileId: dp.id,
        totalDistance: distanceKm,
      );

      // 2. Create ride detail
      final note = driverNoteController.text.trim();
      final tripRoute = note.isNotEmpty
          ? note
          : '$currentPickupAddress -> $currentDropAddress';

      // Backend expects millisecond-precision ISO-8601 (no microseconds)
      final now = DateTime.now();
      final startTime =
          '${now.toIso8601String().split('.').first}.${now.millisecond.toString().padLeft(3, '0')}';

      final request = RideDetailRequest(
        driverProfileId: dp.id,
        startLocationLatitude: pickup.latitude,
        startLocationLongitude: pickup.longitude,
        endLocationLatitude: drop.latitude,
        endLocationLongitude: drop.longitude,
        startCity: currentPickupAddress,
        endCity: currentDropAddress,
        availableSeats: driverAvailableSeats,
        startTime: startTime,
        totalRideDistance: distanceKm,
        tripRoute: tripRoute,
        status: 'ACTIVE',
        totalRideCost: priceResp.totalRidePrice ?? 0.0,
        perKmRate: priceResp.perKmRate,
        vehicleId: selectedVehicleId,
      );

      final result = await RideService.createRideDetail(request);
      final rideId = result['id'] as int;

      if (!mounted) return;

      setState(() => activeRideDetailId = rideId);

      // 3. Navigate to RideStartScreen to show trip details
      Navigator.pushNamed(
        context,
        AppRoutes.rideStart,
        arguments: RideStartArgs(
          rideDetailId: rideId,
          driverProfileId: driverProfile?.id,
          pickupAddress: currentPickupAddress,
          dropAddress: currentDropAddress,
          totalCost: priceResp.totalRidePrice ?? 0.0,
          distanceKm: distanceKm,
          perKmRate: priceResp.perKmRate ?? 0.0,
          duration: duration,
          pickupLat: pickup.latitude,
          pickupLng: pickup.longitude,
          dropLat: drop.latitude,
          dropLng: drop.longitude,
          polylinePoints: currentPolylinePoints,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');

      // If backend says driver already has an active ride, notify the host
      if (msg.toLowerCase().contains('already have an active ride')) {
        onActiveRideConflict();
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
      ));
    } finally {
      if (mounted) setState(() => _isOfferingRide = false);
    }
  }

  // ── routing helpers ──────────────────────────────────────────────

  Color get driverRouteColor =>
      (isDriver && (driverProfile?.isTwoWheeler ?? false))
          ? const Color(0xFF2196F3)
          : const Color(0xFF03AF74);

  String get driverGoogleMode =>
      (isDriver && (driverProfile?.isTwoWheeler ?? false))
          ? 'TWO_WHEELER'
          : 'driving';

  // ── driver-specific widgets ──────────────────────────────────────

  Widget buildAvailabilityToggle() {
    return GestureDetector(
      onTap: () => setState(() => isDriverAvailable = !isDriverAvailable),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isDriverAvailable
              ? const Color(0xFF03AF74).withOpacity(0.15)
              : Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDriverAvailable
                ? const Color(0xFF03AF74)
                : Colors.grey.shade400,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDriverAvailable
                    ? const Color(0xFF03AF74)
                    : Colors.grey,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isDriverAvailable ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDriverAvailable
                    ? const Color(0xFF03AF74)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSeatsSelector(ColorScheme scheme, Color border) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF03AF74).withOpacity(0.14),
            ),
            child: const Icon(Icons.event_seat_rounded,
                color: Color(0xFF03AF74), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Available Seats',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface),
            ),
          ),
          GestureDetector(
            onTap: driverAvailableSeats > 1
                ? () => setState(() => driverAvailableSeats--)
                : null,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: driverAvailableSeats > 1
                    ? const Color(0xFF03AF74).withOpacity(0.12)
                    : scheme.onSurfaceVariant.withOpacity(0.08),
              ),
              child: Icon(Icons.remove,
                  size: 16,
                  color: driverAvailableSeats > 1
                      ? const Color(0xFF03AF74)
                      : scheme.onSurfaceVariant.withOpacity(0.4)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$driverAvailableSeats',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF03AF74)),
            ),
          ),
          GestureDetector(
            onTap: driverAvailableSeats < 6
                ? () => setState(() => driverAvailableSeats++)
                : null,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: driverAvailableSeats < 6
                    ? const Color(0xFF03AF74).withOpacity(0.12)
                    : scheme.onSurfaceVariant.withOpacity(0.08),
              ),
              child: Icon(Icons.add,
                  size: 16,
                  color: driverAvailableSeats < 6
                      ? const Color(0xFF03AF74)
                      : scheme.onSurfaceVariant.withOpacity(0.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildNoteField(ColorScheme scheme, Color border) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF03AF74).withOpacity(0.14),
            ),
            child: const Icon(Icons.notes_rounded,
                color: Color(0xFF03AF74), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: driverNoteController,
              maxLines: 1,
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Add a note for passengers...',
                hintStyle: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant.withOpacity(0.6)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Vehicle selector widget shown in the driver ride panel.
  /// If the driver has only one vehicle, shows it as read-only info.
  /// If the driver has multiple vehicles, shows a tappable row that opens the picker.
  Widget buildVehicleSelector(ColorScheme scheme, Color border) {
    if (_isLoadingVehicles) {
      return Container(
        height: 50,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_driverVehicles.isEmpty) return const SizedBox.shrink();

    final vehicle = _selectedVehicle;
    final hasMultiple = _driverVehicles.length > 1;

    return GestureDetector(
      onTap: hasMultiple
          ? () async {
              final picked = await _pickVehicle(_driverVehicles);
              if (picked != null && mounted) {
                setState(() => _selectedVehicle = picked);
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasMultiple
                ? const Color(0xFF03AF74).withOpacity(0.5)
                : border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF03AF74).withOpacity(0.14),
              ),
              child: const Icon(Icons.directions_car,
                  color: Color(0xFF03AF74), size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Vehicle',
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    vehicle != null
                        ? '${vehicle.vehicleMakeName} ${vehicle.vehicleModelName} · ${vehicle.registrationNumber}'
                        : 'Select a vehicle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: vehicle != null
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (hasMultiple) ...[
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF03AF74), size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildDriverBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF03AF74).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'DRIVER',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF03AF74)),
      ),
    );
  }

  Widget buildOfflineHint(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        'Go online to start offering rides',
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
    );
  }

  Widget buildCompleteDriverProfileCard() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
            decoration: BoxDecoration(
              color: const Color(0xFF040F1B).withOpacity(0.7),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () async {
                      setState(() => showDriverProfileCard = false);
                      try {
                        final userId = await TokenService.getUserId();
                        if (userId != null) {
                          await UserService.updateWillingToDrive(userId, 'NO');
                        }
                      } catch (_) {}
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white70, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete Driver Profile',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please complete your driver profile to start accepting rides.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white70),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8 * 0.6,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => showDriverProfileCard = false);
                      Navigator.pushNamed(
                          context, AppRoutes.vehicleRegistration);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03AF74),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Complete Now',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
