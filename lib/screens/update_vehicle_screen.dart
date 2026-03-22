import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../core/routes/app_routes.dart';
import '../models/vehicle_type.dart';
import '../models/vehicle_make.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';
import '../services/file_service.dart';
import '../widgets/custom_back_button.dart';
import 'selfie_camera_screen.dart';

class UpdateVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const UpdateVehicleScreen({super.key, required this.vehicleData});

  @override
  State<UpdateVehicleScreen> createState() => _UpdateVehicleScreenState();
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

class _UpdateVehicleScreenState extends State<UpdateVehicleScreen> {
  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Vehicle photos
  final Map<String, Uint8List?> _photos = {
    'front': null,
    'rear': null,
    'left': null,
    'right': null,
  };

  // API-loaded data
  List<VehicleType> _vehicleTypes = [];
  List<VehicleMake> _vehicleMakes = [];
  List<VehicleModel> _vehicleModels = [];
  bool _isLoadingTypes = true;
  bool _isLoadingMakes = true;
  bool _isLoadingModels = false;
  bool _isUpdating = false;
  String? _typesError;
  String? _makesError;
  String? _modelsError;

  VehicleType? _selectedVehicleType;
  VehicleMake? _selectedMake;
  VehicleModel? _selectedModel;

  final List<String> _colours = const ['Black', 'White', 'Silver', 'Blue', 'Red', 'Gray', 'Green'];

  int _selectedYear = DateTime.now().year;
  String _selectedColour = 'Black';

  static const Color _panelBackground = Color(0xFFFFFFF0);
  static const Color _fieldBackground = Color(0xFFE9E9DC);
  static const Color _textPrimary = Color(0xFF44526A);
  static const Color _textDark = Color(0xFF121A2C);
  static const Color _accent = Color(0xFF10B47A);
  static const Color _muted = Color(0xFFB5B6B8);
  static const Color _buttonDark = Color(0xFF061324);

  @override
  void initState() {
    super.initState();
    _initializeFromVehicleData();
    _loadVehicleTypes();
    _loadVehicleMakes();
  }

