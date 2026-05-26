import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final VoidCallback onAccepted;
  const PrivacyPolicyScreen({super.key, required this.onAccepted});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with SingleTickerProviderStateMixin {
  bool _acknowledged = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (!_acknowledged) return;
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);
    widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA);
    final cardBg   = isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF);
    final border   = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
    final primary  = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0A0A0A);
    final secondary= isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    final accent   = const Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: bg,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('N',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NOVE',
                                style: GoogleFonts.lora(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primary)),
                            Text('Privacy Policy & Terms of Service',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11, color: secondary)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text('Before you begin',
                        style: GoogleFonts.lora(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: primary,
                            height: 1.2)),
                    const SizedBox(height: 6),
                    Text(
                      'Please read our full Terms of Service and Privacy Policy carefully before using NOVE.',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: secondary, height: 1.5),
                    ),
                  ],
                ),
              ),

              // ── Scrollable content ────────────────────────────────────────
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Scrollbar(
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ════════════════════════════════════════════════
                            //  TERMS OF SERVICE
                            // ════════════════════════════════════════════════
                            _sectionHeader('📋  Terms of Service', primary),
                            _meta('Last updated: ${_formattedDate()}', secondary),
                            _para('Welcome to NOVE ("the App"), a premium note-taking application developed by an independent developer ("Developer", "we", "us"). By installing, downloading, accessing, or using NOVE, you agree to be legally bound by these Terms of Service ("Terms") and our Privacy Policy. If you do not agree to any part of these Terms, you must immediately uninstall and stop using the App.', secondary),

                            _sub('1. Acceptance of Terms', primary),
                            _para('By using NOVE, you represent that you are at least 13 years of age (or the minimum age of digital consent in your jurisdiction). If you are using the App on behalf of an organization, you represent that you have the authority to bind that organization to these Terms. These Terms form a legally binding agreement between you and the Developer.', secondary),

                            _sub('2. License to Use', primary),
                            _para('The Developer grants you a limited, non-exclusive, non-transferable, revocable license to download and use NOVE on your personal Android device solely for your personal, non-commercial purposes. This license does not include:', secondary),
                            _bullet('Selling, reselling, or commercially exploiting the App or its content', secondary),
                            _bullet('Copying, reproducing, or distributing any part of the App', secondary),
                            _bullet('Modifying, reverse engineering, decompiling, or disassembling the App', secondary),
                            _bullet('Using the App to build a competing product or service', secondary),
                            _bullet('Removing any copyright, trademark, or other proprietary notices', secondary),

                            _sub('3. Advertisement Disclosure & Third-Party Ads', primary),
                            _highlight('⚠️  This App contains advertisements served by AdMaven, a third-party advertising network.', accent, isDark),
                            _para('NOVE is a free application supported by advertisements. By using this App, you explicitly acknowledge and agree to the following:', secondary),
                            _bullet('Advertisements displayed in NOVE are exclusively provided and managed by AdMaven and its partner networks.', secondary),
                            _bullet('The Developer has NO control over the content, type, frequency, or quality of advertisements shown.', secondary),
                            _bullet('The Developer is NOT responsible for any products, services, claims, offers, or content advertised through AdMaven.', secondary),
                            _bullet('Any purchase, transaction, or engagement you make with an advertiser is solely between you and that advertiser. The Developer has no liability for such interactions.', secondary),
                            _bullet('Advertisements may automatically open external websites or applications. The Developer is not responsible for the content, safety, accuracy, or legality of any such external destinations.', secondary),
                            _bullet('The Developer disclaims all liability for any financial loss, personal harm, data breach, or any other damages arising from advertisements or any content accessed through advertisement links.', secondary),
                            _bullet('AdMaven may use device identifiers and browsing data to serve personalized ads. This is governed by AdMaven\'s own Privacy Policy.', secondary),
                            _bullet('You agree not to attempt to block, interfere with, or circumvent the advertisement delivery system.', secondary),
                            _highlight('📌  The Developer of NOVE is not affiliated with, endorsed by, or responsible for any advertiser or advertisement content. All ad-related complaints must be directed to AdMaven.', accent, isDark),

                            _sub('4. User-Generated Content', primary),
                            _para('NOVE allows you to create, store, and manage personal notes ("User Content"). With respect to User Content:', secondary),
                            _bullet('You retain full ownership of all notes and content you create within NOVE.', secondary),
                            _bullet('The Developer does not access, view, collect, or transmit your User Content to any server.', secondary),
                            _bullet('You are solely responsible for the legality, accuracy, and appropriateness of your User Content.', secondary),
                            _bullet('You agree not to create notes that contain illegal, harmful, defamatory, or infringing content.', secondary),
                            _bullet('Since data is stored locally, the Developer cannot recover deleted notes. You are responsible for your own backups.', secondary),

                            _sub('5. Data Loss & Backup', primary),
                            _para('All notes are stored locally on your device. The Developer is NOT responsible for any data loss resulting from:', secondary),
                            _bullet('Device failure, reset, or damage', secondary),
                            _bullet('Accidental deletion by the user', secondary),
                            _bullet('App uninstallation', secondary),
                            _bullet('Operating system updates or failures', secondary),
                            _bullet('Any other cause beyond the Developer\'s control', secondary),
                            _para('We strongly recommend regularly exporting important notes using the PDF export feature.', secondary),

                            _sub('6. App Updates & Changes', primary),
                            _para('The Developer reserves the right to update, modify, suspend, or discontinue NOVE or any part of it at any time without notice. The Developer shall not be liable to you or any third party for any modification, suspension, or discontinuation of the App.', secondary),

                            _sub('7. Prohibited Uses', primary),
                            _para('You agree that you will NOT use NOVE to:', secondary),
                            _bullet('Violate any applicable local, national, or international law or regulation', secondary),
                            _bullet('Engage in any activity that is harmful, fraudulent, deceptive, or offensive', secondary),
                            _bullet('Attempt to gain unauthorized access to any part of the App', secondary),
                            _bullet('Introduce viruses, malware, or other malicious code', secondary),
                            _bullet('Scrape, mine, or extract data from the App by automated means', secondary),
                            _bullet('Use the App in any way that could damage, disable, or impair the App', secondary),

                            _sub('8. Accessibility Service Permission', primary),
                            _highlight('🔒  NOVE may request Accessibility Service permission for certain overlay and automation features.', accent, isDark),
                            _para('The Accessibility Service permission, if granted, is used solely for the App\'s overlay and note-linking features. This permission is NOT used to collect, read, or transmit any personal data, keystrokes, or sensitive information from your device. You may revoke this permission at any time in your device settings.', secondary),

                            _sub('9. Intellectual Property', primary),
                            _para('All rights, title, and interest in and to NOVE, including all associated intellectual property rights, are owned by the Developer. The NOVE name, logo, and design are proprietary to the Developer. Nothing in these Terms grants you any right to use the Developer\'s intellectual property without prior written permission.', secondary),

                            _sub('10. Disclaimer of Warranties', primary),
                            _para('NOVE is provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind, express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, non-infringement, accuracy, or reliability. The Developer does not warrant that the App will be error-free, uninterrupted, secure, or that any defects will be corrected.', secondary),

                            _sub('11. Limitation of Liability', primary),
                            _para('To the fullest extent permitted by applicable law, the Developer shall not be liable for any indirect, incidental, special, consequential, exemplary, or punitive damages, including but not limited to:', secondary),
                            _bullet('Loss of data, profits, revenue, or business', secondary),
                            _bullet('Damages arising from advertisements or third-party content', secondary),
                            _bullet('Damages resulting from unauthorized access to your data', secondary),
                            _bullet('Any other damages arising from your use of or inability to use the App', secondary),
                            _para('In no event shall the Developer\'s total liability exceed the amount you paid for the App in the past twelve months (which is zero, as the App is free).', secondary),

                            _sub('12. Indemnification', primary),
                            _para('You agree to indemnify, defend, and hold harmless the Developer from and against any claims, liabilities, damages, losses, and expenses, including reasonable legal fees, arising out of or in any way connected with your access to or use of NOVE, your User Content, or your violation of these Terms.', secondary),

                            _sub('13. Governing Law', primary),
                            _para('These Terms shall be governed by and construed in accordance with the laws of India. Any disputes arising under these Terms shall be subject to the exclusive jurisdiction of the courts located in India.', secondary),

                            _sub('14. Severability', primary),
                            _para('If any provision of these Terms is found to be unenforceable or invalid, that provision will be limited or eliminated to the minimum extent necessary so that the remaining Terms will remain in full force and effect.', secondary),

                            _sub('15. Entire Agreement', primary),
                            _para('These Terms, together with the Privacy Policy, constitute the entire agreement between you and the Developer regarding your use of NOVE and supersede all prior agreements, representations, and understandings.', secondary),

                            _sub('16. Changes to Terms', primary),
                            _para('The Developer reserves the right to modify these Terms at any time. We will notify users of significant changes by updating the "Last Updated" date. Continued use of the App after changes constitutes acceptance of the revised Terms.', secondary),

                            const SizedBox(height: 24),
                            Divider(color: border, thickness: 1),
                            const SizedBox(height: 24),

                            // ════════════════════════════════════════════════
                            //  PRIVACY POLICY
                            // ════════════════════════════════════════════════
                            _sectionHeader('🔒  Privacy Policy', primary),
                            _meta('Last updated: ${_formattedDate()}', secondary),
                            _para('This Privacy Policy explains how NOVE ("the App") handles your information. We are committed to protecting your privacy. Please read this policy carefully.', secondary),

                            _sub('1. Information the Developer Collects', primary),
                            _highlight('✅  The Developer of NOVE does NOT collect any personal data from users.', accent, isDark),
                            _para('All notes, settings, preferences, and data you create or store in NOVE remain entirely on your local device. The Developer has no access to your notes or personal information at any time.', secondary),

                            _sub('2. Information Collected by AdMaven (Third-Party Ads)', primary),
                            _highlight('📢  AdMaven, our advertising partner, may collect certain data to serve ads.', accent, isDark),
                            _para('As NOVE displays advertisements provided by AdMaven, AdMaven and its partners may automatically collect:', secondary),
                            _bullet('Advertising ID (Google Advertising ID / Android ID)', secondary),
                            _bullet('IP address and approximate geographic location', secondary),
                            _bullet('Device information (model, OS version, screen size)', secondary),
                            _bullet('App version and usage patterns', secondary),
                            _bullet('Ad interaction data (impressions, clicks, conversions)', secondary),
                            _bullet('Network connection type', secondary),
                            _para('This data collection is entirely governed by AdMaven\'s Privacy Policy. The Developer has no control over AdMaven\'s data collection, processing, or retention practices. We strongly encourage you to review AdMaven\'s Privacy Policy at: admaven.com/privacy-policy', secondary),

                            _sub('3. App Permissions & Their Purpose', primary),
                            _bullet('INTERNET — Required for loading and displaying advertisements', secondary),
                            _bullet('ACCESS_NETWORK_STATE — Used by AdMaven to check network availability', secondary),
                            _bullet('POST_NOTIFICATIONS — To deliver note reminders you schedule', secondary),
                            _bullet('USE_BIOMETRIC — For optional app lock/biometric authentication', secondary),
                            _bullet('SYSTEM_ALERT_WINDOW — For optional overlay/floating window feature', secondary),
                            _bullet('RECEIVE_BOOT_COMPLETED — To restore scheduled reminders after device restart', secondary),
                            _bullet('VIBRATE — For haptic feedback', secondary),
                            _bullet('SCHEDULE_EXACT_ALARM — For precise reminder notifications', secondary),
                            _bullet('QUERY_ALL_PACKAGES — For app linking feature in notes', secondary),
                            _bullet('FOREGROUND_SERVICE — For overlay window service', secondary),

                            _sub('4. Local Data Storage', primary),
                            _para('All notes, attachments, categories, and settings are stored in your device\'s local storage using SQLite and SharedPreferences. This data never leaves your device unless you manually export it (e.g., via PDF export or sharing). The Developer has no access to this data.', secondary),

                            _sub('5. Data Sharing', primary),
                            _para('The Developer does not share, sell, rent, or trade your personal information with any third parties. The only data sharing that occurs is between your device and AdMaven\'s servers for ad delivery purposes, as described above.', secondary),

                            _sub('6. Data Retention & Deletion', primary),
                            _para('Since all data is stored locally on your device, you can delete all App data at any time by:', secondary),
                            _bullet('Uninstalling the App from your device', secondary),
                            _bullet('Clearing App data from your device\'s Settings → Apps → NOVE → Clear Data', secondary),
                            _para('The Developer does not retain any copies of your data as we do not collect it in the first place.', secondary),

                            _sub('7. Security', primary),
                            _para('We implement appropriate technical measures within the App to protect your data. However, since data is stored on your device, the overall security also depends on your device\'s security settings. We recommend enabling device encryption, screen lock, and using NOVE\'s built-in biometric lock feature for sensitive notes.', secondary),

                            _sub('8. Children\'s Privacy (COPPA Compliance)', primary),
                            _para('NOVE is not directed to children under the age of 13. We do not knowingly collect personal information from children. If you are a parent or guardian and believe your child has used the App, please note that the Developer does not collect any personal data. However, AdMaven\'s ad network may collect device identifiers; please review AdMaven\'s COPPA compliance policies.', secondary),

                            _sub('9. Your Rights', primary),
                            _para('Depending on your jurisdiction, you may have rights regarding your personal data including:', secondary),
                            _bullet('Right to access — Know what data is collected about you', secondary),
                            _bullet('Right to deletion — Request deletion of your data', secondary),
                            _bullet('Right to opt-out — Opt out of personalized advertising via your device\'s ad settings (Settings → Google → Ads → Opt out of Ads Personalization)', secondary),
                            _bullet('Right to data portability — Export your notes using the PDF export feature', secondary),

                            _sub('10. Third-Party Links & Services', primary),
                            _para('Advertisements displayed in NOVE may link to third-party websites or services. The Developer is not responsible for the privacy practices or content of these third-party destinations. We encourage you to review the privacy policies of any third-party sites you visit through ad links.', secondary),

                            _sub('11. Changes to This Privacy Policy', primary),
                            _para('The Developer reserves the right to update this Privacy Policy at any time. Changes will be reflected by updating the "Last Updated" date at the top of this policy. Continued use of the App after changes constitutes acceptance of the updated policy.', secondary),

                            _sub('12. Contact Us', primary),
                            _para('If you have any questions, concerns, or requests regarding these Terms of Service or Privacy Policy, please contact the developer through the App\'s support channel or feedback option within the App settings.', secondary),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Accept section ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _acknowledged = !_acknowledged);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _acknowledged
                              ? accent.withOpacity(0.08)
                              : cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _acknowledged ? accent : border,
                            width: _acknowledged ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _acknowledged
                                    ? accent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      _acknowledged ? accent : secondary,
                                  width: 2,
                                ),
                              ),
                              child: _acknowledged
                                  ? const Icon(Icons.check_rounded,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'I acknowledge that I have read, understood, and agree to NOVE\'s Terms of Service and Privacy Policy, including the advertisement disclosure stating that the Developer is not responsible for third-party ad content served by AdMaven.',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: _acknowledged ? primary : secondary,
                                  height: 1.55,
                                  fontWeight: _acknowledged
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _acknowledged ? 1.0 : 0.4,
                      child: GestureDetector(
                        onTap: _acknowledged ? _accept : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: _acknowledged
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6C63FF),
                                      Color(0xFF3B82F6)
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: _acknowledged ? null : border,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _acknowledged
                                ? [
                                    BoxShadow(
                                      color: accent.withOpacity(0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Accept & Continue →',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, Color primary) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: GoogleFonts.lora(
                fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
      );

  Widget _meta(String text, Color secondary) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: GoogleFonts.dmSans(
                fontSize: 11,
                color: secondary,
                fontStyle: FontStyle.italic)),
      );

  Widget _sub(String title, Color primary) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(title,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: primary)),
      );

  Widget _para(String text, Color secondary) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: GoogleFonts.dmSans(
                fontSize: 13, color: secondary, height: 1.6)),
      );

  Widget _bullet(String text, Color secondary) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: secondary, height: 1.6)),
            ),
          ],
        ),
      );

  Widget _highlight(String text, Color accent, bool isDark) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withOpacity(0.3), width: 1),
        ),
        child: Text(text,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent)),
      );

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}