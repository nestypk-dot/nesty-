import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/nesty_image.dart';
import '../../../shared/widgets/full_screen_image_gallery.dart';
import '../../home/domain/property.dart';
import '../providers/admin_provider.dart';

class AdminPropertyDetailScreen extends ConsumerStatefulWidget {
  final String propertyId;
  const AdminPropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<AdminPropertyDetailScreen> createState() => _AdminPropertyDetailScreenState();
}

class _AdminPropertyDetailScreenState extends ConsumerState<AdminPropertyDetailScreen> {
  bool _isActionInProgress = false;

  void _showImage(BuildContext context, List<String> images, int index) {
    if (images.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenImageGallery(
          images: images,
          initialIndex: index,
        ),
      ),
    );
  }

  void _handleApprove() async {
    setState(() => _isActionInProgress = true);
    try {
      await ref.read(adminControllerProvider).approveProperty(widget.propertyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Property listing approved!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving property: $e'),
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
            'Reject Listing Request',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter rejection feedback for the host:',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Blur property photos or incorrect pricing description...',
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
                    const SnackBar(content: Text('Please enter a reason')),
                  );
                  return;
                }
                Navigator.pop(context);
                setState(() => _isActionInProgress = true);
                try {
                  await ref.read(adminControllerProvider).rejectProperty(widget.propertyId, reason);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Property listing rejected.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
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
          'Review Property Listing',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('properties').doc(widget.propertyId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Property not found.',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          }

          final property = Property.fromJson(snapshot.data!.data()!, snapshot.data!.id);
          final List<String> images = property.galleryImages.isNotEmpty
              ? property.galleryImages
              : [property.imageUrl];

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image gallery row
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, idx) {
                          final url = images[idx];
                          return GestureDetector(
                            onTap: () => _showImage(context, images, idx),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: NestyImage(src: url, fit: BoxFit.cover),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title & Category
                    Text(
                      property.title,
                      style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            property.category,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'PKR ${property.price} / night',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Host Profile
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: property.hostImageUrl.isNotEmpty
                                ? NestyImage(src: property.hostImageUrl, width: 40, height: 40, fit: BoxFit.cover)
                                : Container(width: 40, height: 40, color: const Color(0xFFE2E8F0)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hosted by ${property.hostName}',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              Text(
                                'ID: ${property.hostId}',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Location detail
                    _buildSectionHeader('Location Details'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              property.location,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _buildSectionHeader('Property Description'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        property.description,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, height: 1.5, color: const Color(0xFF334155)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Specifications Grid
                    _buildSectionHeader('Specifications'),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildSpecCard(Icons.group_outlined, '${property.guests} Guests'),
                        _buildSpecCard(Icons.king_bed_outlined, '${property.bedrooms} Bedrooms'),
                        _buildSpecCard(Icons.bathtub_outlined, '${property.bathrooms} Bathrooms'),
                        _buildSpecCard(
                          property.noSmoking ? Icons.smoke_free : Icons.smoking_rooms,
                          property.noSmoking ? 'No Smoking' : 'Smoking Allowed',
                        ),
                        _buildSpecCard(
                          property.noParties ? Icons.volume_mute : Icons.volume_up,
                          property.noParties ? 'No Parties' : 'Parties Allowed',
                        ),
                        _buildSpecCard(
                          property.petsAllowed ? Icons.pets : Icons.money_off_csred,
                          property.petsAllowed ? 'Pets Allowed' : 'No Pets',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Amenities list
                    _buildSectionHeader('Amenities'),
                    if (property.amenities.isEmpty)
                      Text('No amenities specified.', style: GoogleFonts.plusJakartaSans(color: Colors.grey))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: property.amenities.map((amenity) {
                          return Chip(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            label: Text(
                              amenity,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          );
                        }).toList(),
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
                            'Reject Listing',
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
                            'Approve Listing',
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

  Widget _buildSpecCard(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}
