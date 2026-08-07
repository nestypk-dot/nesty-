import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/settings'),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nesty Privacy Policy',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF00674F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: July 2026 • Effective in Pakistan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    '1. Information We Collect',
                    'When you register, book a property, or become a host on Nesty, we collect personal information including your full name, email address, phone number, profile photo, government verification documents (CNIC/Passport for hosts), and payment transaction details.',
                  ),
                  _buildSection(
                    '2. How We Use Your Data',
                    'Your data is used to process bookings, verify host identities, facilitate guest-host communication via in-app chat and calls, send booking confirmations and SMS/Email notifications, and protect against fraudulent activities.',
                  ),
                  _buildSection(
                    '3. Data Protection & Firebase Security',
                    'All user data and uploaded documents are securely stored using Firebase Cloud Firestore and Firebase Storage with end-to-end SSL/TLS encryption. We enforce strict database access control rules so that personal documents remain strictly confidential.',
                  ),
                  _buildSection(
                    '4. Location & Device Information',
                    'With your permission, Nesty uses your device location to show nearby rental properties in Swat, Kalam, Malam Jabba, Islamabad, and other destinations across Pakistan.',
                  ),
                  _buildSection(
                    '5. Sharing of Information',
                    'We do not sell your personal data. Limited contact details (name and phone number) are shared between a guest and host only after a booking is confirmed to coordinate check-in.',
                  ),
                  _buildSection(
                    '6. Your Data Rights & Account Deletion',
                    'You have full control over your personal data. You can edit your profile at any time or permanently delete your account and associated data from Settings > Delete Account.',
                  ),
                  _buildSection(
                    '7. Contact Us',
                    'If you have any privacy questions or requests regarding your data, contact our Data Protection Officer at privacy@nesty.pk.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
