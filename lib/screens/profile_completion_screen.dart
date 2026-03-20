import 'package:flutter/material.dart';
import '../widgets/custom_back_button.dart';
import '../core/routes/app_routes.dart';
import '../models/identification_type.dart';
import '../models/user_verification_args.dart';
import '../services/identification_type_service.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final TextEditingController _idNumberController = TextEditingController();

  List<IdentificationType> _documentTypes = const [];
  final List<String> _genders = const ['Male', 'Female', 'Other'];

  bool _willingToDrive = true;
  int? _selectedDocumentTypeId;
  String? _selectedDocumentTypeName;
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  bool _isLoadingDocumentTypes = true;

  @override
  void initState() {
    super.initState();
    _loadDocumentTypes();
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: size.height,
            child: CustomPaint(
              painter: _MapHeaderPainter(),
            ),
          ),
          // Back button
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.only(left: 16, top: 12),
              child: CustomBackButton(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: size.height * 0.82,
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFF0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(44),
                  topRight: Radius.circular(44),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 14, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 92,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC5C9D2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      _buildStepper(),
                      const SizedBox(height: 46),
                      const Text(
                        'Willing to Drive?',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF44526A),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Switch(
                        value: _willingToDrive,
                        onChanged: (value) {
                          setState(() => _willingToDrive = value);
                        },
                        activeColor: const Color(0xFFFFFFF0),
                        activeTrackColor: const Color(0xFF10B47A),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: const Color(0xFFD8DACE),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Document Type',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF44526A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentTypeDropdown(),
                      const SizedBox(height: 26),
                      const Text(
                        'NIC Number / Passport Number',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF44526A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _idNumberController,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Color(0xFF172235),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter ID number',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9AA0AA),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFE3E3D8),
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
                            borderSide: const BorderSide(
                              color: Color(0xFF10B47A),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Date of Birth',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF44526A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickDateOfBirth,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 22,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3E3D8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDateOfBirth == null
                                    ? 'Select Date of Birth'
                                    : _formatDate(_selectedDateOfBirth!),
                                style: TextStyle(
                                  fontSize: 17,
                                  color: _selectedDateOfBirth == null
                                      ? const Color(0xFF9AA0AA)
                                      : const Color(0xFF172235),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_month,
                                color: Color(0xFFA8AAB0),
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF44526A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownField(
                        value: _selectedGender,
                        items: _genders,
                        hintText: 'Select Gender',
                        onChanged: (value) {
                          setState(() => _selectedGender = value);
                        },
                      ),
                      const SizedBox(height: 34),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 66,
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF010E28),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                                child: const Text(
                                  'Back',
                                  style: TextStyle(fontSize: 40 / 2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 66,
                              child: ElevatedButton(
                                onPressed: _onNextPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B47A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                                child: const Text(
                                  'Next',
                                  style: TextStyle(fontSize: 40 / 2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Column(
      children: [
        Row(
          children: [
            _buildStepCircle(
              label: '1',
              isActive: true,
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Divider(
                  color: Color(0xFFD8DACF),
                  thickness: 3,
                ),
              ),
            ),
            _buildStepCircle(
              label: '2',
              isActive: false,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Expanded(
              child: Text(
                'Personal\nDetails',
                style: TextStyle(
                  height: 1.25,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111A2B),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Vehical\nDetails',
                textAlign: TextAlign.right,
                style: TextStyle(
                  height: 1.25,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFA7A9AF),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepCircle({required String label, required bool isActive}) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF10B47A) : const Color(0xFFDEDFD5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFFF5F5F0),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    String? hintText,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E3D8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: hintText == null ? null : Text(hintText),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFFA8AAB0),
            size: 36,
          ),
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(
            fontSize: 17,
            color: Color(0xFF8D939D),
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: const Color(0xFFFFFFF0),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDocumentTypeDropdown() {
    if (_isLoadingDocumentTypes) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFE3E3D8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Loading document types...',
              style: TextStyle(fontSize: 16, color: Color(0xFF8D939D)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E3D8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: _selectedDocumentTypeId,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFFA8AAB0),
            size: 36,
          ),
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(
            fontSize: 17,
            color: Color(0xFF8D939D),
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: const Color(0xFFFFFFF0),
          items: _documentTypes
              .map(
                (item) => DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(item.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            final selected = _documentTypes.firstWhere((item) => item.id == value);
            setState(() {
              _selectedDocumentTypeId = selected.id;
              _selectedDocumentTypeName = selected.name;
            });
          },
        ),
      ),
    );
  }

  Future<void> _loadDocumentTypes() async {
    try {
      final types = await IdentificationTypeService.getActiveIdentificationTypes();
      if (!mounted) return;

      setState(() {
        _documentTypes = types;
        _isLoadingDocumentTypes = false;
        if (types.isNotEmpty) {
          _selectedDocumentTypeId = types.first.id;
          _selectedDocumentTypeName = types.first.name;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDocumentTypes = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load document types: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDateOfBirth ?? DateTime(now.year - 18, now.month, now.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (pickedDate != null) {
      setState(() => _selectedDateOfBirth = pickedDate);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _onNextPressed() {
    if (_selectedDocumentTypeId == null || _selectedDocumentTypeName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a document type')),
      );
      return;
    }

    final idNumber = _idNumberController.text.trim();
    if (idNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your NIC or passport number')),
      );
      return;
    }

    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender')),
      );
      return;
    }

    final dob = _selectedDateOfBirth!;
    final dateOfBirthStr =
        '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';

    Navigator.pushNamed(
      context,
      AppRoutes.userVerification,
      arguments: UserVerificationArgs(
        documentTypeId: _selectedDocumentTypeId!,
        documentType: _selectedDocumentTypeName!,
        idNumber: idNumber,
        gender: _selectedGender!,
        userRole: _willingToDrive ? 'YES' : 'NO',
        dateOfBirth: dateOfBirthStr,
      ),
    );
  }
}

class _MapHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xFF2A2C34);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final roadPaint = Paint()
      ..color = const Color(0xFF6E737C)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = const Color(0xFF545962)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final waterPaint = Paint()
      ..color = const Color(0xFF0E3F4A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final parkPaint = Paint()..color = const Color(0xFF203D1B);

    final roads = <Path>[
      Path()
        ..moveTo(-20, size.height * 0.25)
        ..lineTo(size.width + 20, size.height * 0.2),
      Path()
        ..moveTo(-20, size.height * 0.45)
        ..lineTo(size.width + 20, size.height * 0.5),
      Path()
        ..moveTo(size.width * 0.2, -20)
        ..lineTo(size.width * 0.23, size.height + 20),
      Path()
        ..moveTo(size.width * 0.7, -20)
        ..lineTo(size.width * 0.75, size.height + 20),
    ];

    final minorRoads = <Path>[
      Path()
        ..moveTo(0, size.height * 0.12)
        ..lineTo(size.width, size.height * 0.12),
      Path()
        ..moveTo(0, size.height * 0.33)
        ..lineTo(size.width, size.height * 0.35),
      Path()
        ..moveTo(0, size.height * 0.61)
        ..lineTo(size.width, size.height * 0.59),
      Path()
        ..moveTo(size.width * 0.42, 0)
        ..lineTo(size.width * 0.44, size.height),
    ];

    final riverPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.42,
        size.width * 0.62,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.68,
        size.width * 1.1,
        size.height * 0.6,
      );

    for (final path in roads) {
      canvas.drawPath(path, roadPaint);
    }
    for (final path in minorRoads) {
      canvas.drawPath(path, minorRoadPaint);
    }

    canvas.drawPath(riverPath, waterPaint);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.18, size.height * 0.28),
        width: 70,
        height: 48,
      ),
      parkPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.8, size.height * 0.72),
        width: 62,
        height: 40,
      ),
      parkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

