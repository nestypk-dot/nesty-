import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Bookings',
    'Hosting',
    'Payments',
    'Account & Security',
  ];

  final List<Map<String, String>> _faqs = [
    {
      'category': 'Bookings',
      'question': 'How do I book a stay on Nesty?',
      'answer':
          'Browse properties on Home or Search, select your dates and number of guests, click "Request to Book", choose your payment option (Easypaisa, JazzCash, Card, or Cash on Check-in), and submit. The host will review and accept your booking.',
    },
    {
      'category': 'Bookings',
      'question': 'Can I cancel my booking request?',
      'answer':
          'Yes, you can cancel any pending or confirmed booking request from the "My Trips" screen or by viewing your trip details. Refunds are processed according to the property\'s cancellation policy.',
    },
    {
      'category': 'Hosting',
      'question': 'How do I become a host on Nesty?',
      'answer':
          'Go to your Profile, tap "Switch to Hosting" or "Become a Host". Fill in your primary contact info, upload your CNIC/Passport verification, and submit for Admin approval. Once approved, you can start listing your properties.',
    },
    {
      'category': 'Hosting',
      'question': 'How do I get paid for guest bookings?',
      'answer':
          'Earnings from completed guest stays are transferred directly to your registered bank account, JazzCash, or Easypaisa wallet within 24 hours of guest check-in.',
    },
    {
      'category': 'Payments',
      'question': 'What payment methods are supported?',
      'answer':
          'Nesty supports JazzCash, Easypaisa, Credit/Debit Cards (Visa/Mastercard), Bank Transfer, and Pay at Property for eligible listings in Pakistan.',
    },
    {
      'category': 'Payments',
      'question': 'Is my payment secure?',
      'answer':
          'Yes, all online transactions are encrypted via 256-bit SSL encryption and processed using state-of-the-art payment gateways.',
    },
    {
      'category': 'Account & Security',
      'question': 'How do I reset my password?',
      'answer':
          'Go to Settings > Change Password. A password reset link will be sent to your registered email address instantly.',
    },
    {
      'category': 'Account & Security',
      'question': 'How do I update my profile picture or phone number?',
      'answer':
          'Go to Settings > Edit Profile or Phone Number. Changes are synced live across your guest and host profiles.',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    return _faqs.where((faq) {
      final matchesCategory =
          _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          faq['question']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showContactSupportSheet() {
    final messageController = TextEditingController();
    String subject = 'General Inquiry';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contact Nesty Support',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Select Topic',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: subject,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: [
                  'General Inquiry',
                  'Booking Problem',
                  'Payment & Refund Issue',
                  'Host Verification',
                  'Report Bug',
                ]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setSheetState(() => subject = val);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Describe Your Request',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your message or question here...',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final text = messageController.text.trim();
                          if (text.isEmpty) return;
                          setSheetState(() => isSubmitting = true);

                          final user = FirebaseAuth.instance.currentUser;
                          try {
                            await FirebaseFirestore.instance
                                .collection('support_tickets')
                                .add({
                              'userId': user?.uid ?? 'guest',
                              'userEmail': user?.email ?? 'anonymous',
                              'userName': user?.displayName ?? 'User',
                              'subject': subject,
                              'message': text,
                              'status': 'open',
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Support ticket submitted! Our team will contact you shortly.',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700),
                                ),
                                backgroundColor: const Color(0xFF00674F),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            setSheetState(() => isSubmitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Submit Ticket',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          'Help Center',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ── Search & Filter Banner ─────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search help topics, questions...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: Colors.grey.shade400),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 13,
                          ),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── FAQ List ──────────────────────────────
          Expanded(
            child: _filteredFaqs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.help_outline_rounded,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'No matching questions found',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try searching with different keywords',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = _filteredFaqs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            childrenPadding: const EdgeInsets.fromLTRB(
                                16, 0, 16, 16),
                            title: Text(
                              faq['question']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: Colors.black87,
                              ),
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.question_answer_outlined,
                                  color: Color(0xFF00674F), size: 18),
                            ),
                            children: [
                              Text(
                                faq['answer']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showContactSupportSheet,
        backgroundColor: const Color(0xFF00674F),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.headset_mic_rounded, size: 20),
        label: Text(
          'Contact Support',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900, fontSize: 13.5),
        ),
      ),
    );
  }
}
