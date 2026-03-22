import 'package:flutter/material.dart';
import '../models/vehicle_type.dart';
import '../models/vehicle_make.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';
import '../widgets/custom_back_button.dart';

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

class UpdateVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const UpdateVehicleScreen({super.key, required this.vehicleData});

  @override
  State<UpdateVehicleScreen> createState() => _UpdateVehicleScreenState();
}

class _UpdateVehicleScreenState extends State<UpdateVehicleScreen> {
  static const Color _panelBackground = Color(0xFFFFFFF0);
  static const Color _fieldBackground = Color(0xFFE9E9DC);
  static const Color _textPrimary = Color(0xFF44526A);
  static const Color _textDark = Color(0xFF121A2C);
  static const Color _accent = Color(0xFF10B47A);
  static const Color _navy = Color(0xFF040F1B);
  static const Color _buttonDark = Color(0xFF061324);

  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController();

  List<VehicleType> _vehicleTypes = [];
  List<VehicleMake> _vehicleMakes = [];
  List<VehicleModel> _vehicleModels = [];

  bool _isLoadingTypes = true;
  bool _isLoadingMakes = true;
  bool _isLoadingModels = false;
  bool _isSaving = false;

  String? _typesError;
  String? _makesError;
  String? _modelsError;

  VehicleType? _selectedVehicleType;
  VehicleMake? _selectedMake;
  VehicleModel? _selectedModel;

  int _selectedYear = DateTime.now().year;
  String _selectedColour = 'Black';

  final List<String> _colours = const [
    'Black', 'White', 'Silver', 'Blue', 'Red', 'Grey', 'Green', 'Yellow',
  ];

  late int _vehicleId;

  @override
  void initState() {
    super.initState();
    _vehicleId = widget.vehicleData['id'] as int;
    _registrationController.text =
        widget.vehicleData['registrationNumber']?.toString() ?? '';
    _seatsController.text =
        widget.vehicleData['seats']?.toString() ?? '';
    _selectedYear = int.tryParse(
          widget.vehicleData['year']?.toString() ?? '',
        ) ??
        DateTime.now().year;

    final existingColour = widget.vehicleData['color']?.toString() ?? 'Black';
    _selectedColour = _colours.contains(existingColour) ? existingColour : 'Black';

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
      if (!mounted) return;
      setState(() {
        _vehicleTypes = types;
        _isLoadingTypes = false;
        final existingTypeId = widget.vehicleData['vehicleTypeId'];
        _selectedVehicleType = types.firstWhere(
          (t) => t.id == existingTypeId,
          orElse: () => types.isNotEmpty ? types.first : types.first,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _typesError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingTypes = false;
      });
    }
  }

  Future<void> _loadVehicleMakes() async {
    setState(() {
      _isLoadingMakes = true;
      _makesError = null;
    });
    try {
      final makes = await VehicleService.getVehicleMakesByStatus('ACTIVE');
      if (!mounted) return;
      final existingMakeId = widget.vehicleData['vehicleMakeId'];
      final matched = makes.where((m) => m.id == existingMakeId).toList();
      final selected = matched.isNotEmpty
          ? matched.first
          : (makes.isNotEmpty ? makes.first : null);
      setState(() {
        _vehicleMakes = makes;
        _isLoadingMakes = false;
        _selectedMake = selected;
      });
      if (selected != null) {
        await _loadVehicleModels(selected.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _makesError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingMakes = false;
      });
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
      final models =
          await VehicleService.getVehicleModelsByMakeId(vehicleMakeId);
      if (!mounted) return;
      final existingModelId = widget.vehicleData['vehicleModelId'];
      final matched = models.where((m) => m.id == existingModelId).toList();
      setState(() {
        _vehicleModels = models;
        _isLoadingModels = false;
        _selectedModel = matched.isNotEmpty
            ? matched.first
            : (models.isNotEmpty ? models.first : null);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _modelsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingModels = false;
      });
    }
  }

  Future<void> _pickYear() async {
    int tempYear = _selectedYear;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panelBackground,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Select Year',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
        ),
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

