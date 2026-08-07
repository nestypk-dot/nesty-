import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../domain/property.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/full_screen_image_gallery.dart';
import '../../../shared/widgets/nesty_image.dart';
import '../providers/properties_provider.dart';
import '../../host/providers/listings_provider.dart';
import '../../../core/providers/auth_provider.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> with SingleTickerProviderStateMixin {
  static const Color primaryBlue = AppTheme.secondaryColor; 
  static const Color lightGrey = AppTheme.sectionColor;
  static const Color dividerColor = AppTheme.borderColor;
  static const Color sectionDividerColor = Color(0xFFF0F0F0);
  
  final ValueNotifier<int> _currentImageIndex = ValueNotifier<int>(0);
  final PageController _pageController = PageController();
  DateTime? _startDate;
  DateTime? _endDate;
  int _adults = 1;
  int _children = 0;
  int _infants = 0;
  int _pets = 0;
  List<String> _amenities = [];
  bool _isAmenitiesInitialized = false;

  late AnimationController _flagAnimController;
  late Animation<double> _flagAnimation;

  @override
  void initState() {
    super.initState();
    _flagAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _flagAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _flagAnimController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _flagAnimController.dispose();
    _pageController.dispose();
    _currentImageIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProperties = ref.watch(allPropertiesProvider);
    final hostProperties = ref.watch(hostListingsProvider);

    final property = allProperties.firstWhere(
      (p) => p.id == widget.propertyId,
      orElse: () => hostProperties.firstWhere(
        (p) => p.id == widget.propertyId,
        orElse: () => mockProperties.firstWhere(
          (p) => p.id == widget.propertyId,
          orElse: () => mockProperties.first,
        ),
      ),
    );

    if (!_isAmenitiesInitialized) {
      _amenities = List.from(property.amenities);
      _isAmenitiesInitialized = true;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, property),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Section
                _buildHeaderSection(property),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          'https://maps.googleapis.com/maps/api/staticmap?center=${property.latitude},${property.longitude}&zoom=13&size=600x300&maptype=roadmap&markers=color:red%7C${property.latitude},${property.longitude}&key=YOUR_API_KEY',
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.map_outlined, size: 40, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Exact location will be provided after booking.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // 1.5 Guest Favorite / Rating Summary Card
                if (property.reviews > 0) ...[
                  _buildRatingSummaryCard(property),
                  const Divider(thickness: 1, color: dividerColor),
                ],

                // 2. About this place
                _buildAboutSection(property),

                const Divider(thickness: 8, color: sectionDividerColor),

                // 3. Meet the host
                _buildHostSection(property),

                const Divider(thickness: 8, color: sectionDividerColor),

                // 4. Amenities
                _buildAmenitiesSection(property),

                const Divider(thickness: 8, color: sectionDividerColor),

                // 5. Location
                _buildLocationPreview(property),

                const Divider(thickness: 8, color: sectionDividerColor),

                // 6. House Rules
                _buildSafetyAndRulesSection(property),

                const Divider(thickness: 8, color: sectionDividerColor),

                // 8. Cancellation
                _buildCancellationPolicySection(property),

                const Divider(thickness: 8, color: sectionDividerColor),

                // 9. Nearby Places
                _buildNearbyPlacesSection(property),

                if (_startDate != null && _endDate != null) ...[
                  const Divider(thickness: 8, color: sectionDividerColor),
                  _buildPriceBreakdownSection(property),
                ],

                const SizedBox(height: 120), 
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildStickyBottomBar(property),
    );
  }

  Widget _buildAppBar(BuildContext context, Property property) {
    final isFavorite = ref.watch(authProvider).favorites.contains(property.id);

    return SliverAppBar(
      expandedHeight: 350,
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      stretch: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 16),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? AppTheme.primaryColor : Colors.black,
              size: 20,
            ),
            onPressed: () {
              ref.read(authProvider.notifier).toggleFavorite(property.id);
            },
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black, size: 20),
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImageGallery(property),
      ),
    );
  }

  Widget _buildImageGallery(Property property) {
    final images = property.galleryImages.isNotEmpty ? property.galleryImages : [property.imageUrl];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: images.length >= 5
                ? SizedBox(
                    height: 350,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Large Main Image
                        Expanded(
                          flex: 3,
                          child: _buildGalleryImage(images, 0, isMain: true),
                        ),
                        const SizedBox(width: 8),
                        // Right Side Grid (2x2)
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(child: _buildGalleryImage(images, 1)),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildGalleryImage(images, 2)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(child: _buildGalleryImage(images, 3)),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildGalleryImage(images, 4)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildImageGridFallback(images),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageGallery(
                      images: images,
                      initialIndex: 0,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.grid_view_rounded, size: 18, color: Colors.black),
              label: const Text('Show all photos', 
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.black, width: 1),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGridFallback(List<String> images) {
    if (images.length >= 3) {
      return SizedBox(
        height: 300,
        child: Row(
          children: [
            Expanded(flex: 2, child: _buildGalleryImage(images, 0, isMain: true)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                   Expanded(child: _buildGalleryImage(images, 1)),
                   const SizedBox(height: 8),
                   Expanded(child: _buildGalleryImage(images, 2)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return _buildGalleryImage(images, 0, isMain: true);
  }

  Widget _buildGalleryImage(List<String> images, int index, {bool isMain = false}) {
    final String url = images[index];
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FullScreenImageGallery(
              images: images,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Hero(
        tag: isMain ? 'property_main_hero' : 'gallery_image_$url',
        child: NestyImage(
          src: url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: Container(color: AppTheme.sectionColor),
          errorWidget: Container(color: AppTheme.sectionColor, child: const Icon(Icons.image)),
        ),
      ),
    );
  }
  Widget _buildHeaderSection(Property property) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3FF), // Soft light blue for category
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  property.category.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF4A90E2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    property.rating.toString(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${property.reviews} reviews)',
                    style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            property.title,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF4A90E2)),
              const SizedBox(width: 4),
              Text(
                property.location,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: sectionDividerColor, thickness: 1),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildFeatureIcon(Icons.people_rounded, '${property.guests} guest')),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureIcon(Icons.door_front_door_outlined, '${property.bedrooms} BR')),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureIcon(Icons.king_bed_outlined, '${property.beds} beds')),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureIcon(Icons.bathtub_outlined, '${property.bathrooms} bath')),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: dividerColor),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                property.rating.toString(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 4),
              Text(
                '· ${property.reviews} reviews',
                style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummaryCard(Property property) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFFBFBFA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.04), // Soft luxury gold shadow
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Subtle background glow for the rating
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.12),
                      blurRadius: 50,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildLuxuryBadgeItem(true),
                  const SizedBox(width: 14),
                  
                  // Gold Gradient Border Wrapper for the Rating
                  Container(
                    padding: const EdgeInsets.all(2.5), // Border thickness
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFDF7A), // Metallic gold light
                          Color(0xFFD4AF37), // Classic gold
                          Color(0xFF855D10), // Shadow gold
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Text(
                        property.rating.toString(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          color: Colors.black,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 14),
                  _buildLuxuryBadgeItem(false),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          // Certified Status Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA), // Soft emerald background
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF00674F).withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF00674F)),
                const SizedBox(width: 8),
                Text(
                  (property.isGuestFavorite ? 'Guest favorite' : 'Highly rated').toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF00674F), // Cohesive Emerald Green
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          
          // Elite Rating Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFC5A028)),
              const SizedBox(width: 6),
              Text(
                'TOP 1% OF HOMES ON NESTY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFC5A028), // Elegant Gold Text
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFC5A028)),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            property.isGuestFavorite
                ? 'This home is a guest favorite based on\nratings, reviews, and reliability'
                : 'One of the most loved homes on Nesty based on\nratings, reviews, and host hospitality',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
              height: 1.5,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'How reviews work',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.black54,
                  decorationThickness: 2,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(color: Color(0xFFF3F4F6), thickness: 1.5),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Guest reviews mention',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _buildReviewMentionChip(Icons.monetization_on_rounded, 'Value', 10),
                const SizedBox(width: 12),
                _buildReviewMentionChip(Icons.directions_car_rounded, 'Parking', 2),
                const SizedBox(width: 12),
                _buildReviewMentionChip(Icons.bathtub_rounded, 'Bathroom', 5),
                const SizedBox(width: 12),
                _buildReviewMentionChip(Icons.coffee_rounded, 'Breakfast', 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuxuryBadgeItem(bool isLeft) {
    return AnimatedBuilder(
      animation: _flagAnimation,
      builder: (context, child) {
        final double baseAngle = isLeft ? -0.15 : 0.15;
        final double waveAngle = isLeft ? _flagAnimation.value * 0.5 : -_flagAnimation.value * 0.5;
        final double verticalOffset = _flagAnimation.value * 30; // smooth float

        return Transform.translate(
          offset: Offset(0, verticalOffset),
          child: Transform.rotate(
            angle: baseAngle + waveAngle,
            child: Container(
              padding: const EdgeInsets.all(2.0), // Outer gold border
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFDF7A),
                    Color(0xFFD4AF37),
                    Color(0xFF855D10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33D4AF37),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF09110E), // Satin black inner core
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLeft ? Icons.auto_awesome_rounded : Icons.workspace_premium_rounded,
                  color: const Color(0xFFFFDF7A),
                  size: 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewMentionChip(IconData icon, String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF4A4A4A)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.black),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHostSection(Property property) {
    final isSuperhost = property.hostRating >= 4.7 && property.hostReviews >= 10;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meet your host',
            style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => context.push('/host/${property.id}'),
            borderRadius: BorderRadius.circular(28),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, Color.lerp(AppTheme.primaryColor, Colors.black, 0.2)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left side: Profile
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: const Color(0xFFAEF4D6),
                                backgroundImage: CachedNetworkImageProvider(property.hostImageUrl),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle, color: Color(0xFF00674F), size: 24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          property.hostName,
                          style: GoogleFonts.plusJakartaSans(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                isSuperhost ? 'Superhost' : 'Host',
                                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right side: Stats
                  Container(
                    width: 1,
                    height: 120,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildHostStat(
                          NumberFormat.decimalPattern().format(property.hostReviews),
                          'Reviews',
                        ),
                        const Divider(color: Colors.white24, indent: 20, endIndent: 20),
                        _buildHostStat(
                          property.hostRating == 0.0 ? 'New' : '${property.hostRating.toStringAsFixed(1)}★',
                          'Rating',
                        ),
                        const Divider(color: Colors.white24, indent: 20, endIndent: 20),
                        _buildHostStat('Joined in', '${property.hostJoinedYear}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (property.hostExtraInfo != null && property.hostExtraInfo!.trim().isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.cake_outlined, size: 24),
                const SizedBox(width: 16),
                Text(property.hostExtraInfo!, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (property.hostEducation != null && property.hostEducation!.trim().isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.school_outlined, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Where I went to school: ${property.hostEducation!}', 
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
          Text(
            property.hostBio,
            style: GoogleFonts.plusJakartaSans(fontSize: 16, height: 1.6, color: Colors.black87, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          if (isSuperhost) ...[
            Text(
              '${property.hostName} is a Superhost',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Superhosts are experienced, highly rated hosts who are committed to providing great stays for guests.',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5, color: Colors.black54, fontWeight: FontWeight.w700),
            ),
          ] else ...[
            Text(
              '${property.hostName} is a Host',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Hosts are committed to providing welcoming, comfortable, and memorable stays for guests.',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5, color: Colors.black54, fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.push('/chat', extra: {
                'peerId': property.hostId ?? 'host_${property.id}',
                'peerName': property.hostName,
                'peerImageUrl': property.hostImageUrl,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00674F),
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Message Host', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildHostStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w900)),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDescriptionSection(Property property) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this space',
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Text(
            property.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Read more',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(Property property) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'What this place offers',
                  style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
              InkWell(
                onTap: () => _showAddAmenityDialog(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 18, color: Color(0xFF00674F)),
                      const SizedBox(width: 6),
                      Text('Add Amenity', 
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, 
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF00674F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 40,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _amenities.length,
            itemBuilder: (context, index) {
              return Row(
                children: [
                   Icon(_getAmenityIcon(_amenities[index]), size: 24, color: Colors.black54),
                  const SizedBox(width: 12),
                  Text(
                    _amenities[index],
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String name) {
    switch (name.toLowerCase()) {
      case 'wifi': return Icons.wifi;
      case 'heater': return Icons.hot_tub_rounded;
      case 'fireplace': return Icons.fireplace_rounded;
      case 'parking': return Icons.local_parking_rounded;
      case 'kitchen': return Icons.kitchen_rounded;
      case 'washer': return Icons.local_laundry_service_rounded;
      case 'dryer': return Icons.dry_cleaning_rounded;
      case 'tv': return Icons.tv_rounded;
      case 'air conditioning': return Icons.air_rounded;
      default: return Icons.check_circle_outline_rounded;
    }
  }

  Widget _buildNearbyPlacesSection(Property property) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore nearby',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          _buildNearbyItem('Mall of Lahore', '10 min drive', Icons.shopping_bag_outlined),
          const SizedBox(height: 16),
          _buildNearbyItem('Allama Iqbal Intl Airport', '35 min drive', Icons.airplanemode_active_rounded),
          const SizedBox(height: 16),
          _buildNearbyItem('Hospital / Clinic', '5 min drive', Icons.local_hospital_outlined),
        ],
      ),
    );
  }

  Widget _buildNearbyItem(String name, String distance, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.sectionColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(distance, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildSafetyAndRulesSection(Property property) {
    // Format check-in/out times nicely
    String formatTimeString(String timeStr) {
      try {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final tod = TimeOfDay(hour: hour, minute: minute);
          return tod.format(context);
        }
      } catch (_) {}
      return timeStr;
    }

    final formattedCheckIn = formatTimeString(property.checkInTime);
    final formattedCheckOut = formatTimeString(property.checkOutTime);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'House Rules',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          _buildRuleRow(Icons.access_time_rounded, 'Check-in: after $formattedCheckIn'),
          const SizedBox(height: 16),
          _buildRuleRow(Icons.access_time_rounded, 'Checkout: before $formattedCheckOut'),
          const SizedBox(height: 16),
          _buildRuleRow(Icons.people_alt_outlined, '${property.guests} guests maximum'),
          const SizedBox(height: 16),
          _buildRuleRow(
            property.noSmoking ? Icons.smoke_free_rounded : Icons.smoking_rooms_rounded, 
            property.noSmoking ? 'No smoking allowed' : 'Smoking allowed',
          ),
          const SizedBox(height: 16),
          _buildRuleRow(
            property.noParties ? Icons.volume_mute_rounded : Icons.volume_up_rounded, 
            property.noParties ? 'No parties or events' : 'Parties / Events allowed',
          ),
          const SizedBox(height: 16),
          _buildRuleRow(
            property.petsAllowed ? Icons.pets_rounded : Icons.do_not_disturb_on_rounded, 
            property.petsAllowed ? 'Pets allowed' : 'No pets allowed',
          ),
          if (property.quickRules.isNotEmpty) ...[
            for (final rule in property.quickRules) ...[
              const SizedBox(height: 16),
              _buildRuleRow(Icons.assignment_turned_in_outlined, rule),
            ],
          ],
          const SizedBox(height: 32),
          Text(
            'Safety & Property',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          _buildRuleRow(Icons.smoke_free_rounded, 'No smoke alarm reported'),
          const SizedBox(height: 16),
          _buildRuleRow(Icons.warning_amber_rounded, 'Carbon monoxide alarm not reported'),
          const SizedBox(height: 16),
          _buildRuleRow(Icons.info_outline_rounded, 'Security camera/recording device'),
          const SizedBox(height: 24),
          Text(
            'Show more',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
              fontSize: 16,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationPolicySection(Property property) {
    String getPolicyDescription(String policy) {
      if (policy.toLowerCase().contains('strict')) {
        return 'Strict cancellation policy: Cancellation charges apply. Non-refundable.';
      } else if (policy.toLowerCase().contains('flexible')) {
        return 'Flexible cancellation policy: Free cancellation up to 24 hours before check-in.';
      } else {
        return 'Moderate cancellation policy: Full refund up to 5 days before check-in.';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cancellation policy',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            '${property.cancellationPolicy}\n\n${getPolicyDescription(property.cancellationPolicy)}',
            style: const TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            'Read more',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
              fontSize: 16,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.black87),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPreview(Property property) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where you\'ll be',
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: lightGrey,
              image: const DecorationImage(
                image: CachedNetworkImageProvider('https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=800'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: const Icon(Icons.home_rounded, color: primaryBlue, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            property.location,
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.privacy_tip_outlined, size: 20, color: Colors.black87),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'To protect our hosts\' privacy, we show the approximate location on the map. You\'ll receive the exact address after your booking is confirmed.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(Property property) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 28),
              const SizedBox(width: 8),
              Text(
                '${property.rating} · ${property.reviews} reviews',
                style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => _buildReviewCard(),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              side: const BorderSide(color: Colors.black, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Show all reviews', style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard() {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 20, backgroundColor: Color(0xFFAEF4D6)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jane Doe', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text('March 2024', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Amazing place! The view was breathtaking and the host was very accommodating. Definitely coming back.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontSize: 15, height: 1.4, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdownSection(Property property) {
    final nights = _endDate!.difference(_startDate!).inDays;
    final total = property.price * nights;
    final currencyFormat = NumberFormat("#,##0", "en_US");

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDetailRow('PKR ${currencyFormat.format(property.price)} x $nights nights', 'PKR ${currencyFormat.format(total)}'),
          const SizedBox(height: 12),
          _buildDetailRow('Total', 'PKR ${currencyFormat.format(total)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: isTotal ? 20 : 16, fontWeight: FontWeight.w900)),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: isTotal ? 20 : 16, fontWeight: FontWeight.w900, color: isTotal ? const Color(0xFF00674F) : Colors.black)),
      ],
    );
  }

  Widget _buildStickyBottomBar(Property property) {
    final currencyFormat = NumberFormat("#,##0", "en_US");
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'PKR ${currencyFormat.format(property.price)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18, 
                                fontWeight: FontWeight.w900, 
                                color: Colors.black, // Darker looks more premium
                              ),
                            ),
                            TextSpan(
                              text: ' night',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, 
                                fontWeight: FontWeight.w600, 
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        if (_startDate == null) {
                          _showDateRangePicker(context);
                        } else {
                          _showGuestPicker(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          _startDate == null 
                            ? 'Select dates · ${_adults + _children + _infants} guest${_adults + _children + _infants > 1 ? 's' : ''}' 
                            : '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)} · ${_adults + _children + _infants} guest${(_adults + _children + _infants) > 1 ? 's' : ''}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, 
                            fontWeight: FontWeight.w800, 
                            decoration: TextDecoration.underline,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You won\'t be charged yet',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  context.push('/booking-summary', extra: {
                    'property': property,
                    'startDate': _startDate,
                    'endDate': _endDate,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00674F), // Emerald Green
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  minimumSize: const Size(140, 56),
                ),
                child: Text(
                  'Reserve',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showGuestPicker(BuildContext context) async {
    final result = await context.push<Map<String, int>>('/select-guests', extra: {
      'adults': _adults,
      'children': _children,
      'infants': _infants,
      'pets': _pets,
    });

    if (result != null) {
      setState(() {
        _adults = result['adults'] ?? 1;
        _children = result['children'] ?? 0;
        _infants = result['infants'] ?? 0;
        _pets = result['pets'] ?? 0;
      });
    }
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00674F),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _showAddAmenityDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Add New Amenity',
                      style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'What feature does this place have?',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'e.g. Swimming Pool',
                  prefixIcon: const Icon(Icons.star_outline, color: Color(0xFF00674F)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF00674F), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF00674F), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    setState(() {
                      _amenities.add(controller.text);
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00674F),
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 8,
                  shadowColor: const Color(0xFF00674F).withOpacity(0.4),
                ),
                child: Text(
                  'Add Amenity',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildAboutSection(Property property) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this place',
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Text(
            property.description ?? 'Welcome to this beautiful ${property.category}. This property offers a unique experience for travelers seeking comfort and authenticity in Pakistan.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Row(
              children: [
                Text(
                  'Show more',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: Colors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
