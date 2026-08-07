import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/nesty_bottom_nav.dart';
import '../../../shared/widgets/nesty_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/domain/property.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../host/providers/listings_provider.dart';
import '../../../shared/widgets/full_screen_image_gallery.dart';
import '../../host_onboarding/data/host_profile_repository.dart';
import '../../host_onboarding/domain/host_profile.dart';


class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostProperties = ref.watch(hostListingsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Listings',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${hostProperties.length} ${hostProperties.length == 1 ? 'property' : 'properties'}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildAddPropertyButton(context, ref, mini: true),
                  ],
                ),
              ),
            
            if (hostProperties.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                        child: const Icon(Icons.business_rounded, size: 48, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(height: 24),
                      Text('No listings yet', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF1F2937))),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text('Create your first property listing to start hosting guests', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280), height: 1.5)),
                      ),
                      const SizedBox(height: 32),
                      _buildAddPropertyButton(context, ref, label: 'Add Your First Property'),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: hostProperties.length,
                  itemBuilder: (context, index) {
                    return HostPropertyCard(property: hostProperties[index]);
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const NestyBottomNav(currentIndex: 1),
      ),
    );
  }

  Widget _buildAddPropertyButton(BuildContext context, WidgetRef ref, {String? label, bool mini = false}) {
    final hostProfileAsync = ref.watch(currentHostProfileProvider);

    return hostProfileAsync.maybeWhen(
      data: (profile) {
        final bool isApproved = profile?.status == HostProfileStatus.approved;
        
        return ElevatedButton(
          onPressed: () {
            if (!isApproved) {
              _showNotApprovedDialog(context, profile);
            } else {
              context.push('/add-property');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: mini ? 16 : 24,
              vertical: mini ? 10 : 16,
            ),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 20),
              const SizedBox(width: 8),
              Text(
                label ?? 'Add Property',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: mini ? 12 : 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  void _showNotApprovedDialog(BuildContext context, HostProfile? profile) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Text(
                'Verification Required',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            profile?.status == HostProfileStatus.pendingReview
                ? 'Your host identity profile is currently under review by admin. You will be allowed to add properties once verified.'
                : profile?.status == HostProfileStatus.rejected
                    ? 'Your host application was rejected.\nReason: ${profile?.rejectionReason}\n\nPlease update and re-submit your profile from home.'
                    : 'You must submit your host identity verification profile before you can list a property for rent.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.grey),
              ),
            ),
            if (profile?.status != HostProfileStatus.pendingReview)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/become-host');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Verify Profile',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Host Property Card with real-time gallery carousel
// ─────────────────────────────────────────────────────────────────────────────
class HostPropertyCard extends ConsumerStatefulWidget {
  final Property property;

  const HostPropertyCard({super.key, required this.property});

  @override
  ConsumerState<HostPropertyCard> createState() => _HostPropertyCardState();
}

class _HostPropertyCardState extends ConsumerState<HostPropertyCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Returns all available image sources (URLs or local paths) for this property.
  List<String> get _allImages {
    final List<String> images = [];
    // Prefer galleryImages (full list)
    if (widget.property.galleryImages.isNotEmpty) {
      images.addAll(widget.property.galleryImages);
    } else if (widget.property.imageUrl.isNotEmpty) {
      images.add(widget.property.imageUrl);
    }
    return images;
  }

  /// Build a single image widget — handles network URLs and local file paths.
  Widget _buildImage(String src, {double height = 220}) {
    return NestyImage(
      src: src,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: _loadingShimmer(height),
      errorWidget: _placeholder(height),
    );
  }

  Widget _loadingShimmer(double height) {
    return Container(
      height: height,
      decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Loading image...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(double height) {
    return Container(
      height: height,
      color: const Color(0xFFF3F4F6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              color: Color(0xFF9CA3AF),
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No photos uploaded',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Edit listing to add photos',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final images = _allImages;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image Section ─────────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: images.isEmpty
                    ? _placeholder(220)
                    : images.length == 1
                        ? GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImageGallery(
                                    images: images,
                                    initialIndex: 0,
                                  ),
                                ),
                              );
                            },
                            child: _buildImage(images[0], height: 220),
                          )
                        // Gallery carousel
                        : SizedBox(
                            height: 220,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: images.length,
                              onPageChanged: (page) {
                                setState(() => _currentPage = page);
                              },
                              itemBuilder: (context, idx) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => FullScreenImageGallery(
                                          images: images,
                                          initialIndex: idx,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _buildImage(images[idx], height: 220),
                                );
                              },
                            ),
                          ),
              ),

              // Gradient overlay for badge readability
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.45, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.22),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Status badge (top-left)
              Positioned(
                top: 12,
                left: 12,
                child: _buildStatusBadge(property.status),
              ),

              // Image count badge (top-right) — only when multiple images
              if (images.length > 1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          '${_currentPage + 1}/${images.length}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Dots indicator (bottom center) — only when multiple images
              if (images.length > 1)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (idx) {
                      final isActive = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
          
          // ── Details Section ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1F2937)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, 
                          fontWeight: FontWeight.w600, 
                          color: const Color(0xFF6B7280),
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFeature(Icons.people_outline, property.guests.toString()),
                    const SizedBox(width: 16),
                    _buildFeature(Icons.bed_outlined, property.bedrooms.toString()),
                    const SizedBox(width: 16),
                    _buildFeature(Icons.bathtub_outlined, property.bathrooms.toString()),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'PKR ${NumberFormat("#,##0", "en_US").format(property.price)} / night',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1F2937)),
                ),
                if (property.status == 'pending') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => const Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryColor),
                          ),
                        );

                        try {
                          await ref.read(hostListingsProvider.notifier).approveProperty(property.id);
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop(); // Dismiss loader cleanly
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your property details have been submitted for admin approval.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop(); // Dismiss loader cleanly
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to publish property: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.publish_rounded, size: 18),
                      label: Text(
                        'Approve & Publish Listing',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/edit-listing', extra: property),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1F2937),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildIconButton(
                      context, 
                      Icons.visibility_outlined, 
                      Colors.black87,
                      onTap: () => context.push('/property/${property.id}'),
                    ),
                    const SizedBox(width: 12),
                    _buildIconButton(
                      context, 
                      Icons.delete_outline_rounded, 
                      Colors.redAccent,
                      onTap: () => _showDeleteConfirmation(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final bool isPending = status == 'pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFF3CD) : const Color(0xFFD1E7DD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPending ? const Color(0xFFFFE69C) : const Color(0xFFBADBCC),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPending ? const Color(0xFFD97706) : const Color(0xFF0F5132),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isPending ? 'Pending Approval' : 'Published',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isPending ? const Color(0xFF664D03) : const Color(0xFF0F5132),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Listing?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
        content: Text(
          'Are you sure you want to delete "${widget.property.title}"? This action cannot be undone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(hostListingsProvider.notifier).removeProperty(widget.property.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Listing deleted successfully'),
                  backgroundColor: Colors.black87,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String val) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF374151))),
      ],
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
