import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
                    'Nesty Terms of Service',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF00674F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: July 2026 • Governing Laws of Pakistan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    '1. Agreement to Terms',
                    'By accessing or using the Nesty platform (mobile application and website), you agree to be bound by these Terms of Service and all applicable laws of Pakistan.',
                  ),
                  _buildSection(
                    '2. Platform Services',
                    'Nesty provides an online marketplace that connects hosts offering verified residential accommodations (hotels, resorts, apartments, cottages, guest houses) with guests seeking short-term rentals across Pakistan.',
                  ),
                  _buildSection(
                    '3. Host Responsibilities & Verification',
                    'Hosts must provide accurate property details, honest pricing, clear photos, and valid CNIC/Passport identity verification. Hosts are responsible for maintaining safe, clean, and accessible accommodations for guests.',
                  ),
                  _buildSection(
                    '4. Guest Booking & Conduct',
                    'Guests agree to treat properties and local communities with respect, adhere to house rules, avoid illegal activities, and check out by the agreed time. Any damage to property may result in penalty charges or account suspension.',
                  ),
                  _buildSection(
                    '5. Payments, Fees & Cancellations',
                    'All bookings must be processed through Nesty approved payment channels (Easypaisa, JazzCash, Card, or Cash on Arrival). Cancellations and refunds are governed by the property cancellation policy specified at the time of booking.',
                  ),
                  _buildSection(
                    '6. Dispute Resolution & Complaints',
                    'In case of disputes or property grievances, users can file a formal ticket using the Complaints Manager. Nesty support will investigate and arbitrate fairly according to documented evidence.',
                  ),
                  _buildSection(
                    '7. Limitation of Liability',
                    'Nesty is a venue connecting hosts and guests. While we verify hosts and properties, Nesty is not liable for indirect damages, personal injuries, or loss of personal property during stays.',
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
