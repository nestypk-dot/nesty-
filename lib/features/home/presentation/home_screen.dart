import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../chat/presentation/incoming_call_listener.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/property_card.dart';
import '../../../shared/widgets/nesty_bottom_nav.dart';
import '../../../shared/widgets/app_drawer.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/nesty_image.dart';
import '../../host/providers/listings_provider.dart';
import '../../host_onboarding/data/host_profile_repository.dart';
import '../../host_onboarding/domain/host_profile.dart';
import '../providers/properties_provider.dart';
import '../../trips/domain/booking.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedCategoryIndex = 0;

  bool _matchesCategory(String propertyCategory, String targetCategory) {
    if (targetCategory == 'All Types') return true;

    final propCatLower = propertyCategory.toLowerCase().trim();
    final targetLower = targetCategory.toLowerCase().trim();

    if (targetLower == 'apartments') {
      return propCatLower == 'apartments' ||
          propCatLower == 'suites' ||
          propCatLower == 'apartment' ||
          propCatLower == 'flat' ||
          propCatLower.contains('apartment') ||
          propCatLower.contains('flat');
    } else if (targetLower == 'houses') {
      return propCatLower == 'houses' ||
          propCatLower == 'villas' ||
          propCatLower == 'cottages' ||
          propCatLower == 'house' ||
          propCatLower == 'villa' ||
          propCatLower == 'cottage' ||
          propCatLower == 'guest_house' ||
          propCatLower.contains('house') ||
          propCatLower.contains('villa');
    } else if (targetLower == 'rooms') {
      return propCatLower == 'rooms' ||
          propCatLower == 'resort' ||
          propCatLower == 'room' ||
          propCatLower == 'resorts' ||
          propCatLower.contains('room');
    }

    return propCatLower == targetLower ||
        propCatLower.contains(targetLower) ||
        targetLower.contains(propCatLower);
  }

  void _switchToHostMode() {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    final profile = ref
        .read(currentHostProfileProvider)
        .maybeWhen(data: (profile) => profile, orElse: () => null);
    final bool isSubmitted =
        profile?.isSubmitted == true || ref.read(isSubmittedProvider);

    if (!isAuthenticated) {
      // Not logged in → go to signup as host
      context.push('/signup', extra: {'role': 'host'});
    } else if (!isSubmitted || profile?.isDraft == true) {
      context.push('/become-host');
    } else {
      ref.read(authProvider.notifier).setRole(AppRole.host);
    }
  }

  void _switchToGuestMode() {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      // Not logged in → go to signup as guest
      context.push('/signup', extra: {'role': 'guest'});
    } else {
      ref.read(authProvider.notifier).setRole(AppRole.guest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = ref.watch(roleProvider);
    final hostProfileAsync = ref.watch(currentHostProfileProvider);

    final properties = ref.watch(allPropertiesProvider);
    final selectedCategory = homeCategories[_selectedCategoryIndex].label;
    final filteredFeatured = properties
        .where((p) => _matchesCategory(p.category, selectedCategory))
        .toList();
    final reversedProperties = properties.reversed.toList();
    final filteredAll = reversedProperties
        .where((p) => _matchesCategory(p.category, selectedCategory))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      endDrawer: const AppDrawer(),

      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Premium Header (Logo, Guest/Host Toggle, Notifications, Profile)
                SliverToBoxAdapter(child: _buildHeader(context, selectedRole)),

                if (selectedRole == AppRole.host)
                  SliverToBoxAdapter(
                    child: hostProfileAsync.when(
                      data: (profile) {
                        final bool isApproved =
                            profile?.isApproved == true ||
                            ref.watch(isApprovedProvider);
                        final bool isSubmitted =
                            profile?.isSubmitted == true ||
                            ref.watch(isSubmittedProvider);

                        if (isApproved) {
                          return _buildProfessionalHostDashboard(context);
                        }
                        if (profile?.status == HostProfileStatus.rejected) {
                          return _buildRejectedView(context, profile?.rejectionReason);
                        }
                        if (isSubmitted) {
                          return _buildPendingApprovalView();
                        }
                        return _buildOnboardingCTA(context, profile: profile);
                      },
                      loading: _buildHostStatusLoading,
                      error: (_, __) => _buildOnboardingCTA(context),
                    ),
                  )
                else ...[
                  // 2. Hero Search Section
                  SliverToBoxAdapter(child: _buildHeroSearch(context)),

                  // 3. Category Selection
                  SliverToBoxAdapter(child: _buildCategories()),

                  // 4. Safe & Verified Banner
                  SliverToBoxAdapter(child: _buildVerifiedBanner(context)),

                  // 5. Featured Stays (Horizontal)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          context,
                          'Featured Stays',
                          'See all',
                          subtitle: 'نمایاں قیام گاہیں',
                        ),
                        SizedBox(
                          height:
                              395, // Highly spacious to prevent any vertical clipping or text scaling overflows
                          child: filteredFeatured.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Text(
                                      'No stays found in this category / کوئی قیام گاہ نہیں ملی',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: filteredFeatured.length,
                                  itemBuilder: (context, index) {
                                    final property = filteredFeatured[index];
                                    return Container(
                                      width: 245,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: PropertyCard(
                                        propertyId: property.id,
                                        imageUrl: property.imageUrl,
                                        location: property.location,
                                        title: property.title,
                                        price: property.price,
                                        rating: property.rating,
                                        onTap: () => context.push(
                                          '/property/${property.id}',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  // 6. Explore Pakistan (Horizontal)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          context,
                          'Explore Pakistan',
                          null,
                          subtitle: 'پاکستان',
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height:
                              205, // Expanded height to provide breathing room for city labels and stays
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: destinations.length,
                            itemBuilder: (context, index) {
                              final dest = destinations[index];
                              final staysCount = properties
                                  .where((p) => p.location.toLowerCase().contains(dest.name.toLowerCase()))
                                  .length;
                              final dynamicDest = Destination(
                                dest.name,
                                '$staysCount stay${staysCount == 1 ? "" : "s"}',
                                dest.imageUrl,
                              );
                              return _buildDestinationCard(context, dynamicDest);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 7. "Become a Host" Banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildHostBanner(context),
                    ),
                  ),

                  // 8. Why Choose Nesty
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const Text(
                          'Why Choose Nesty / کیوں منتخب کریں',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              _buildFeatureCard(
                                Icons.verified_user_outlined,
                                'Verified Properties',
                                'Every listing verified by our team',
                                'تصدیق شدہ جائیدادیں',
                              ),
                              const SizedBox(width: 12),
                              _buildFeatureCard(
                                Icons.payment_outlined,
                                'Local Payments',
                                'JazzCash, EasyPaisa, Bank Transfer',
                                'مقامی ادائیگی',
                              ),
                              const SizedBox(width: 12),
                              _buildFeatureCard(
                                Icons.security_outlined,
                                'Secure Booking',
                                'Protected with host guarantee',
                                'محفوظ بکنگ',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 9. All Properties
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context,
                      'All Properties',
                      null,
                      subtitle: 'تمام جائیدادیں',
                    ),
                  ),
                  filteredAll.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No properties found in this category / کوئی جائیداد نہیں ملی',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final property = filteredAll[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: PropertyCard(
                                  propertyId: property.id,
                                  imageUrl: property.imageUrl,
                                  location: property.location,
                                  title: property.title,
                                  price: property.price,
                                  rating: property.rating,
                                  category: property.category,
                                  onTap: () =>
                                      context.push('/property/${property.id}'),
                                ),
                              );
                            }, childCount: filteredAll.length),
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ],
            ),

            // Overlaid Floating Capsule Switch Button (charcoal black)
            if (selectedRole == AppRole.host && ref.watch(isApprovedProvider))
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildSwitchToGuestFloatingButton(context),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, selectedRole),
    );
  }

  Widget _buildHeader(BuildContext context, AppRole selectedRole) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Logo Section
          Flexible(
            flex: 5, // Increased to accommodate back button and prevent squeeze
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (context.canPop()) ...[
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Image.asset('assets/images/logo.png', width: 22, height: 22),
                const SizedBox(width: 2),
                const Text(
                  'Nesty',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          // 2. Toggles Group — visible only when NOT authenticated
          Flexible(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!ref.watch(isAuthenticatedProvider)) ...[
                  // Guest button
                  GestureDetector(
                    onTap: _switchToGuestMode,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Guest',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Become Host button
                  GestureDetector(
                    onTap: _switchToHostMode,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.sectionColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Become Host',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ] else if (ref.watch(isAuthenticatedProvider) &&
                    !ref.watch(isApprovedProvider)) ...[
                  // Logged-in guest: show active role label
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      selectedRole == AppRole.host ? 'Host' : 'Guest',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3. Icons Section
          Flexible(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildMenuIcon(context),
                const SizedBox(width: 10),
                _buildNotificationIcon(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find your perfect stay in Pakistan',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.black,
            ),
          ),
          const Text(
            'پاکستان میں بہترین رہائش تلاش کریں۔',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.green),
              SizedBox(width: 4),
              Text(
                'Pakistan / پاکستان',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Search city, area, or property',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Lahore • Karachi • Islamabad',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.push('/filters'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height:
          130, // Expanded height to guarantee categories layout safely with labels
      child: ListView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: homeCategories.length,
        itemBuilder: (context, index) {
          final cat = homeCategories[index];
          final isSelected = index == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
              context.push('/search-results?category=${cat.label}');
            },
            child: Container(
              width: 90,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.sectionColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    cat.icon,
                    color: isSelected ? Colors.white : Colors.black87,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    cat.urdu,
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerifiedBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppTheme.primaryColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          const Text(
            'Safe & verified properties by trusted hosts',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String? actionText, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              if (actionText != null)
                GestureDetector(
                  onTap: () => context.push('/search-results'),
                  child: Row(
                    children: [
                      Text(
                        actionText,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(BuildContext context, Destination dest) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              dest.imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dest.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    dest.stays,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.1,
              child: const Icon(
                Icons.home_work,
                size: 140,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Earn money as a host',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const Text(
                  'میزبان بن کر کمائیں',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'List your property and start earning. We handle payments, support, and verification.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _switchToHostMode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Start hosting / شروع کریں',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String desc,
    String urdu,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.orange.shade700, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
            ),
            Text(
              urdu,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    final isApproved = ref.watch(isApprovedProvider);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 22,
            color: Colors.black87,
          ),
          if (isApproved)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(BuildContext context) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => Scaffold.of(context).openEndDrawer(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_rounded, size: 20, color: Colors.black87),
              const SizedBox(width: 8),
              ref.watch(isApprovedProvider)
                  ? ClipOval(
                      child: NestyImage(
                        src: (ref.watch(authProvider).photoUrl != null &&
                                ref.watch(authProvider).photoUrl!.isNotEmpty)
                            ? ref.watch(authProvider).photoUrl!
                            : 'https://i.pravatar.cc/150?u=muhammad',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppTheme.sectionColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(
    BuildContext context,
    AuthState authState,
    bool isApproved,
  ) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      elevation: 8,
      shadowColor: Colors.black26,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_rounded, size: 20, color: Colors.black87),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.sectionColor,
              backgroundImage: isApproved
                  ? const NetworkImage('https://i.pravatar.cc/150?u=muhammad')
                  : null,
              child: !isApproved
                  ? const Text(
                      'M',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authState.name ?? 'Muhammad Haad',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                Text(
                  authState.email ?? 'muhammad.haad96@gmail.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
              ],
            ),
          ),
        ),
        if (isApproved && authState.adminName != null)
          PopupMenuItem(
            enabled: false,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Approved by ${authState.adminName}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _buildPopupItem(Icons.person_outline_rounded, 'Profile'),
        _buildPopupItem(Icons.settings_outlined, 'Settings'),
        if (isApproved)
          _buildPopupItem(Icons.home_work_outlined, 'Host Settings'),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          onTap: () => ref.read(authProvider.notifier).logout(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Log out',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(IconData icon, String title) {
    return PopupMenuItem(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black87),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovalView() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Profile Under Review',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your profile is currently being reviewed by our team. You will be notified once it is approved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            // Mock Approval Button for Demo
            ElevatedButton(
              onPressed: () => ref.read(authProvider.notifier).approve(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Simulate Admin Approval'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedView(BuildContext context, String? reason) {
    return Container(
      height: 420,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.gavel_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 24),
            Text(
              'Application Rejected',
              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Text(
                'Feedback: ${reason ?? "Please check and update your document details."}',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/become-host'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Re-submit Application',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildProfessionalHostDashboard(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.name ?? 'Abdur';
    final String hostId = authState.isAuthenticated
        ? (FirebaseAuth.instance.currentUser?.uid ?? 'mock_host_id')
        : 'mock_host_id';

    final hostListings = ref.watch(hostListingsProvider);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(hostId)
          .snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() ?? const <String, dynamic>{};
        final String displayName = userData['name'] ?? userName;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('hostId', isEqualTo: hostId)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

             // Calculate confirmed guests & payout
            final confirmedBookings = docs
                .where(
                  (doc) =>
                      doc.data()['status'] == 'upcoming' ||
                      doc.data()['status'] == 'current',
                )
                .toList();
            final confirmedGuests = confirmedBookings.fold<int>(
              0,
              (acc, doc) => acc + (doc.data()['totalGuests'] as num? ?? 0).toInt(),
            );
            final totalPayout = confirmedBookings.fold<double>(
              0.0,
              (acc, doc) =>
                  acc + (doc.data()['totalPrice'] as num? ?? 0.0).toDouble(),
            );

            // Filter pending bookings
            final pendingBookings = docs
                .where((doc) => doc.data()['status'] == 'pending')
                .toList();

            final format = NumberFormat("#,##0", "en_US");

            // Real-time calculation from published properties
            final publishedListings = hostListings
                .where((p) => p.status == 'published')
                .toList();

            final double ratingVal = publishedListings.isEmpty
                ? (userData['hostRating'] as num? ?? 4.95).toDouble()
                : (publishedListings.fold<double>(0.0, (acc, p) => acc + p.rating) /
                    publishedListings.length);

            final int reviewsVal = publishedListings.isEmpty
                ? (userData['hostReviews'] as num? ?? 24).toInt()
                : publishedListings.fold<int>(0, (acc, p) => acc + p.reviews);

            final String statusVal = userData['hostStatus'] as String? ??
                ((ratingVal >= 4.7 && reviewsVal >= 10) ? 'Superhost' : 'Active');

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Glowing Welcome Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F172A),
                          Color(0xFF1E293B),
                        ], // Gorgeous elegant dark slate
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back, $displayName!',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(
                                            0xFF10B981,
                                          ), // Pulsing active dot
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Host Mode Active",
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00674F).withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF00674F).withOpacity(0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                color: Color(0xFF00674F),
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildQuickHeaderStat('${ratingVal.toStringAsFixed(2)} ★', 'Rating'),
                              _buildQuickHeaderStat('$reviewsVal', 'Reviews'),
                              _buildQuickHeaderStat(statusVal, 'Status'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Earnings & Listings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Section
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double cardWidth = (constraints.maxWidth - 16) / 2;
                      final hostListings = ref.watch(hostListingsProvider);
                      final activeCount = hostListings
                          .where((p) => p.status == 'published')
                          .length;
                      final pendingCount = hostListings
                          .where((p) => p.status == 'pending')
                          .length;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildStatCard(
                            '$activeCount',
                            'Active Stays',
                            Icons.home_work_rounded,
                            const Color(0xFF00674F),
                            cardWidth,
                          ),
                          _buildStatCard(
                            '$pendingCount',
                            'Pending review',
                            Icons.hourglass_bottom_rounded,
                            const Color(0xFFF59E0B),
                            cardWidth,
                          ),
                          _buildStatCard(
                            '$confirmedGuests',
                            'Confirmed guests',
                            Icons.people_rounded,
                            const Color(0xFF10B981),
                            cardWidth,
                          ),
                          _buildStatCard(
                            'PKR ${format.format(totalPayout)}',
                            'Total payout',
                            Icons.account_balance_wallet_rounded,
                            const Color(0xFF6366F1),
                            cardWidth,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  _buildEarningsCard(confirmedBookings),
                  const SizedBox(height: 32),
                  _buildRecentBookingsSection(pendingBookings),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(
                    height: 100,
                  ), // extra padding for bottom capsule button
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickHeaderStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBookingsSection(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingBookings,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking Requests',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pendingBookings.length} Pending',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF00674F),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (pendingBookings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No pending booking requests',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingBookings.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 32, color: Color(0xFFF3F4F6)),
              itemBuilder: (context, index) {
                final bookingDoc = pendingBookings[index];
                final String docId = bookingDoc.id;
                final data = bookingDoc.data();
                
                Booking booking;
                try {
                  booking = Booking.fromJson(data, docId);
                } catch (e) {
                  print("Error parsing booking $docId: $e");
                  return const SizedBox.shrink();
                }

                final String guestName = booking.guestName.isNotEmpty ? booking.guestName : 'Guest';
                final String guestAvatarUrl = booking.guestAvatar.isNotEmpty ? booking.guestAvatar : 'https://i.pravatar.cc/150';
                final String location = booking.property.title;
                final int guests = booking.totalGuests;
                final double price = booking.totalPrice;

                final start = booking.checkInDate;
                final end = booking.checkOutDate;
                final nights = end.difference(start).inDays;
                final String dateRange = '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)} ($nights nights)';

                final format = NumberFormat("#,##0", "en_US");

                return _buildBookingRequestItem(
                  guestName: guestName,
                  guestAvatarUrl: guestAvatarUrl,
                  location: location,
                  dates: dateRange,
                  guestsCount: '$guests guest${guests > 1 ? 's' : ''}',
                  price: 'PKR ${format.format(price)}',
                  onAccept: () async {
                    await FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(docId)
                        .update({'status': 'upcoming'});
                    _showBookingFeedback(context, guestName, true);
                  },
                  onDecline: () async {
                    await FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(docId)
                        .update({'status': 'cancelled'});
                    _showBookingFeedback(context, guestName, false);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  void _showBookingFeedback(
    BuildContext context,
    String guestName,
    bool accepted,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              accepted ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: accepted
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              accepted
                  ? 'Booking request by $guestName approved!'
                  : 'Booking request by $guestName declined.',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildBookingRequestItem({
    required String guestName,
    required String guestAvatarUrl,
    required String location,
    required String dates,
    required String guestsCount,
    required String price,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: guestAvatarUrl.startsWith('http')
                  ? Image.network(
                      guestAvatarUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey.shade200,
                        child: Text(
                          guestName.isNotEmpty ? guestName[0].toUpperCase() : 'G',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        guestName.isNotEmpty ? guestName[0].toUpperCase() : 'G',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guestName,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: const Color(0xFF00674F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dates,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_alt_outlined,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        guestsCount,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        price,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDecline,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00674F), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Decline',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: const Color(0xFF00674F),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF00674F,
                  ), // Premium emerald green
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: Text(
                  'Accept',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitchToGuestFloatingButton(BuildContext context) {
    return _PremiumSwitchButton(
      label: 'Switch to guest',
      icon: Icons.swap_horiz_rounded,
      onTap: () => context.push('/switching-guest'),
    );
  }

  Widget _buildStatCard(
    String val,
    String label,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 20),
          Text(
            val,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Widget _buildEarningsCard(List<QueryDocumentSnapshot<Map<String, dynamic>>> confirmedBookings) {
    final DateTime now = DateTime.now();
    final List<DateTime> months = List.generate(6, (i) {
      return DateTime(now.year, now.month - (5 - i), 1);
    });

    final List<Map<String, dynamic>> monthlyStats = [];
    for (final month in months) {
      final monthBookings = confirmedBookings.where((doc) {
        final dateVal = doc.data()['checkInDate'];
        final date = _parseDateTime(dateVal);
        if (date == null) return false;
        return date.year == month.year && date.month == month.month;
      }).toList();

      final double earnings = monthBookings.fold<double>(
        0.0,
        (sum, doc) => sum + (doc.data()['totalPrice'] as num? ?? 0.0).toDouble(),
      );
      final int count = monthBookings.length;

      monthlyStats.add({
        'monthName': DateFormat('MMM').format(month),
        'earnings': earnings,
        'count': count,
      });
    }

    // Find max earnings and max count to scale the bars
    double maxEarnings = monthlyStats.map((s) => s['earnings'] as double).fold(0.0, (a, b) => a > b ? a : b);
    if (maxEarnings == 0) maxEarnings = 10000.0;

    int maxCount = monthlyStats.map((s) => s['count'] as int).fold(0, (a, b) => a > b ? a : b);
    if (maxCount == 0) maxCount = 5;

    final double totalLifetimeEarnings = confirmedBookings.fold<double>(
      0.0,
      (sum, doc) => sum + (doc.data()['totalPrice'] as num? ?? 0.0).toDouble(),
    );

    final format = NumberFormat("#,##0", "en_US");

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.wallet_rounded, size: 20, color: Colors.black),
              SizedBox(width: 8),
              Text(
                'Earnings Analytics',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Available Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lifetime Earnings',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PKR ${format.format(totalLifetimeEarnings)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 28),
          
          // Chart Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Earnings (PKR)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Bookings',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Grouped Bar Chart
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthlyStats.map((stat) {
                final double earningsVal = stat['earnings'] as double;
                final int bookingsVal = stat['count'] as int;
                final String monthName = stat['monthName'] as String;

                final double earningsHeight = (earningsVal / maxEarnings) * 120;
                final double bookingsHeight = (bookingsVal / maxCount) * 120;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: 'PKR ${format.format(earningsVal)}',
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              width: 10,
                              height: earningsHeight.clamp(4.0, 120.0),
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: '$bookingsVal bookings',
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              width: 10,
                              height: bookingsHeight.clamp(4.0, 120.0),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        monthName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          const Divider(height: 40, color: Color(0xFFF3F4F6)),
          _buildEarningRow('Active Bookings Payout', 'PKR ${format.format(totalLifetimeEarnings)}'),
          _buildEarningRow('Completed Withdrawals', 'PKR 0'),
        ],
      ),
    );
  }

  Widget _buildEarningRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            val,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          _buildQuickActionItem(
            Icons.add_home_work_rounded,
            'Add New Property',
            isPrimary: true,
            onTap: () => context.push('/listings'),
          ),
          _buildQuickActionItem(
            Icons.manage_accounts_outlined,
            'Manage Listings',
            onTap: () => context.push('/listings'),
          ),
          _buildQuickActionItem(
            Icons.calendar_today_outlined,
            'View All Bookings',
          ),
          _buildQuickActionItem(
            Icons.chat_bubble_outline_rounded,
            'Open Inbox',
            onTap: () => context.push('/inbox'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    IconData icon,
    String label, {
    bool isPrimary = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPrimary ? AppTheme.primaryColor : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPrimary ? Colors.transparent : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    if (!isPrimary)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                      ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isPrimary
                      ? Colors.yellowAccent
                      : const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isPrimary
                      ? Colors.yellowAccent
                      : const Color(0xFF374151),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isPrimary
                    ? Colors.yellowAccent
                    : const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHostStatusLoading() {
    return const SizedBox(
      height: 400,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildOnboardingCTA(BuildContext context, {HostProfile? profile}) {
    final hasDraft = profile?.isDraft == true;
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.house_siding_rounded,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Become a Host',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const Text(
              'Complete your 6-step profile to start listing your properties and earning.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/become-host'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                hasDraft
                    ? 'Continue Profile Creation'
                    : 'Start Profile Creation',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppRole selectedRole) {
    return const NestyBottomNav(currentIndex: 0);
  }
}

class HomeCategory {
  final String label;
  final String urdu;
  final IconData icon;
  HomeCategory(this.label, this.urdu, this.icon);
}

final homeCategories = [
  HomeCategory('All Types', 'تمام اقسام', Icons.auto_awesome_outlined),
  HomeCategory('Apartments', 'اپارٹمنٹس', Icons.apartment_outlined),
  HomeCategory('Houses', 'مکانات', Icons.home_outlined),
  HomeCategory('Rooms', 'کمرے', Icons.bed_outlined),
];

class Destination {
  final String name;
  final String stays;
  final String imageUrl;
  Destination(this.name, this.stays, this.imageUrl);
}

final destinations = [
  Destination(
    'Murree',
    '45 stays',
    'https://images.unsplash.com/photo-1571171637578-41bc2dd41cd2?q=80&w=600',
  ),
  Destination(
    'Hunza',
    '28 stays',
    'https://images.unsplash.com/photo-1524443169398-9aa1ceab67d5?q=80&w=800',
  ),
  Destination(
    'Swat',
    '32 stays',
    'https://images.unsplash.com/photo-1598091383021-15ddea10925d?q=80&w=600',
  ),
  Destination(
    'Lahore',
    '120 stays',
    'https://images.unsplash.com/photo-1622547748225-3fc4abd2cca0?q=80&w=600',
  ),
  Destination(
    'Karachi',
    '95 stays',
    'https://images.unsplash.com/photo-1588666309990-d68f08e3d4a6?q=80&w=600',
  ),
  Destination(
    'Naran',
    '38 stays',
    'https://images.unsplash.com/photo-1605807646983-377bc5a76493?q=80&w=600',
  ),
];

class _PremiumSwitchButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PremiumSwitchButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PremiumSwitchButton> createState() => _PremiumSwitchButtonState();
}

class _PremiumSwitchButtonState extends State<_PremiumSwitchButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xEE09110E), // Luxury opaque dark jade/black
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFF00674F).withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00674F).withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulse Green Dot
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5), // Glowing neon green
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BFA5).withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Custom Icon inside a circle frame
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00674F).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: const Color(0xFF00BFA5),
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
