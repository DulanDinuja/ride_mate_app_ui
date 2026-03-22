import 'package:flutter/material.dart';
import '../core/routes/app_routes.dart';
import '../widgets/custom_back_button.dart';
import '../services/vehicle_service.dart';
import '../services/driver_service.dart';
import '../services/token_service.dart';
import 'update_vehicle_screen.dart';

class ManageVehicleProfilesScreen extends StatefulWidget {
  const ManageVehicleProfilesScreen({super.key});

  @override
  State<ManageVehicleProfilesScreen> createState() => _ManageVehicleProfilesScreenState();
}

class _ManageVehicleProfilesScreenState extends State<ManageVehicleProfilesScreen> {
  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);
  static const Color _creamBg = Color(0xFFFFFFF0);

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _vehicleData;
  List<Map<String, dynamic>> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicleProfiles();
  }

  Future<void> _loadVehicleProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = await TokenService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final driverProfile = await DriverService.getDriverProfileByUserId(userId);
      final vehicleData = await VehicleService.getDriverVehicles(driverProfile.id);

      if (!mounted) return;

      setState(() {
        _vehicleData = vehicleData;
        _vehicles = (vehicleData['vehicles'] as List<dynamic>)
            .map((v) => v as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _creamBg,
      appBar: AppBar(
        leading: CustomBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manage Vehicle Profiles'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _accent),
            )
          : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddVehicle,
        backgroundColor: _accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Vehicle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadVehicleProfiles,
                style: ElevatedButton.styleFrom(backgroundColor: _accent),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_vehicles.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_navy, Color(0xFF0A1F35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: _accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Vehicles',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_vehicleData?['totalVehicles'] ?? 0} vehicle(s)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ..._vehicles.map((vehicle) => _buildVehicleCard(vehicle)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.1),
              ),
              child: Icon(
                Icons.directions_car_outlined,
                size: 50,
                color: _accent.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Vehicles Added',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first vehicle to start\noffering rides as a driver',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onAddVehicle,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Your First Vehicle',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final vehicleTypeName = vehicle['vehicleTypeName']?.toString() ?? 'N/A';
    final vehicleMakeName = vehicle['vehicleMakeName']?.toString() ?? 'N/A';
    final vehicleModelName = vehicle['vehicleModelName']?.toString() ?? 'N/A';
    final registrationNumber = vehicle['registrationNumber']?.toString() ?? 'N/A';
    final year = vehicle['year']?.toString() ?? 'N/A';
    final color = vehicle['color']?.toString() ?? 'N/A';
    final seats = vehicle['seats']?.toString() ?? 'N/A';
    final status = vehicle['status']?.toString() ?? 'PENDING';
    final isVerified = vehicle['isVerified']?.toString().toUpperCase() == 'YES';
    final isPrimary = vehicle['isPrimary']?.toString().toUpperCase() == 'YES';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car, color: _accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$vehicleMakeName $vehicleModelName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicleTypeName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified ? _accent.withOpacity(0.1) : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isVerified ? _accent : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.confirmation_number_outlined, 'Registration', registrationNumber),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.calendar_today, 'Year', year),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.palette_outlined, 'Color', color),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.event_seat, 'Seats', seats),
          const SizedBox(height: 16),
          if (isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _accent.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: _accent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Primary Vehicle',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToUpdateVehicle(vehicle),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text(
                'Update Vehicle',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _navy,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToUpdateVehicle(Map<String, dynamic> vehicle) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateVehicleScreen(vehicleData: vehicle),
      ),
    );

    if (result == true) {
      _loadVehicleProfiles();
    }
  }

  void _onAddVehicle() {
    Navigator.pushNamed(context, AppRoutes.vehicleRegistration);
  }
}
