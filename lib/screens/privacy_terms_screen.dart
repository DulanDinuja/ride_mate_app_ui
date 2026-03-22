import 'package:flutter/material.dart';

import '../widgets/custom_back_button.dart';

/// Displays Privacy Policy and Terms of Service in a tabbed layout.
class PrivacyTermsScreen extends StatelessWidget {
  const PrivacyTermsScreen({super.key});

  static const Color _accent = Color(0xFF03AF74);
  static const Color _navy = Color(0xFF040F1B);
  static const Color _cream = Color(0xFFFFFFF0);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF040F1B), Color(0xFF0A2240)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          CustomBackButton(
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Privacy & Terms',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _accent.withOpacity(0.5), width: 1),
                            ),
                            child: const Text(
                              'v1.0',
                              style: TextStyle(
                                color: Color(0xFF03AF74),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TabBar(
                      indicatorColor: _accent,
                      indicatorWeight: 3,
                      labelColor: _accent,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.privacy_tip_outlined, size: 20),
                          text: 'Privacy Policy',
                        ),
                        Tab(
                          icon: Icon(Icons.gavel_rounded, size: 20),
                          text: 'Terms of Use',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Tab content ────────────────────────────────────────────
            const Expanded(
              child: TabBarView(
                children: [
                  _PrivacyPolicyTab(),
                  _TermsOfUseTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Privacy Policy Tab
// ─────────────────────────────────────────────────────────────────────────────
class _PrivacyPolicyTab extends StatelessWidget {
  const _PrivacyPolicyTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _effectiveDate('Effective Date: 22 March 2026'),
        _intro('RideMate is committed to protecting your privacy. This policy outlines how we handle your data within Sri Lanka.'),
        _section(
          icon: Icons.info_outline_rounded,
          title: '1. Information We Collect',
          color: const Color(0xFF03AF74),
          children: [
            _bulletItem('Identity', 'Name, email, phone number, NIC, and gender.'),
            _bulletItem('Location', 'GPS during active ride sessions only.'),
            _bulletItem('Vehicle (Drivers)', 'Registration, make, model, and insurance.'),
            _bulletItem('Usage', 'App interactions and ride history.'),
          ],
        ),
        _section(
          icon: Icons.settings_suggest_outlined,
          title: '2. How We Use It',
          color: const Color(0xFF1565C0),
          children: [
            _bulletItem('Ride Matching', 'Connect drivers and passengers by route and preference.'),
            _bulletItem('Verification', 'Confirm identities to keep the community safe.'),
            _bulletItem('Notifications', 'Ride updates and important alerts.'),
            _bulletItem('Improvement', 'Analyse usage to enhance app performance.'),
          ],
        ),
        _section(
          icon: Icons.share_rounded,
          title: '3. Sharing Your Data',
          color: const Color(0xFF7B1FA2),
          children: [
            _bulletItem('Ride Partners', 'First name and general location shown to matched users.'),
            _bulletItem('Third Parties', 'Only trusted providers (maps, payments) under strict agreements.'),
            _bulletItem('Legal', 'Disclosed if required by Sri Lankan law.'),
            _bulletItem('No Sale', 'We never sell your data.'),
          ],
        ),
        _section(
          icon: Icons.lock_outline_rounded,
          title: '4. Security & Your Rights',
          color: const Color(0xFFE65100),
          children: [
            _bulletItem('Encryption', 'All data transmitted via TLS/HTTPS.'),
            _bulletItem('Access', 'Update your profile anytime from the Account tab.'),
            _bulletItem('Deletion', 'Request account removal at info.ridemate@gmail.com.'),
            _bulletItem('Location', 'Not tracked in the background — only during rides.'),
          ],
        ),
        _contactCard(
          icon: Icons.email_outlined,
          label: 'Privacy Enquiries',
          value: 'info.ridemate@gmail.com',
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Terms of Use Tab
// ─────────────────────────────────────────────────────────────────────────────
class _TermsOfUseTab extends StatelessWidget {
  const _TermsOfUseTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _effectiveDate('Effective Date: 22 March 2026'),
        _intro('By using RideMate you agree to these Terms. Please read them carefully before proceeding.'),
        _section(
          icon: Icons.check_circle_outline_rounded,
          title: '1. Eligibility',
          color: const Color(0xFF03AF74),
          children: [
            _bulletItem('Age', 'Must be 18 years or older.'),
            _bulletItem('NIC', 'A valid Sri Lankan NIC is required.'),
            _bulletItem('Drivers', 'Must hold a valid driving licence and insured vehicle.'),
          ],
        ),
        _section(
          icon: Icons.account_circle_outlined,
          title: '2. Accounts & Conduct',
          color: const Color(0xFF1565C0),
          children: [
            _bulletItem('Accuracy', 'Provide truthful information and keep it updated.'),
            _bulletItem('One Account', 'Duplicate accounts may be suspended.'),
            _bulletItem('Respect', 'Treat all users with courtesy. Harassment is prohibited.'),
            _bulletItem('No Fraud', 'Fictitious ride listings breach these Terms.'),
          ],
        ),
        _section(
          icon: Icons.directions_car_outlined,
          title: '3. Ride Services',
          color: const Color(0xFF7B1FA2),
          children: [
            _bulletItem('Carpooling Only', 'RideMate connects users — it is not a taxi service.'),
            _bulletItem('Fares', 'Cost estimates are indicative; final fares are agreed between users.'),
            _bulletItem('Cancellations', 'Repeated cancellations may restrict your account.'),
          ],
        ),
        _section(
          icon: Icons.shield_outlined,
          title: '4. Safety & Liability',
          color: const Color(0xFF00838F),
          children: [
            _bulletItem('SOS', 'Use the emergency feature responsibly.'),
            _bulletItem('Liability', 'RideMate is not liable for road incidents — users ride at own risk.'),
            _bulletItem('Governing Law', 'These Terms are governed by the laws of Sri Lanka.'),
          ],
        ),
        _contactCard(
          icon: Icons.support_agent_rounded,
          label: 'Legal & Support',
          value: 'info.ridemate@gmail.com',
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Widget Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _effectiveDate(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF03AF74).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFF03AF74).withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_note_rounded,
                size: 16, color: Color(0xFF03AF74)),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF03AF74),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

Widget _intro(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF555555),
          height: 1.6,
        ),
      ),
    );

Widget _section({
  required IconData icon,
  required String title,
  required Color color,
  required List<Widget> children,
}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(
                left: BorderSide(color: color, width: 4),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // section body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );

Widget _bulletItem(String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF03AF74),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  TextSpan(
                    text: body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

Widget _plainText(String text) => Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF555555),
        height: 1.6,
      ),
    );

Widget _contactCard({
  required IconData icon,
  required String label,
  required String value,
}) =>
    Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF040F1B), Color(0xFF0A2240)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF03AF74).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF03AF74), size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );

