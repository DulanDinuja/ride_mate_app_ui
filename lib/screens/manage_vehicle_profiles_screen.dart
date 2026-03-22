import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/routes/app_routes.dart';
import '../widgets/custom_back_button.dart';
import '../services/vehicle_service.dart';
import '../services/driver_service.dart';
import '../services/token_service.dart';

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
  bool _isUpdating = false;
  String? _errorMessage;
  Map<String, dynamic>? _vehicleData;
  List<Map<String, dynamic>> _vehicles = [];

  // Controllers for editable fields
  final Map<int, TextEditingController> _registrationControllers = {};
  final Map<int, TextEditingController> _modelControllers = {};
  final Map<int, TextEditingController> _yearControllers = {};
  final Map<int, TextEditingController> _colorControllers = {};
  final Map<int, TextEditingController> _seatsControllers = {};
  final Map<int, bool> _isPrimaryValues = {};

  @override
  void initState() {
    super.initState();
    _loadVehicleProfiles();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _registrationControllers.values) {
      controller.dispose();
    }
    for (var controller in _modelControllers.values) {
      controller.dispose();
    }
    for (var controller in _yearControllers.values) {
      controller.dispose();
    }
    for (var controller in _colorControllers.values) {
      controller.dispose();
    }
    for (var controller in _seatsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadVehicleProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get driver profile ID
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

        // Initialize controllers for each vehicle
        for (var vehicle in _vehicles) {
          final id = vehicle['id'] as int;
          _registrationControllers[id] = TextEditingController(
            text: vehicle['registrationNumber']?.toString() ?? '',
          );
          _modelControllers[id] = TextEditingController(
            text: vehicle['model']?.toString() ?? '',
          );
          _yearControllers[id] = TextEditingController(
            text: vehicle['year']?.toString() ?? '',
          );
          _colorControllers[id] = TextEditingController(
            text: vehicle['color']?.toString() ?? '',
          );
          _seatsControllers[id] = TextEditingController(
            text: vehicle['seats']?.toString() ?? '',
          );
          _isPrimaryValues[id] = vehicle['isPrimary']?.toString().toUpperCase() == 'YES';
        }
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
        // Header card
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Vehicle list
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
    final vehicleId = vehicle['id'] as int;
    final vehicleTypeName = vehicle['vehicleTypeName']?.toString() ?? 'N/A';
    final vehicleMakeName = vehicle['vehicleMakeName']?.toString() ?? 'N/A';
    final vehicleModelName = vehicle['vehicleModelName']?.toString() ?? 'N/A';
    final status = vehicle['status']?.toString() ?? 'PENDING';
    final isVerified = vehicle['isVerified']?.toString().toUpperCase() == 'YES';

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
          // Vehicle header
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

          // Editable fields
          _buildTextField(
            label: 'Registration Number',
            controller: _registrationControllers[vehicleId]!,
            icon: Icons.confirmation_number_outlined,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Model',
            controller: _modelControllers[vehicleId]!,
            icon: Icons.car_rental,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Year',
            controller: _yearControllers[vehicleId]!,
            icon: Icons.calendar_today,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Color',
            controller: _colorControllers[vehicleId]!,
            icon: Icons.palette_outlined,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Seats',
            controller: _seatsControllers[vehicleId]!,
            icon: Icons.event_seat,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),

          // Primary vehicle toggle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_outline, color: _accent, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Set as Primary Vehicle',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                ),
                Switch(
                  value: _isPrimaryValues[vehicleId] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _isPrimaryValues[vehicleId] = value;
                    });
                  },
                  activeColor: _accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: _navy),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : () => _updateVehicle(vehicleId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    disabledBackgroundColor: _accent.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Update',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _accent, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _updateVehicle(int vehicleId) async {
    setState(() => _isUpdating = true);

    try {
      final body = {
        'registrationNumber': _registrationControllers[vehicleId]!.text.trim(),
        'model': _modelControllers[vehicleId]!.text.trim(),
        'year': int.tryParse(_yearControllers[vehicleId]!.text.trim()) ?? 0,
        'color': _colorControllers[vehicleId]!.text.trim(),
        'seats': int.tryParse(_seatsControllers[vehicleId]!.text.trim()) ?? 0,
        'isPrimary': _isPrimaryValues[vehicleId] == true ? 'YES' : 'NO',
      };

      await VehicleService.updateVehicle(vehicleId: vehicleId, body: body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle updated successfully!'),
          backgroundColor: _accent,
        ),
      );

      // Reload vehicles
      await _loadVehicleProfiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _onAddVehicle() {
    Navigator.pushNamed(context, AppRoutes.vehicleRegistration);
  }
}
