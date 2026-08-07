import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/property.dart';
import '../providers/properties_provider.dart';
import '../../host/providers/listings_provider.dart';

class HostProfileScreen extends ConsumerWidget {
  final String propertyId;
  final bool hasBooking; // To control the contact button state

  const HostProfileScreen({
    super.key,
    required this.propertyId,
    this.hasBooking = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProperties = ref.watch(allPropertiesProvider);
    final hostProperties = ref.watch(hostListingsProvider);

    // Find the property to get host details
    final property = allProperties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => hostProperties.firstWhere(
        (p) => p.id == propertyId,
        orElse: () => mockProperties.firstWhere(
          (p) => p.id == propertyId,
          orElse: () => mockProperties.first,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Header Card
            _buildProfileCard(context, property),

            const SizedBox(height: 32),

            // 2. Main Stats Section
            _buildHostStats(property),

            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: AppTheme.borderColor, thickness: 0.5),
            ),
            const SizedBox(height: 32),

            // 3. About Section
            _buildAboutHost(property),

            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: AppTheme.borderColor, thickness: 0.5),
            ),
            const SizedBox(height: 32),

            // 4. Contact Host Section (Locked state)
            _buildContactSection(context, property),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Property property) {
    final isSuperhost = property.hostRating >= 4.7 && property.hostReviews >= 10;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white,
            Color(0xFF01411C), // Pakistani Green
            Color(0xFF01411C),
          ],
          stops: [0.0, 0.35, 0.36, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF01411C).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Texture Overlay (Simplified silk effect)
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.black],
                    stops: [0.2, 0.8],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Host Image with Shield
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundImage: CachedNetworkImageProvider(property.hostImageUrl),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF01411C), width: 2),
                        ),
                        child: const Icon(Icons.verified_user_rounded, size: 20, color: Color(0xFF01411C)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Name and Tagline
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        property.hostName,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          shadows: [const Shadow(color: Colors.black26, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSuperhost ? Icons.workspace_premium_rounded : Icons.person_rounded,
                              size: 14,
                              color: const Color(0xFF01411C),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSuperhost ? 'Superhost' : 'Host',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF01411C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostStats(Property property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('${property.hostReviews}', 'Reviews'),
            const VerticalDivider(width: 1, thickness: 0.5, color: AppTheme.borderColor),
            _buildStatItem('${property.hostRating} ★', 'Rating'),
            const VerticalDivider(width: 1, thickness: 0.5, color: AppTheme.borderColor),
            _buildStatItem('${property.hostExperienceYears}', 'Years hosting'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutHost(Property property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About ${property.hostName.split(' ')[0]}',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (property.hostEducation != null)
            _buildHostDetailRow(Icons.school_outlined, 'Studied at ${property.hostEducation!}'),
          _buildHostDetailRow(Icons.history_rounded, 'Joined in ${property.hostJoinedYear}'),
          if (property.hostExtraInfo != null)
            _buildHostDetailRow(Icons.cake_outlined, property.hostExtraInfo!),
          
          const SizedBox(height: 16),
          Text(
            property.hostBio,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: AppTheme.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textPrimary),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context, Property property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Contact ${property.hostName.split(' ')[0]}',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (!hasBooking)
                const Icon(Icons.lock_outline_rounded, size: 18, color: AppTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasBooking 
                ? 'Send a message to coordinate your check-in or ask questions about the stay.'
                : 'Messaging is available once you have a confirmed booking with this host.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: hasBooking ? () {
                context.push('/chat', extra: {
                  'peerId': property.hostId ?? 'host_${property.id}',
                  'peerName': property.hostName,
                  'peerImageUrl': property.hostImageUrl,
                });
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: AppTheme.sectionColor,
                disabledForegroundColor: AppTheme.textSecondary.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Message Host',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
