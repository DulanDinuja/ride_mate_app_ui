import 'package:flutter/material.dart';

import '../services/ride_preferences_service.dart';
import '../widgets/custom_back_button.dart';

/// Screen where the user sets their ride-matching preferences.
/// Gender preference controls which rides are shown / who can join the ride.
class RidePreferencesScreen extends StatefulWidget {
  const RidePreferencesScreen({super.key});

  @override
  State<RidePreferencesScreen> createState() => _RidePreferencesScreenState();
}

class _RidePreferencesScreenState extends State<RidePreferencesScreen> {
  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);
  static const Color _cream = Color(0xFFFFFFF0);
  static const Color _cardBg = Color(0xFFF5F6F2);

  GenderPreference _selectedGender = GenderPreference.both;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final pref = await RidePreferencesService.loadGenderPreference();
    if (mounted) {
      setState(() {
        _selectedGender = pref;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      await RidePreferencesService.saveGenderPreference(_selectedGender);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Preferences saved successfully!'),
            ],
          ),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, _selectedGender);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        title: const Text('Ride Preferences'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildGenderSection(),
                const SizedBox(height: 24),
                _buildInsightCard(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF040F1B), Color(0xFF0A2540)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.tune_rounded, color: _accent, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RideMate Ride Matching',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Set your preferences to personalise your ride matches by comfort and safety.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Gender Section ────────────────────────────────────────────────

  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people_outline, color: _accent, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Gender Preference',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF040F1B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose who you prefer to ride with or offer rides to.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        _buildGenderCard(
          preference: GenderPreference.both,
          icon: Icons.people_alt_outlined,
          title: 'Both',
          subtitle: 'Open to all genders — maximise ride matches and savings.',
          accentColor: _accent,
          iconBg: _accent.withOpacity(0.1),
        ),
        const SizedBox(height: 12),
        _buildGenderCard(
          preference: GenderPreference.male,
          icon: Icons.male_rounded,
          title: 'Male Only',
          subtitle:
              'Match only with male drivers (as passenger) or male passengers (as driver).',
          accentColor: const Color(0xFF1A73E8),
          iconBg: const Color(0xFF1A73E8).withOpacity(0.1),
        ),
        const SizedBox(height: 12),
        _buildGenderCard(
          preference: GenderPreference.female,
          icon: Icons.female_rounded,
          title: 'Female Only',
          subtitle:
              'Match only with female drivers (as passenger) or female passengers (as driver).',
          accentColor: const Color(0xFFE91E8C),
          iconBg: const Color(0xFFE91E8C).withOpacity(0.1),
        ),
      ],
    );
  }

  Widget _buildGenderCard({
    required GenderPreference preference,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required Color iconBg,
  }) {
    final isSelected = _selectedGender == preference;

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = preference),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.06) : _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withOpacity(0.15) : iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isSelected ? accentColor : Colors.grey.shade500,
                  size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? accentColor : _navy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── How It Works Card ────────────────────────────────────────────────

  Widget _buildInsightCard() {
    final insights = _getInsights();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.04),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_outline,
                    color: _accent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'How It Works',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF040F1B),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'RideMate Match',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...insights
              .map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            insight,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  List<String> _getInsights() {
    switch (_selectedGender) {
      case GenderPreference.both:
        return [
          'Maximum ride availability — you will see all drivers and all passengers regardless of gender.',
          'Higher chance of finding a ride quickly due to the larger pool of matches.',
          'Best for saving money — more passengers means a lower cost split for everyone.',
        ];
      case GenderPreference.male:
        return [
          'You will only be matched with male drivers (when requesting a ride) or male passengers (when offering a ride).',
          'Reduces the match pool but ensures gender alignment with your preference.',
          'Availability may be lower during peak hours — consider switching to Both if no rides are found.',
        ];
      case GenderPreference.female:
        return [
          'You will only be matched with female drivers (when requesting a ride) or female passengers (when offering a ride).',
          'Ideal for safety-conscious riders — female-only matching gives greater peace of mind.',
          'Availability may be limited — RideMate will suggest when female-only rides are available nearby.',
        ];
    }
  }

  // ─── Save Button ──────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _savePreferences,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save_alt_rounded),
        label: Text(
          _isSaving ? 'Saving...' : 'Save Preferences',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
      ),
    );
  }
}

