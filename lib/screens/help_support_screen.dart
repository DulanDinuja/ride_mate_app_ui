import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/custom_back_button.dart';

/// Help & Support screen — accessible from the account tab and from the
/// active ride screen as an emergency panel.
class HelpSupportScreen extends StatefulWidget {
  /// When [isEmergencyMode] is true the screen opens directly to the
  /// Emergency Services section (ride is ongoing).
  final bool isEmergencyMode;

  const HelpSupportScreen({super.key, this.isEmergencyMode = false});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);
  static const Color _cream = Color(0xFFFFFFF0);
  static const Color _red = Color(0xFFD32F2F);
  static const Color _redLight = Color(0xFFFFEBEE);

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _emergencyKey = GlobalKey();

  // FAQ expand state
  final Map<int, bool> _faqExpanded = {};

  @override
  void initState() {
    super.initState();
    if (widget.isEmergencyMode) {
      // Scroll to emergency section after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToEmergency();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEmergency() {
    final ctx = _emergencyKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Launch a phone call URI.
  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch call to $number'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (_) {}
  }

  /// Show an SOS confirmation dialog before calling.
  Future<void> _triggerSOS() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _redLight,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: _red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('SOS Emergency',
                style: TextStyle(
                    color: _red,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
          ],
        ),
        content: const Text(
          'This will immediately call the Sri Lanka Police Emergency line (119).\n\nOnly use in a real emergency.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.phone, size: 16),
            label: const Text('Call 119 Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _call('119');
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
        title: const Text('Help & Support'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Quick SOS in AppBar when in emergency mode
          if (widget.isEmergencyMode)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ElevatedButton.icon(
                onPressed: _triggerSOS,
                icon: const Icon(Icons.emergency_share_rounded, size: 16),
                label: const Text('SOS',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(18),
        children: [
          // ── Emergency banner when ride is ongoing ──
          if (widget.isEmergencyMode) ...[
            _buildEmergencyBanner(),
            const SizedBox(height: 18),
          ],

          // ── Emergency Services ──
          _buildEmergencySection(),
          const SizedBox(height: 18),

          // ── Contact Support ──
          _buildContactSection(),
          const SizedBox(height: 18),

          // ── FAQ ──
          _buildFaqSection(),
          const SizedBox(height: 18),

          // ── Safety Tips ──
          _buildSafetyTipsSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Emergency Banner (ride ongoing) ──────────────────────────────

  Widget _buildEmergencyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _red.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_car_rounded,
                color: _red, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ride is Active',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _red,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Emergency services are available below. Stay safe.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B0000),
                      height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Emergency Services ───────────────────────────────────────────

  Widget _buildEmergencySection() {
    return Column(
      key: _emergencyKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          Icons.emergency_rounded,
          'Emergency Services',
          color: _red,
          bg: _redLight,
        ),
        const SizedBox(height: 12),

        // SOS Big Button
        GestureDetector(
          onTap: _triggerSOS,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _red.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54, width: 2),
                  ),
                  child: const Icon(Icons.sos_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 10),
                const Text(
                  'SOS — EMERGENCY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to call Police (119)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Emergency number grid
        Row(
          children: [
            Expanded(
              child: _emergencyCard(
                icon: Icons.local_police_rounded,
                label: 'Police',
                number: '119',
                color: Colors.blue.shade700,
                bg: Colors.blue.shade50,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _emergencyCard(
                icon: Icons.local_hospital_rounded,
                label: 'Ambulance',
                number: '1990',
                color: Colors.green.shade700,
                bg: Colors.green.shade50,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _emergencyCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Fire',
                number: '110',
                color: Colors.orange.shade700,
                bg: Colors.orange.shade50,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Tourist Police
        _emergencyTile(
          icon: Icons.shield_rounded,
          label: 'Tourist Police',
          number: '1912',
          description: 'For tourists and visitors needing police assistance',
          color: Colors.purple.shade700,
          bg: Colors.purple.shade50,
        ),
        const SizedBox(height: 8),
        _emergencyTile(
          icon: Icons.health_and_safety_rounded,
          label: 'Suwa Seriya (Health)',
          number: '1990',
          description: 'National Emergency Ambulance Service of Sri Lanka',
          color: Colors.teal.shade700,
          bg: Colors.teal.shade50,
        ),
      ],
    );
  }

  Widget _emergencyCard({
    required IconData icon,
    required String label,
    required String number,
    required Color color,
    required Color bg,
  }) {
    return GestureDetector(
      onTap: () => _call(number),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
            Text(
              number,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Call',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emergencyTile({
    required IconData icon,
    required String label,
    required String number,
    required String description,
    required Color color,
    required Color bg,
  }) {
    return GestureDetector(
      onTap: () => _call(number),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  Text(description,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          height: 1.3)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Contact Support ──────────────────────────────────────────────

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.support_agent_rounded, 'Contact Support'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _navy.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _contactTile(
                icon: Icons.email_outlined,
                iconColor: _accent,
                title: 'Email Support',
                subtitle: 'info.ridemate@gmail.com',
                onTap: () => _openEmail('info.ridemate@gmail.com'),
              ),
              const Divider(height: 1, indent: 56),
              _contactTile(
                icon: Icons.phone_outlined,
                iconColor: Colors.blue.shade600,
                title: 'Call Support',
                subtitle: 'Mon–Fri, 8am–8pm',
                onTap: () => _call('0112345678'),
              ),
              const Divider(height: 1, indent: 56),
              _contactTile(
                icon: Icons.bug_report_outlined,
                iconColor: Colors.orange.shade600,
                title: 'Report a Problem',
                subtitle: 'Incorrect charge, app issue, driver complaint',
                onTap: () => _openEmail(
                    'report@ridemate.lk?subject=RideMate Problem Report'),
              ),
              const Divider(height: 1, indent: 56),
              _contactTile(
                icon: Icons.star_outline_rounded,
                iconColor: Colors.amber.shade600,
                title: 'Give Feedback',
                subtitle: 'Help us improve RideMate',
                onTap: () => _openEmail(
                    'feedback@ridemate.lk?subject=RideMate Feedback'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
      title: Text(title,
          style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: Colors.grey.shade400, size: 20),
      onTap: onTap,
    );
  }

  // ─── FAQ ─────────────────────────────────────────────────────────

  Widget _buildFaqSection() {
    final faqs = [
      _Faq(
        q: 'How is the ride cost calculated?',
        a: 'RideMate calculates cost based on distance and the number of passengers. The total ride cost is split proportionally — each passenger pays only for their segment of the journey, making it cheaper for everyone.',
      ),
      _Faq(
        q: 'How do I cancel a ride request?',
        a: 'Open the Active Rides tab and tap "Cancel Ride". You can cancel a pending or accepted ride request before the trip begins. Cancellation during an active trip may incur a small fee.',
      ),
      _Faq(
        q: 'What if the driver doesn\'t show up?',
        a: 'If the driver has not arrived within 10 minutes of the agreed start time, you can cancel the request without any charge. Please report the issue via Help & Support.',
      ),
      _Faq(
        q: 'How are drivers verified?',
        a: 'All RideMate drivers go through identity verification, vehicle registration, insurance checks and licence upload. A driver badge is only awarded after approval.',
      ),
      _Faq(
        q: 'Can I switch between Passenger and Driver?',
        a: 'Yes. Go to the Account tab and use the role selector. Complete your driver profile first to offer rides. You can switch freely as long as no active ride is in progress.',
      ),
      _Faq(
        q: 'What should I do in an emergency during a ride?',
        a: 'Tap the SOS button at the top of this screen or use the emergency panel in the Active Ride screen to instantly call Sri Lanka Police (119) or Ambulance (1990). Always stay calm and inform emergency services of your current location.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.quiz_outlined, 'Frequently Asked Questions'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _navy.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: faqs.asMap().entries.map((entry) {
              final i = entry.key;
              final faq = entry.value;
              final isExpanded = _faqExpanded[i] ?? false;
              return Column(
                children: [
                  if (i > 0) const Divider(height: 1, indent: 16),
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      childrenPadding: const EdgeInsets.fromLTRB(
                          16, 0, 16, 16),
                      leading: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? _accent.withOpacity(0.12)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isExpanded ? _accent : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        faq.q,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isExpanded ? _accent : _navy,
                        ),
                      ),
                      iconColor: _accent,
                      collapsedIconColor: Colors.grey.shade400,
                      onExpansionChanged: (v) =>
                          setState(() => _faqExpanded[i] = v),
                      children: [
                        Text(
                          faq.a,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Safety Tips ─────────────────────────────────────────────────

  Widget _buildSafetyTipsSection() {
    final tips = [
      _Tip(
        icon: Icons.share_location_rounded,
        title: 'Share Your Trip',
        body: 'Always share your live route with a trusted contact before starting a ride.',
        color: Colors.blue.shade600,
      ),
      _Tip(
        icon: Icons.verified_user_rounded,
        title: 'Verify Driver Details',
        body: 'Check the driver\'s name, photo, and vehicle plate before getting in.',
        color: _accent,
      ),
      _Tip(
        icon: Icons.no_photography_rounded,
        title: 'Protect Your Privacy',
        body: 'Do not share personal information such as your home address with strangers.',
        color: Colors.orange.shade700,
      ),
      _Tip(
        icon: Icons.front_hand_rounded,
        title: 'Trust Your Instincts',
        body: 'If you feel unsafe at any point, cancel the ride and move to a public place.',
        color: Colors.red.shade600,
      ),
      _Tip(
        icon: Icons.reviews_rounded,
        title: 'Rate Your Ride',
        body: 'Always leave a rating after your trip. It helps keep the RideMate community safe.',
        color: Colors.amber.shade700,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
            Icons.security_rounded, 'Safety Tips'),
        const SizedBox(height: 12),
        ...tips.map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _navy.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tip.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(tip.icon, color: tip.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tip.body,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared Helpers ───────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String title,
      {Color? color, Color? bg}) {
    final c = color ?? _navy;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (bg ?? _accent.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: c, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c,
          ),
        ),
      ],
    );
  }

  Future<void> _openEmail(String address) async {
    final uri = Uri.parse('mailto:$address');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }
}

// ─── Models ───────────────────────────────────────────────────────

class _Faq {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});
}

class _Tip {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _Tip(
      {required this.icon,
      required this.title,
      required this.body,
      required this.color});
}

