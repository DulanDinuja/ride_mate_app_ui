import 'package:flutter/material.dart';
import '../models/vehicle_type.dart';
import '../models/vehicle_make.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';
import '../widgets/custom_back_button.dart';

class UpdateVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const UpdateVehicleScreen({super.key, required this.vehicleData});

  @override
  State<UpdateVehicleScreen> createState() => _UpdateVehicleScreenState();
}

class _UpdateVehicleScreenState extends State<UpdateVehicleScreen> {
  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);
  static const Color _fieldBg = Color(0xFFE9E9DC);
  static const Color _pageBg = Color(0xFFFFFFF0);
  static const Color _textPrimary = Color(0xFF44526A);

  final _formKey = GlobalKey<FormState>();
  final _registrationController = TextEditingController();

  List<VehicleType> _vehicleTypes = [];
  List<VehicleMake> _vehicleMakes = [];
  List<VehicleModel> _vehicleModels = [];

  VehicleType? _selectedType;
  VehicleMake? _selectedMake;
  VehicleModel? _selectedModel;

  int _selectedYear = DateTime.now().year;
  String _selectedColor = 'White';
  bool _isLoading = false;
  bool _isLoadingDropdowns = true;

  final List<String> _colours = const [
    'Black', 'White', 'Silver', 'Blue', 'Red', 'Grey', 'Green', 'Yellow'
  ];

  @override
  void initState() {
    super.initState();
    _registrationController.text =
        widget.vehicleData['registrationNumber']?.toString() ?? '';
    _selectedYear = widget.vehicleData['year'] as int? ?? DateTime.now().year;
    _selectedColor = widget.vehicleData['color']?.toString() ?? 'White';
    if (!_colours.contains(_selectedColor)) _selectedColor = _colours.first;
    _loadDropdowns();
  }

  @override
  void dispose() {
    _registrationController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    try {
      final types = await VehicleService.getActiveVehicleTypes();
      final makes = await VehicleService.getVehicleMakesByStatus('ACTIVE');

      final currentTypeId = widget.vehicleData['vehicleTypeId'] as int?;
      final currentMakeId = widget.vehicleData['vehicleMakeId'] as int?;
      final currentModelId = widget.vehicleData['vehicleModelId'] as int?;

      VehicleType? matchedType =
          types.where((t) => t.id == currentTypeId).firstOrNull ?? types.firstOrNull;
      VehicleMake? matchedMake =
          makes.where((m) => m.id == currentMakeId).firstOrNull ?? makes.firstOrNull;

      List<VehicleModel> models = [];
      VehicleModel? matchedModel;
      if (matchedMake != null) {
        models = await VehicleService.getVehicleModelsByMakeId(matchedMake.id);
        matchedModel =
            models.where((m) => m.id == currentModelId).firstOrNull ?? models.firstOrNull;
      }

      if (!mounted) return;
      setState(() {
        _vehicleTypes = types;
        _vehicleMakes = makes;
        _vehicleModels = models;
        _selectedType = matchedType;
        _selectedMake = matchedMake;
        _selectedModel = matchedModel;
        _isLoadingDropdowns = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDropdowns = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _loadModels(int makeId) async {
    setState(() => _vehicleModels = []);
    try {
      final models = await VehicleService.getVehicleModelsByMakeId(makeId);
      if (!mounted) return;
      setState(() {
        _vehicleModels = models;
        _selectedModel = models.firstOrNull;
      });
    } catch (_) {}
  }

  Future<void> _pickYear() async {
    int tempYear = _selectedYear;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _pageBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Year',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 200,
          height: 200,
          child: StatefulBuilder(
            builder: (ctx, setD) => YearPicker(
              firstDate: DateTime(1990),
              lastDate: DateTime.now(),
              selectedDate: DateTime(tempYear),
              onChanged: (date) {
                setD(() => tempYear = date.year);
                setState(() => _selectedYear = date.year);
                Navigator.pop(ctx);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null || _selectedMake == null || _selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final vehicleId = widget.vehicleData['id'] as int;
      await VehicleService.updateVehicle(
        vehicleId: vehicleId,
        body: {
          'vehicleTypeId': _selectedType!.id,
          'vehicleMakeId': _selectedMake!.id,
          'vehicleModelId': _selectedModel!.id,
          'model': _selectedModel!.name,
          'registrationNumber': _registrationController.text.trim(),
          'year': _selectedYear,
          'color': _selectedColor,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle updated successfully'),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        leading: CustomBackButton(onPressed: () => Navigator.pop(context)),
        title: const Text('Update Vehicle'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingDropdowns
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _label('Vehicle Type'),
                  const SizedBox(height: 10),
                  _buildTypeSelector(),
                  const SizedBox(height: 20),
                  _label('Make'),
                  const SizedBox(height: 10),
                  _buildMakeDropdown(),
                  const SizedBox(height: 20),
                  _label('Model'),
                  const SizedBox(height: 10),
                  _buildModelDropdown(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Year'),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: _pickYear,
                              child: _fieldBox(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('$_selectedYear',
                                        style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF8F95A1))),
                                    const Icon(Icons.calendar_today,
                                        size: 18, color: Color(0xFFB5B6B8)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Color'),
                            const SizedBox(height: 10),
                            _buildColorDropdown(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _label('Registration Number'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _registrationController,
                    style: const TextStyle(fontSize: 15, color: _navy),
                    decoration: _inputDecoration('e.g. CAR-1234'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        disabledBackgroundColor: _accent.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary),
      );

  Widget _fieldBox({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9AA0AA)),
        filled: true,
        fillColor: _fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      );

  Widget _buildTypeSelector() {
    if (_vehicleTypes.isEmpty) {
      return const Text('No vehicle types available.',
          style: TextStyle(color: _textPrimary));
    }
    return Row(
      children: _vehicleTypes.asMap().entries.map((e) {
        final i = e.key;
        final vt = e.value;
        final selected = _selectedType?.id == vt.id;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = vt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? _accent : _fieldBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.directions_car,
                        color: selected ? Colors.white : _navy, size: 28),
                    const SizedBox(height: 6),
                    Text(vt.name,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : _navy)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMakeDropdown() => DropdownButtonFormField<VehicleMake>(
        value: _selectedMake,
        dropdownColor: Colors.white,
        decoration: _inputDecoration('Select make'),
        style: const TextStyle(fontSize: 15, color: Color(0xFF8F95A1)),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Color(0xFFB5B6B8)),
        items: _vehicleMakes
            .map((m) =>
                DropdownMenuItem(value: m, child: Text(m.name)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() => _selectedMake = v);
          _loadModels(v.id);
        },
      );

  Widget _buildModelDropdown() => DropdownButtonFormField<VehicleModel>(
        value: _selectedModel,
        dropdownColor: Colors.white,
        decoration: _inputDecoration('Select model'),
        style: const TextStyle(fontSize: 15, color: Color(0xFF8F95A1)),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Color(0xFFB5B6B8)),
        items: _vehicleModels
            .map((m) =>
                DropdownMenuItem(value: m, child: Text(m.name)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() => _selectedModel = v);
        },
      );

  Widget _buildColorDropdown() => DropdownButtonFormField<String>(
        value: _selectedColor,
        dropdownColor: Colors.white,
        decoration: _inputDecoration('Color'),
        style: const TextStyle(fontSize: 15, color: Color(0xFF8F95A1)),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Color(0xFFB5B6B8)),
        items: _colours
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() => _selectedColor = v);
        },
      );
}
