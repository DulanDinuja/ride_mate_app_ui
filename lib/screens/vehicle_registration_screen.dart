import 'package:flutter/material.dart';
import '../core/routes/app_routes.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() => _VehicleRegistrationScreenState();
}

enum VehicleType { bike, tuk, car, van }

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final TextEditingController _registrationController =
      TextEditingController(text: 'CAR-1515');

  final List<String> _makes = const ['Toyota', 'Suzuki', 'Honda', 'Nissan'];
  final List<String> _models = const ['Yaris', 'Prius', 'Alto', 'WagonR'];
  final List<String> _years = const ['2025', '2024', '2023', '2022'];
  final List<String> _colours = const ['Black', 'White', 'Silver', 'Blue'];

  VehicleType _selectedVehicleType = VehicleType.car;
  String _selectedMake = 'Toyota';
  String _selectedModel = 'Yaris';
  String _selectedYear = '2025';
  String _selectedColour = 'Black';

  static const Color _screenBackground = Colors.black;
  static const Color _panelBackground = Color(0xFFFFFFF0);
  static const Color _fieldBackground = Color(0xFFE9E9DC);
  static const Color _textPrimary = Color(0xFF44526A);
  static const Color _textDark = Color(0xFF121A2C);
  static const Color _accent = Color(0xFF10B47A);
  static const Color _muted = Color(0xFFB5B6B8);
  static const Color _buttonDark = Color(0xFF061324);

  @override
  void dispose() {
    _registrationController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_registrationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter registration number')),
      );
      return;
    }

    Navigator.of(context).pushNamed(AppRoutes.vehiclePhotosUpload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _panelBackground,
              borderRadius: BorderRadius.circular(48),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildStepper(),
                  const SizedBox(height: 38),
                  const Text(
                    'Choose your Vehicle',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _VehicleTypeCard(
                          label: 'Bike',
                          icon: Icons.two_wheeler_rounded,
                          isSelected: _selectedVehicleType == VehicleType.bike,
                          onTap: () => setState(() => _selectedVehicleType = VehicleType.bike),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _VehicleTypeCard(
                          label: 'Tuk',
                          icon: Icons.electric_rickshaw_rounded,
                          isSelected: _selectedVehicleType == VehicleType.tuk,
                          onTap: () => setState(() => _selectedVehicleType = VehicleType.tuk),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _VehicleTypeCard(
                          label: 'Car',
                          icon: Icons.directions_car_filled_rounded,
                          isSelected: _selectedVehicleType == VehicleType.car,
                          onTap: () => setState(() => _selectedVehicleType = VehicleType.car),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _VehicleTypeCard(
                          label: 'Van',
                          icon: Icons.airport_shuttle_rounded,
                          isSelected: _selectedVehicleType == VehicleType.van,
                          onTap: () => setState(() => _selectedVehicleType = VehicleType.van),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Make',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownField(
                    value: _selectedMake,
                    items: _makes,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedMake = value);
                    },
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Model',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownField(
                    value: _selectedModel,
                    items: _models,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedModel = value);
                    },
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Year of Manufacture',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w500,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDropdownField(
                              value: _selectedYear,
                              items: _years,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedYear = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Colour',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w500,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDropdownField(
                              value: _selectedColour,
                              items: _colours,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedColour = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Registration No (Number Plate)',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _registrationController,
                    style: const TextStyle(
                      fontSize: 17,
                      color: _textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'CAR-1515',
                      hintStyle: const TextStyle(color: Color(0xFF9AA0AA)),
                      filled: true,
                      fillColor: _fieldBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: _accent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: _textPrimary,
                      ),
                      children: [
                        TextSpan(text: 'By continuing, I agree to the '),
                        TextSpan(
                          text: 'RideMate Terms of Service',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text:
                              ' and consent to disclose certain personal information to RideMate passengers under the ',
                        ),
                        TextSpan(
                          text: 'RideMate Privacy Policy',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            children: [
              _StepCircle(number: '1'),
              Expanded(
                child: Divider(
                  color: _accent,
                  thickness: 4,
                  height: 4,
                ),
              ),
              _StepCircle(number: '2'),
            ],
          ),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  'Personal\nDetails',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: _muted,
                    height: 1.35,
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  'Vehical\nDetails',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: _textDark,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFFB5B6B8),
        size: 32,
      ),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: _fieldBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
      style: const TextStyle(
        fontSize: 17,
        color: Color(0xFF8F95A1),
        fontWeight: FontWeight.w400,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: const BoxDecoration(
        color: _VehicleRegistrationScreenState._accent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _VehicleTypeCard extends StatelessWidget {
  const _VehicleTypeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B47A) : const Color(0xFFE9E9DC),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? Colors.white : const Color(0xFF121A2C),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF121A2C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

