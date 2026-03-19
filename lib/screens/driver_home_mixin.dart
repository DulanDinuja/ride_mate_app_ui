import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/routes/app_routes.dart';
import '../models/driver_profile.dart';
import '../models/ride_detail_request.dart';
import '../models/ride_price_calculation_response.dart';
import '../models/user_profile.dart';
import '../services/driver_service.dart';
import '../services/ride_service.dart';
import '../services/token_service.dart';
import '../services/user_service.dart';
import 'user_home_map_screen.dart';

/// Mixin that encapsulates all driver-specific state, logic, and widgets
/// for [UserHomeMapScreen]. The host State must implement the two abstract
/// getters so the mixin can read shared state without reaching into private
/// fields.
mixin DriverHomeMixin on State<UserHomeMapScreen> {
  // ── interface: host must provide ──────────────────────────────────
  UserProfile? get currentUserProfile;
  LatLng? get currentDropLatLng;
  LatLng? get currentPickupLatLng;
  String get currentPickupAddress;
  String get currentDropAddress;
  double? get currentRouteDistanceKm;
  List<LatLng> get currentRoutePoints;

  // ── driver state ─────────────────────────────────────────────────
  bool isDriverAvailable = false;
  DriverProfile? driverProfile;
  int driverAvailableSeats = 1;
  final TextEditingController driverNoteController = TextEditingController();
  bool showDriverProfileCard = false;
  bool isOfferingRide = false;
  RidePriceCalculationResponse? ridePrice;
  int? activeRideDetailId;

  /// Whether the current user has the DRIVER role.
  bool get isDriver => currentUserProfile?.role.toUpperCase() == 'DRIVER';

  // ── lifecycle helpers ────────────────────────────────────────────

  /// Call from the host's [dispose].
  void disposeDriverState() {
    driverNoteController.dispose();
  }

  /// Reset driver state when switching back to passenger.
  void resetDriverState() {
    setState(() {
      isDriverAvailable = false;
      driverProfile = null;
      driverAvailableSeats = 1;
      driverNoteController.clear();
    });
  }

  // ── driver data helpers ──────────────────────────────────────────

  /// Fetch the driver profile (vehicle type, etc.).
  Future<void> fetchDriverProfile(String userId) async {
    try {
      final profile = await DriverService.getDriverProfileByUserId(userId);
      if (mounted) setState(() => driverProfile = profile);
    } catch (_) {}
  }

  /// Show the "Complete Driver Profile" card if the profile is incomplete.
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

  /// Offer-ride action for drivers.
  /// 1. Calculate price from backend
  /// 2. Create ride detail
  /// 3. Navigate to active ride screen
  Future<void> onOfferRide() async {
    if (currentDropLatLng == null || currentPickupLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please set a destination first.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    if (driverProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Driver profile not loaded. Please try again.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final distance = currentRouteDistanceKm;
    if (distance == null || distance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please wait for route to be calculated.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => isOfferingRide = true);

    try {
      // Step 1: Calculate price
      final priceResponse = await RideService.calculateRidePrice(
        driverProfileId: driverProfile!.id,
        totalDistance: distance,
      );

      if (!mounted) return;
      setState(() => ridePrice = priceResponse);

      // Step 2: Create ride detail
      // Encode the route polyline as a JSON array of [lat, lng] pairs
      String? tripRoute;
      final routePoints = currentRoutePoints;
      if (routePoints.isNotEmpty) {
        tripRoute = json.encode(
          routePoints.map((p) => [p.latitude, p.longitude]).toList(),
        );
      }

      final request = RideDetailRequest(
        driverProfileId: driverProfile!.id,
        startLocationLatitude: currentPickupLatLng!.latitude,
        startLocationLongitude: currentPickupLatLng!.longitude,
        endLocationLatitude: currentDropLatLng!.latitude,
        endLocationLongitude: currentDropLatLng!.longitude,
        startCity: currentPickupAddress,
        availableSeats: driverAvailableSeats,
        startTime: DateTime.now().toIso8601String(),
        totalRideDistance: distance,
        tripRoute: tripRoute,
        status: 'ACTIVE',
        totalRideCost: priceResponse.totalRidePrice ?? 0,
        perKmRate: priceResponse.perKmRate,
      );

      final result = await RideService.createRideDetail(request);
      final rideId = result['id'] as int?;

      if (!mounted) return;

      if (rideId == null) {
        throw Exception('Ride created but no ID returned');
      }

      setState(() => activeRideDetailId = rideId);

      // Step 3: Navigate to active ride screen
      Navigator.pushNamed(
        context,
        AppRoutes.activeRide,
        arguments: {
          'rideDetailId': rideId,
          'pickupAddress': currentPickupAddress,
          'dropAddress': currentDropAddress,
          'totalDistance': distance,
          'totalCost': priceResponse.totalRidePrice ?? 0,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red.shade700,
      ));
    } finally {
      if (mounted) setState(() => isOfferingRide = false);
    }
  }

  // ── routing helpers ──────────────────────────────────────────────

  /// Route polyline colour based on vehicle type.
  Color get driverRouteColor =>
      (isDriver && (driverProfile?.isTwoWheeler ?? false))
          ? const Color(0xFF2196F3)
          : const Color(0xFF03AF74);

  /// Google Directions travel mode based on vehicle type.
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
