import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/nesty_image.dart';
import '../../../shared/widgets/full_screen_image_gallery.dart';
import '../../host_onboarding/domain/host_profile.dart';
import '../providers/admin_provider.dart';

class AdminHostDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdminHostDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<AdminHostDetailScreen> createState() => _AdminHostDetailScreenState();
}

class _AdminHostDetailScreenState extends ConsumerState<AdminHostDetailScreen> {
  bool _isActionInProgress = false;

  void _showImage(BuildContext context, String? url) {
    if (url == null || url.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenImageGallery(
          images: [url],
          initialIndex: 0,
        ),
      ),
    );
  }

  void _handleApprove() async {
    setState(() => _isActionInProgress = true);
    try {
      await ref.read(adminControllerProvider).approveHost(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Host approved successfully!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving host: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  void _handleReject() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Reject Application',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please enter the reason for rejection:',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Broken or unreadable Police Character Certificate...',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a rejection reason')),
                  );
                  return;
                }
                Navigator.pop(context);
                setState(() => _isActionInProgress = true);
                try {
                  await ref.read(adminControllerProvider).rejectHost(widget.userId, reason);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Host application rejected.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    context.pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isActionInProgress = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Reject',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Review Host Application',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('host_profiles').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Host Profile not found.',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          }

          final host = HostProfile.fromFirestore(snapshot.data!);

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Host profile card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: host.profilePhotoUrl != null
                                ? NestyImage(src: host.profilePhotoUrl!, width: 60, height: 60, fit: BoxFit.cover)
                                : Container(width: 60, height: 60, color: const Color(0xFFE2E8F0)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  host.fullName,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  host.email,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  host.primaryPhone,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description Box
                    _buildSectionHeader('Description Box / About Host'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        host.aboutHost.isNotEmpty ? host.aboutHost : "No description provided.",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Identity Photo Comparison
                    _buildSectionHeader('Identity Comparison'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImageDocCard(
                            context,
                            'Profile Photo',
                            host.profilePhotoUrl,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildImageDocCard(
                            context,
                            'Selfie (Realtime)',
                            host.selfieUrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // CNIC Verification
                    _buildSectionHeader('CNIC Verification'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge_outlined, color: Color(0xFF475569)),
                          const SizedBox(width: 10),
                          Text(
                            'CNIC Number: ',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            host.cnicNumber,
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImageDocCard(
                            context,
                            'CNIC Front',
                            host.cnicFrontUrl,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildImageDocCard(
                            context,
                            'CNIC Back',
                            host.cnicBackUrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Legal Documents Uploaded
                    _buildSectionHeader('Legal Certificates / بیک گراؤنڈ سرٹیفکیٹ'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImageDocCard(
                            context,
                            'Police Character Cert',
                            host.policeCertificateUrl,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildImageDocCard(
                            context,
                            'Verification Cert',
                            host.verificationCertificateUrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Property Verification (Fard-e-Malkiat + Photos)
                    _buildSectionHeader('Onboarding Property Details'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Address: ${host.houseNumber}, ${host.houseAddress}',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    _buildImageDocCard(
                      context,
                      'Fard-e-Malkiat (Property ownership certificate)',
                      host.fardMalkiatUrl,
                      height: 150,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader('Onboarding Property Photos'),
                    if (host.propertyPhotoUrls.isEmpty)
                      Text(
                        'No onboarding property photos uploaded.',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.grey),
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: host.propertyPhotoUrls.length,
                          itemBuilder: (context, idx) {
                            final imgUrl = host.propertyPhotoUrls[idx];
                            return GestureDetector(
                              onTap: () => _showImage(context, imgUrl),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: NestyImage(src: imgUrl, fit: BoxFit.cover),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (_isActionInProgress)
                Positioned.fill(
                  child: Container(
                    color: Colors.white54,
                    child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                  ),
                ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isActionInProgress ? null : _handleReject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.redAccent,
                            elevation: 0,
                            side: const BorderSide(color: Colors.redAccent, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'Reject',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isActionInProgress ? null : _handleApprove,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00674F),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: const Color(0xFF00674F).withOpacity(0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'Approve & Verify',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildImageDocCard(BuildContext context, String label, String? url, {double height = 120}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showImage(context, url),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: url != null && url.isNotEmpty
                  ? NestyImage(src: url, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 32),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