  void _initializeFromVehicleData() {
    _registrationController.text = widget.vehicleData['registrationNumber']?.toString() ?? '';
    _selectedYear = widget.vehicleData['year'] as int? ?? DateTime.now().year;
    
    final colorFromData = widget.vehicleData['color']?.toString() ?? 'Black';
    if (_colours.contains(colorFromData)) {
      _selectedColour = colorFromData;
    } else {
      _selectedColour = 'Black';
    }
    
    _colorController.text = widget.vehicleData['color']?.toString() ?? '';
    _seatsController.text = widget.vehicleData['seats']?.toString() ?? '';
  }

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
          // Set selected type from vehicle data
          final vehicleTypeId = widget.vehicleData['vehicleTypeId'] as int?;
          if (vehicleTypeId != null) {
            _selectedVehicleType = types.firstWhere(
              (t) => t.id == vehicleTypeId,
              orElse: () => types.isNotEmpty ? types.first : types.first,
            );
          } else if (types.isNotEmpty) {
            _selectedVehicleType = types.first;
          }
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
          // Set selected make from vehicle data
          final vehicleMakeId = widget.vehicleData['vehicleMakeId'] as int?;
          if (vehicleMakeId != null) {
            _selectedMake = makes.firstWhere(
              (m) => m.id == vehicleMakeId,
              orElse: () => makes.isNotEmpty ? makes.first : makes.first,
            );
            if (_selectedMake != null) {
              _loadVehicleModels(_selectedMake!.id);
            }
          } else if (makes.isNotEmpty) {
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
      if (_selectedMake?.id != vehicleMakeId) {
        _selectedModel = null;
      }
    });
    try {
      final models = await VehicleService.getVehicleModelsByMakeId(vehicleMakeId);
      if (mounted) {
        setState(() {
          _vehicleModels = models;
          _isLoadingModels = false;
          // Set selected model from vehicle data
          final vehicleModelId = widget.vehicleData['vehicleModelId'] as int?;
          if (vehicleModelId != null) {
            _selectedModel = models.firstWhere(
              (m) => m.id == vehicleModelId,
              orElse: () => models.isNotEmpty ? models.first : models.first,
            );
          } else if (models.isNotEmpty) {
            _selectedModel = models.first;
          }
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
    _colorController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  Future<void> _onUpdatePressed() async {
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

    final currentYear = DateTime.now().year;
    if (_selectedYear > currentYear) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid vehicle manufacture year!!!')),
      );
      return;
    }

    if (_registrationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter registration number')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final vehicleId = widget.vehicleData['id'] as int;
      
      // Upload new images if provided
      final Map<String, int?> imageDocumentIds = {};
      
      if (_photos['front'] != null) {
        final docId = await FileService.uploadFile(
          bytes: _photos['front']!,
          fileName: 'vehicle_front_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        imageDocumentIds['vehicleImageDocumentId1'] = docId;
      }
      
      if (_photos['rear'] != null) {
        final docId = await FileService.uploadFile(
          bytes: _photos['rear']!,
          fileName: 'vehicle_rear_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        imageDocumentIds['vehicleImageDocumentId2'] = docId;
      }
      
      if (_photos['left'] != null) {
        final docId = await FileService.uploadFile(
          bytes: _photos['left']!,
          fileName: 'vehicle_left_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        imageDocumentIds['vehicleImageDocumentId3'] = docId;
      }
      
      if (_photos['right'] != null) {
        final docId = await FileService.uploadFile(
          bytes: _photos['right']!,
          fileName: 'vehicle_right_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        imageDocumentIds['vehicleImageDocumentId4'] = docId;
      }

      final body = {
        'vehicleTypeId': _selectedVehicleType!.id,
        'vehicleMakeId': _selectedMake!.id,
        'vehicleModelId': _selectedModel!.id,
        'registrationNumber': _registrationController.text.trim(),
        'model': _selectedModel!.name,
        'year': _selectedYear,
        'color': _colorController.text.trim(),
        'seats': int.tryParse(_seatsController.text.trim()) ?? 4,
        ...imageDocumentIds,
      };

      await VehicleService.updateVehicle(vehicleId: vehicleId, body: body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle updated successfully!'),
          backgroundColor: _accent,
        ),
      );

      Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _panelBackground,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Vehicle Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vehicle ID: ${widget.vehicleData['id']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _textPrimary,
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
                    const SizedBox(height: 26),
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
                    const SizedBox(height: 26),
                    const Text(
                      'Colour',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _colorController,
                      style: const TextStyle(
                        fontSize: 17,
                        color: _textDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'White',
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
                    const SizedBox(height: 26),
                    const Text(
                      'Number of Seats',
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
                      style: const TextStyle(
                        fontSize: 17,
                        color: _textDark,
                      ),
                      decoration: InputDecoration(
                        hintText: '4',
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
                    const SizedBox(height: 30),
                    const Text(
                      'Vehicle Photos (Optional)',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Update vehicle photos if needed',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildPhotoCard('front', 'Front')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildPhotoCard('rear', 'Rear')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildPhotoCard('left', 'Left')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildPhotoCard('right', 'Right')),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: OutlinedButton(
                              onPressed: _isUpdating ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _buttonDark,
                                side: const BorderSide(color: _buttonDark),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 58,
                            child: ElevatedButton(
                              onPressed: _isUpdating ? null : _onUpdatePressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _buttonDark,
                                disabledBackgroundColor: _buttonDark.withOpacity(0.5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              child: _isUpdating
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Update Vehicle',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Positioned(
                top: 16,
                left: 12,
                child: CustomBackButton(),
              ),
            ],
          ),
        ),
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
      return const Text('No vehicle types available.', style: TextStyle(color: _textPrimary));
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
      return const Text('No vehicle makes available.', style: TextStyle(color: _textPrimary));
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      return const Text('No vehicle models available.', style: TextStyle(color: _textPrimary));
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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

  Future<void> _selectPhoto(String side) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take photo'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Upload from gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;
    if (!mounted) return;

    try {
      Uint8List? bytes;
      if (source == ImageSource.camera) {
        bytes = await Navigator.of(context).push<Uint8List>(
          MaterialPageRoute(
            builder: (_) => const SelfieCameraScreen(
              title: 'Capture Vehicle Photo',
              preferredLensDirection: CameraLensDirection.back,
              overlayShape: BoxShape.rectangle,
            ),
          ),
        );
      } else {
        final file = await _picker.pickImage(source: source, imageQuality: 80);
        if (file != null) {
          bytes = await file.readAsBytes();
        }
      }

      if (bytes == null || !mounted) return;
      setState(() {
        _photos[side] = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Widget _buildPhotoCard(String side, String label) {
    final image = _photos[side];

    return GestureDetector(
      onTap: () => _selectPhoto(side),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: image == null ? _fieldBackground : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: image == null ? Colors.grey.shade300 : _accent,
            width: image == null ? 1 : 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_rounded,
                    size: 32,
                    color: Color(0xFFB5B6B8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8F95A1),
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    image,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _photos[side] = null),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
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
