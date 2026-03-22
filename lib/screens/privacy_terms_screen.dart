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
        _intro(
          'RideMate ("we", "our", "us") is committed to protecting your personal '
          'information and your right to privacy. This Privacy Policy explains how we '
          'collect, use, store, and share your information when you use the RideMate '
          'mobile application and related services in Sri Lanka.',
        ),
        _section(
          icon: Icons.info_outline_rounded,
          title: '1. Information We Collect',
          color: const Color(0xFF03AF74),
          children: [
            _bulletItem('Personal Identification',
                'Full name, email address, phone number, National Identity Card (NIC) number, date of birth, and gender.'),
            _bulletItem('Location Data',
                'Real-time GPS location during active ride sessions to facilitate route matching and navigation.'),
            _bulletItem('Vehicle Information (Drivers)',
                'Vehicle registration number, make, model, colour, and insurance details.'),
            _bulletItem('Profile Photo',
                'Selfie captured during verification to confirm identity.'),
            _bulletItem('Usage Data',
                'Log data, device identifiers, app interactions, and ride history to improve the service.'),
          ],
        ),
        _section(
          icon: Icons.settings_suggest_outlined,
          title: '2. How We Use Your Information',
          color: const Color(0xFF1565C0),
          children: [
            _bulletItem('Ride Matching',
                'To connect drivers and passengers based on route, location, and ride preferences.'),
            _bulletItem('Verification & Safety',
                'To verify user identities and maintain a safe community on the platform.'),
            _bulletItem('Communication',
                'To send ride confirmations, updates, and important notifications via push or email.'),
            _bulletItem('Fare Calculation',
                'To estimate and split ride costs fairly using distance and route data.'),
            _bulletItem('Service Improvement',
                'To analyse usage patterns and continuously improve app features and performance.'),
          ],
        ),
        _section(
          icon: Icons.share_rounded,
          title: '3. Sharing Your Information',
          color: const Color(0xFF7B1FA2),
          children: [
            _bulletItem('Other Users',
                'Your first name, rating, vehicle details (for drivers), and general pickup/drop area are visible to matched ride partners.'),
            _bulletItem('Service Providers',
                'We work with trusted third parties (e.g., mapping and payment services) who process data on our behalf under strict confidentiality agreements.'),
            _bulletItem('Legal Obligations',
                'We may disclose your information if required by Sri Lankan law, court order, or to protect the rights and safety of users.'),
            _bulletItem('No Sale of Data',
                'We do not sell, rent, or trade your personal information to third parties for marketing purposes.'),
          ],
        ),
        _section(
          icon: Icons.lock_outline_rounded,
          title: '4. Data Security',
          color: const Color(0xFFE65100),
          children: [
            _bulletItem('Encryption',
                'All data transmitted between the app and our servers is encrypted using industry-standard TLS/HTTPS protocols.'),
            _bulletItem('Secure Storage',
                'Sensitive data (NIC, tokens) is stored in encrypted device storage (Flutter Secure Storage) and our secured cloud servers.'),
            _bulletItem('Access Controls',
                'Access to your data is restricted to authorised personnel and systems only.'),
          ],
        ),
        _section(
          icon: Icons.person_outline_rounded,
          title: '5. Your Rights',
          color: const Color(0xFF00838F),
          children: [
            _bulletItem('Access & Correction',
                'You can view and update your profile information at any time from the Account tab.'),
            _bulletItem('Data Deletion',
                'You may request deletion of your account and associated data by contacting us at privacy@ridemate.lk.'),
            _bulletItem('Opt-Out',
                'You can opt out of non-essential notifications through your device or app settings.'),
            _bulletItem('Data Portability',
                'Upon request, we can provide a copy of your personal data in a machine-readable format.'),
          ],
        ),
        _section(
          icon: Icons.child_care_rounded,
          title: '6. Children\'s Privacy',
          color: const Color(0xFF558B2F),
          children: [
            _plainText(
              'RideMate is not intended for users under the age of 18. We do not knowingly '
              'collect personal information from minors. If you believe a minor has provided '
              'us with personal information, please contact us immediately.',
            ),
          ],
        ),
        _section(
          icon: Icons.map_outlined,
          title: '7. Location Data',
          color: const Color(0xFF6D4C41),
          children: [
            _plainText(
              'Location access is only used during active ride sessions. We do not track '
              'your location in the background when you are not using the app. You can '
              'manage location permissions through your device settings at any time.',
            ),
          ],
        ),
        _section(
          icon: Icons.update_rounded,
          title: '8. Changes to This Policy',
          color: const Color(0xFF455A64),
          children: [
            _plainText(
              'We may update this Privacy Policy from time to time. We will notify you '
              'of any significant changes through the app or via email. Your continued use '
              'of RideMate after changes are posted constitutes your acceptance of the '
              'updated policy.',
            ),
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
        _intro(
          'These Terms of Use ("Terms") govern your access to and use of the RideMate '
          'application and services. By registering or using RideMate, you agree to be '
          'bound by these Terms. Please read them carefully.',
        ),
        _section(
          icon: Icons.check_circle_outline_rounded,
          title: '1. Eligibility',
          color: const Color(0xFF03AF74),
          children: [
            _bulletItem('Age Requirement',
                'You must be at least 18 years of age to use RideMate.'),
            _bulletItem('Valid NIC',
                'A valid Sri Lankan National Identity Card (NIC) is required for account verification.'),
            _bulletItem('Driving Licence (Drivers)',
                'Drivers must hold a valid Sri Lankan driving licence and maintain a road-worthy vehicle with active insurance.'),
          ],
        ),
        _section(
          icon: Icons.account_circle_outlined,
          title: '2. User Accounts',
          color: const Color(0xFF1565C0),
          children: [
            _bulletItem('Accurate Information',
                'You must provide accurate and truthful information during registration and keep it up to date.'),
            _bulletItem('Account Security',
                'You are responsible for maintaining the confidentiality of your account credentials. Do not share your account with others.'),
            _bulletItem('One Account',
                'Each user is permitted one active account. Creating duplicate accounts may result in suspension.'),
          ],
        ),
        _section(
          icon: Icons.directions_car_outlined,
          title: '3. Ride Services',
          color: const Color(0xFF7B1FA2),
          children: [
            _bulletItem('Ride Matching',
                'RideMate is a carpooling platform. Drivers offer seats on their existing journeys; we do not provide a taxi or transport service.'),
            _bulletItem('Fare Estimation',
                'Costs displayed are estimates based on distance and route. Final fares are agreed between driver and passengers.'),
            _bulletItem('Ride Preferences',
                'Users may apply gender-based ride preferences (Male/Female/Both). These preferences are optional but must be respected once set.'),
            _bulletItem('Cancellations',
                'Repeated last-minute cancellations may result in account restrictions. Users should cancel promptly if plans change.'),
          ],
        ),
        _section(
          icon: Icons.handshake_outlined,
          title: '4. User Conduct',
          color: const Color(0xFFE65100),
          children: [
            _bulletItem('Respectful Behaviour',
                'All users must treat fellow passengers and drivers with courtesy and respect.'),
            _bulletItem('No Discrimination',
                'Discrimination based on race, gender, religion, disability, or any other characteristic is strictly prohibited.'),
            _bulletItem('Prohibited Activities',
                'Using RideMate to harass, defraud, or harm others; carrying illegal items; or operating under the influence of alcohol/drugs is prohibited.'),
            _bulletItem('Accurate Ride Details',
                'Drivers must only offer rides they genuinely intend to make. Fictitious ride listings are a breach of these Terms.'),
          ],
        ),
        _section(
          icon: Icons.shield_outlined,
          title: '5. Safety & Liability',
          color: const Color(0xFF00838F),
          children: [
            _bulletItem('Emergency Features',
                'The SOS feature connects you to emergency services. Please use responsibly.'),
            _bulletItem('No Transport Liability',
                'RideMate is a technology platform facilitating connections between users. We are not a transportation company and do not assume liability for road incidents.'),
            _bulletItem('Insurance',
                'Users travel at their own risk. Drivers are responsible for maintaining adequate vehicle insurance.'),
            _bulletItem('Reporting',
                'Any safety incident must be reported via the "Report a Problem" feature or by calling Sri Lanka Police on 119.'),
          ],
        ),
        _section(
          icon: Icons.payment_outlined,
          title: '6. Payments & Refunds',
          color: const Color(0xFF558B2F),
          children: [
            _plainText(
              'Fare contributions are currently handled directly between drivers and passengers. '
              'In the event of a dispute regarding charges, please use the "Report a Problem" '
              'feature. RideMate reserves the right to introduce in-app payment processing '
              'in the future with reasonable advance notice.',
            ),
          ],
        ),
        _section(
          icon: Icons.block_outlined,
          title: '7. Suspension & Termination',
          color: const Color(0xFF6D4C41),
          children: [
            _plainText(
              'RideMate reserves the right to suspend or terminate any account that violates '
              'these Terms, engages in fraudulent activity, poses a safety risk to others, or '
              'receives multiple substantiated complaints. Users can appeal account decisions '
              'by contacting our support team.',
            ),
          ],
        ),
        _section(
          icon: Icons.gavel_rounded,
          title: '8. Governing Law',
          color: const Color(0xFF455A64),
          children: [
            _plainText(
              'These Terms are governed by the laws of Sri Lanka. Any disputes arising from '
              'the use of RideMate shall be subject to the exclusive jurisdiction of the '
              'courts of Sri Lanka.',
            ),
          ],
        ),
        _section(
          icon: Icons.update_rounded,
          title: '9. Changes to Terms',
          color: const Color(0xFF37474F),
          children: [
            _plainText(
              'We may modify these Terms at any time. We will notify you of material changes '
              'through the app. Your continued use of RideMate following notification of '
              'changes constitutes acceptance of the updated Terms.',
            ),
          ],
        ),
        _contactCard(
          icon: Icons.support_agent_rounded,
          label: 'Legal & Support',
          value: 'support@ridemate.lk',
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

