import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/token_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_back_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  // ── Design constants ────────────────────────────────────────────
  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);
  static const Color _cream = Color(0xFFFFFFF0);
  static const Color _amber = Color(0xFFF59E0B);

  // ── State ─────────────────────────────────────────────────────
  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  int _rating = 0;
  String? _selectedCategory;
  final _feedbackCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  static const List<String> _categories = [
    'Overall App Experience',
    'Driver Experience',
    'Ride Comfort',
    'Fare / Pricing',
    'Customer Support',
    'Map & Navigation',
    'Feature Request',
    'Other',
  ];

  static const List<String> _ratingLabels = [
    '',
    'Very Poor',
    'Poor',
    'Okay',
    'Good',
    'Excellent',
  ];

  static const List<Color> _ratingColors = [
    Colors.transparent,
    Color(0xFFD32F2F),
    Color(0xFFE64A19),
    Color(0xFFF59E0B),
    Color(0xFF43A047),
    Color(0xFF03AF74),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = await TokenService.getUserId();
      if (userId == null) throw Exception('User not logged in');
      final profile = await UserService.getUserProfileByUserId(userId);
      if (mounted) setState(() { _profile = profile; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a star rating'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a feedback category'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _submitting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _submitting = false);
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _amber.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.star_rounded, color: _amber, size: 36),
            ),
            const SizedBox(height: 12),
            const Text('Thank You!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _navy)),
          ],
        ),
        content: const Text(
          'Your feedback has been submitted. We use your input to continuously improve RideMate for everyone.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black54),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(6),
          child: CustomBackButton(),
        ),
        title: const Text('Give Feedback'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _error != null
              ? _buildError()
              : _buildForm(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text('Could not load profile',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() { _loading = true; _error = null; });
                _loadProfile();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _accent, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final p = _profile!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Banner ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.reviews_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Share Your Experience',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text(
                            'Help us improve RideMate with your valuable feedback.',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Auto-populated User Info ────────────────────────────
            _sectionLabel(
                Icons.person_pin_circle_rounded, 'Your Information',
                color: _navy),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: _navy.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Column(
                children: [
                  _infoTile(
                    icon: Icons.badge_outlined,
                    label: 'User ID',
                    value: '#${p.userId}',
                    iconColor: Colors.indigo.shade600,
                  ),
                  const Divider(height: 1, indent: 56),
                  _infoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: p.phoneNumber.isNotEmpty
                        ? p.phoneNumber
                        : 'Not provided',
                    iconColor: Colors.green.shade600,
                  ),
                  const Divider(height: 1, indent: 56),
                  _infoTile(
                    icon: Icons.credit_card_rounded,
                    label: 'NIC / ID Number',
                    value: (p.identificationNumber != null &&
                            p.identificationNumber!.isNotEmpty)
                        ? p.identificationNumber!
                        : 'Not provided',
                    iconColor: Colors.blue.shade600,
                  ),
                  const Divider(height: 1, indent: 56),
                  _infoTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Name',
                    value: '${p.firstName} ${p.lastName}',
                    iconColor: _accent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Star Rating ────────────────────────────────────────
            _sectionLabel(Icons.star_half_rounded, 'Overall Rating',
                color: _navy),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: _navy.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = star),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            star <= _rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: star <= _rating ? 44 : 38,
                            color: star <= _rating
                                ? _ratingColors[_rating]
                                : Colors.grey.shade300,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_rating > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 5),
                      decoration: BoxDecoration(
                        color: _ratingColors[_rating].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _ratingLabels[_rating],
                        style: TextStyle(
                          color: _ratingColors[_rating],
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Category ───────────────────────────────────────────
            _sectionLabel(Icons.category_outlined, 'Feedback Category',
                color: _navy),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _selectedCategory == null
                        ? Colors.grey.shade300
                        : _amber.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                      color: _navy.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: Text('Select a category',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 14)),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade500),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(
                                    fontSize: 14, color: _navy)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ── Feedback Text ──────────────────────────────────────
            _sectionLabel(Icons.edit_note_rounded, 'Your Feedback',
                color: _navy),
            const SizedBox(height: 10),
            TextFormField(
              controller: _feedbackCtrl,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14, color: _navy),
              decoration: _inputDecoration(
                hint:
                    'Share your thoughts, suggestions, or experiences with RideMate...',
                icon: Icons.chat_bubble_outline_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please write your feedback';
                }
                if (v.trim().length < 10) {
                  return 'Please provide at least 10 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            // ── Submit Button ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _submitting ? 'Submitting…' : 'Submit Feedback',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amber,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
              ),
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                'We read every piece of feedback. Thank you! 🙏',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: _navy)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('Auto',
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, color: _accent)),
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? _navy),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: color ?? _navy),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _amber, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
    );
  }
}

