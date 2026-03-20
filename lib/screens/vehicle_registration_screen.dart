import 'package:flutter/material.dart';
import '../core/routes/app_routes.dart';
import '../models/driver_registration_data.dart';
import '../models/vehicle_type.dart';
import '../models/vehicle_make.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() => _VehicleRegistrationScreenState();
}

IconData _iconForVehicleCode(String code) {
  switch (code.toUpperCase()) {
    case 'BIKE':
      return Icons.two_wheeler_rounded;
    case 'TUK':
      return Icons.electric_rickshaw_rounded;
    case 'CAR':
      return Icons.directions_car_filled_rounded;
    case 'VAN':
      return Icons.airport_shuttle_rounded;
    default:
      return Icons.directions_car_outlined;
  }
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final TextEditingController _registrationController =
      TextEditingController();

  // API-loaded data
  List<VehicleType> _vehicleTypes = [];
  List<VehicleMake> _vehicleMakes = [];
  List<VehicleModel> _vehicleModels = [];
  bool _isLoadingTypes = true;
  bool _isLoadingMakes = true;
  bool _isLoadingModels = false;
  String? _typesError;
  String? _makesError;
  String? _modelsError;

  VehicleType? _selectedVehicleType;
  VehicleMake? _selectedMake;
  VehicleModel? _selectedModel;

  final List<String> _colours = const ['Black', 'White', 'Silver', 'Blue'];

  int _selectedYear = DateTime.now().year;
  String _selectedColour = 'Black';

  static const Color _screenBackground = Colors.black;
  static const Color _panelBackground = Color(0xFFFFFFF0);
  static const Color _fieldBackground = Color(0xFFE9E9DC);
  static const Color _textPrimary = Color(0xFF44526A);
  static const Color _textDark = Color(0xFF121A2C);
  static const Color _accent = Color(0xFF10B47A);
  static const Color _muted = Color(0xFFB5B6B8);
  static const Color _buttonDark = Color(0xFF061324);

  Future<void> _pickYear() async {
    int tempYear = _selectedYear;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panelBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Select Year', style: TextStyle(color: _textDark, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 200,
          height: 200,
          child: StatefulBuilder(
            builder: (context, setDialogState) => YearPicker(
              firstDate: DateTime(1990),
              lastDate: DateTime.now(),
              selectedDate: DateTime(tempYear),
              onChanged: (date) {
                setDialogState(() => tempYear = date.year);
                setState(() => _selectedYear = date.year);
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
    _loadVehicleMakes();
  }

  Future<void> _loadVehicleTypes() async {
    setState(() {
      _isLoadingTypes = true;
      _typesError = null;
    });
    try {
      final types = await VehicleService.getActiveVehicleTypes();
      if (mounted) {
        setState(() {
          _vehicleTypes = types;
          _isLoadingTypes = false;
          if (types.isNotEmpty) _selectedVehicleType = types.first;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _typesError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingTypes = false;
        });
      }
    }
  }

  Future<void> _loadVehicleMakes() async {
    setState(() {
      _isLoadingMakes = true;
      _makesError = null;
    });
    try {
      final makes = await VehicleService.getVehicleMakesByStatus('ACTIVE');
      if (mounted) {
        setState(() {
          _vehicleMakes = makes;
          _isLoadingMakes = false;
          if (makes.isNotEmpty) {
            _selectedMake = makes.first;
            _loadVehicleModels(makes.first.id);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _makesError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingMakes = false;
        });
      }
    }
  }

  Future<void> _loadVehicleModels(int vehicleMakeId) async {
    setState(() {
      _isLoadingModels = true;
      _modelsError = null;
      _vehicleModels = [];
      _selectedModel = null;
    });
    try {
      final models = await VehicleService.getVehicleModelsByMakeId(vehicleMakeId);
      if (mounted) {
        setState(() {
          _vehicleModels = models;
          _isLoadingModels = false;
          if (models.isNotEmpty) _selectedModel = models.first;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _modelsError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingModels = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _registrationController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_selectedVehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle type')),
      );
      return;
    }
    if (_selectedMake == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle make')),
      );
      return;
    }
    if (_selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle model')),
      );
      return;
    }
    if (_registrationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter registration number')),
      );
      return;
    }

    final data = DriverRegistrationData()
      ..vehicleTypeId = _selectedVehicleType!.id
      ..vehicleMakeId = _selectedMake!.id
      ..vehicleModelId = _selectedModel!.id
      ..model = _selectedModel!.name
      ..registrationNumber = _registrationController.text.trim()
      ..year = _selectedYear
      ..color = _selectedColour;

    Navigator.of(context).pushNamed(
      AppRoutes.vehiclePhotosUpload,
      arguments: data,
    );
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: const Color(0xFF44526A),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
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
                  _buildVehicleTypeSelector(),
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
                  _buildMakeDropdown(),
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
                  _buildModelDropdown(),
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
                            GestureDetector(
                              onTap: _pickYear,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                decoration: BoxDecoration(
                                  color: _fieldBackground,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$_selectedYear',
                                      style: const TextStyle(fontSize: 17, color: Color(0xFF8F95A1)),
                                    ),
                                    const Icon(Icons.calendar_today_rounded, color: Color(0xFFB5B6B8), size: 20),
                                  ],
                                ),
                              ),
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

  Widget _buildVehicleTypeSelector() {
    if (_isLoadingTypes) {
      return const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    if (_typesError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              _typesError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _loadVehicleTypes,
            child: const Text('Retry', style: TextStyle(color: _accent)),
          ),
        ],
      );
    }
    if (_vehicleTypes.isEmpty) {
      return const Text('No vehicle types available.',
          style: TextStyle(color: _textPrimary));
    }

    final children = <Widget>[];
    for (int i = 0; i < _vehicleTypes.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 14));
      final vt = _vehicleTypes[i];
      children.add(
        Expanded(
          child: _VehicleTypeCard(
            label: vt.name,
            icon: _iconForVehicleCode(vt.code),
            isSelected: _selectedVehicleType?.id == vt.id,
            onTap: () => setState(() => _selectedVehicleType = vt),
          ),
        ),
      );
    }
    return Row(children: children);
  }

  Widget _buildMakeDropdown() {
    if (_isLoadingMakes) {
      return const SizedBox(
        height: 62,
        child: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    if (_makesError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              _makesError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _loadVehicleMakes,
            child: const Text('Retry', style: TextStyle(color: _accent)),
          ),
        ],
      );
    }
    if (_vehicleMakes.isEmpty) {
      return const Text('No vehicle makes available.',
          style: TextStyle(color: _textPrimary));
    }

    return DropdownButtonFormField<VehicleMake>(
      value: _selectedMake,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFFB5B6B8),
        size: 32,
      ),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: _fieldBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      items: _vehicleMakes
          .map((m) => DropdownMenuItem<VehicleMake>(
                value: m,
                child: Text(m.name),
              ))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedMake = value);
        _loadVehicleModels(value.id);
      },
    );
  }

  Widget _buildModelDropdown() {
    if (_isLoadingModels) {
      return const SizedBox(
        height: 62,
        child: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    if (_modelsError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              _modelsError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
          if (_selectedMake != null)
            TextButton(
              onPressed: () => _loadVehicleModels(_selectedMake!.id),
              child: const Text('Retry', style: TextStyle(color: _accent)),
            ),
        ],
      );
    }
    if (_vehicleModels.isEmpty) {
      return const Text('No vehicle models available.',
          style: TextStyle(color: _textPrimary));
    }

    return DropdownButtonFormField<VehicleModel>(
      value: _selectedModel,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFFB5B6B8),
        size: 32,
      ),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: _fieldBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      items: _vehicleModels
          .map((m) => DropdownMenuItem<VehicleModel>(
                value: m,
                child: Text(m.name),
              ))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedModel = value);
      },
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