  Future<void> _onSavePressed() async {
    if (_selectedVehicleType == null) {
      _showSnack('Please select a vehicle type');
      return;
    }
    if (_selectedMake == null) {
      _showSnack('Please select a vehicle make');
      return;
    }
    if (_selectedModel == null) {
      _showSnack('Please select a vehicle model');
      return;
    }
    if (_selectedYear > DateTime.now().year) {
      _showSnack('Invalid vehicle manufacture year');
      return;
    }
    if (_registrationController.text.trim().isEmpty) {
      _showSnack('Please enter registration number');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final body = <String, dynamic>{
        'vehicleTypeId': _selectedVehicleType!.id,
        'vehicleMakeId': _selectedMake!.id,
        'vehicleModelId': _selectedModel!.id,
        'registrationNumber': _registrationController.text.trim(),
        'year': _selectedYear,
        'color': _selectedColour,
        if (_seatsController.text.trim().isNotEmpty)
          'seats': int.tryParse(_seatsController.text.trim()),
      };

      await VehicleService.updateVehicle(vehicleId: _vehicleId, body: body);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle updated successfully'),
          backgroundColor: _accent,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _panelBackground,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Vehicle',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Edit your vehicle details below',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Vehicle Type',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildVehicleTypeSelector(),
                  const SizedBox(height: 28),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 18),
                                decoration: BoxDecoration(
                                  color: _fieldBackground,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$_selectedYear',
                                      style: const TextStyle(
                                          fontSize: 17,
                                          color: Color(0xFF8F95A1)),
                                    ),
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Color(0xFFB5B6B8),
                                      size: 20,
                                    ),
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
                    style: const TextStyle(fontSize: 17, color: _textDark),
                    decoration: InputDecoration(
                      hintText: 'CAR-1515',
                      hintStyle:
                          const TextStyle(color: Color(0xFF9AA0AA)),
                      filled: true,
                      fillColor: _fieldBackground,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 22),
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
                        borderSide:
                            const BorderSide(color: _accent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Seats',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _seatsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 17, color: _textDark),
                    decoration: InputDecoration(
                      hintText: '4',
                      hintStyle:
                          const TextStyle(color: Color(0xFF9AA0AA)),
                      filled: true,
                      fillColor: _fieldBackground,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 22),
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
                        borderSide:
                            const BorderSide(color: _accent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _onSavePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonDark,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            _buttonDark.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 12,
              child: CustomBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeSelector() {
    if (_isLoadingTypes) {
      return const SizedBox(
        height: 90,
        child:
            Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    if (_typesError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(_typesError!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
          TextButton(
            onPressed: _loadVehicleTypes,
            child:
                const Text('Retry', style: TextStyle(color: _accent)),
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
      final isSelected = _selectedVehicleType?.id == vt.id;
      children.add(
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedVehicleType = vt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: isSelected ? _accent : _fieldBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconForVehicleCode(vt.code),
                    size: 28,
                    color: isSelected ? Colors.white : _textPrimary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    vt.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _textPrimary,
                    ),
                  ),
                ],
              ),
            ),
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
        child:
            Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    if (_makesError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(_makesError!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
          TextButton(
            onPressed: _loadVehicleMakes,
            child:
                const Text('Retry', style: TextStyle(color: _accent)),
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
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: Color(0xFFB5B6B8), size: 32),
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
      items: _vehicleMakes
          .map(
            (m) => DropdownMenuItem(
              value: m,
              child: Text(m.name,
                  style: const TextStyle(fontSize: 16, color: _textDark)),
            ),
          )
          .toList(),
      onChanged: (make) {
        if (make == null) return;
        setState(() {
          _selectedMake = make;
          _selectedModel = null;
          _vehicleModels = [];
        });
        _loadVehicleModels(make.id);
      },
    );
  }

  Widget _buildModelDropdown() {
    if (_isLoadingModels) {
      return const SizedBox(
        height: 62,
        child:
            Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    if (_modelsError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(_modelsError!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
          TextButton(
            onPressed: () {
              if (_selectedMake != null) {
                _loadVehicleModels(_selectedMake!.id);
              }
            },
            child:
                const Text('Retry', style: TextStyle(color: _accent)),
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
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: Color(0xFFB5B6B8), size: 32),
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
      items: _vehicleModels
          .map(
            (m) => DropdownMenuItem(
              value: m,
              child: Text(m.name,
                  style: const TextStyle(fontSize: 16, color: _textDark)),
            ),
          )
          .toList(),
      onChanged: (model) {
        if (model == null) return;
        setState(() => _selectedModel = model);
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
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: Color(0xFFB5B6B8), size: 32),
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
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item,
                  style:
                      const TextStyle(fontSize: 17, color: Color(0xFF8F95A1))),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
