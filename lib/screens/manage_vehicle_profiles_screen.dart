import 'package:flutter/material.dart';
import '../widgets/custom_back_button.dart';

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

  @override
  void initState() {
    super.initState();
    _loadVehicleProfiles();
  }

  Future<void> _loadVehicleProfiles() async {
    setState(() => _isLoading = true);
    // TODO: Load vehicle profiles from API
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _isLoading = false);
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Vehicles',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage your vehicle profiles',
                          style: TextStyle(
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

        // Empty state or vehicle list
        _buildEmptyState(),
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

  void _onAddVehicle() {
    // TODO: Navigate to add vehicle screen or show dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add vehicle functionality coming soon'),
        backgroundColor: _accent,
      ),
    );
  }
}
