import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/widgets/nesty_bottom_nav.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/nesty_image.dart';
import '../../booking/providers/bookings_provider.dart';

class MyProfileScreen extends HookConsumerWidget {
  const MyProfileScreen({super.key});

  void _updateProfilePicture(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Profile Photo / تصویر تبدیل کریں',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF00674F)),
                title: Text('Choose from Gallery', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  _pickAndUpload(picker, ImageSource.gallery, context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF00674F)),
                title: Text('Take a Photo', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  _pickAndUpload(picker, ImageSource.camera, context, ref);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _pickAndUpload(ImagePicker picker, ImageSource source, BuildContext context, WidgetRef ref) async {
    try {
      final image = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 400);
      if (image == null) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Uploading profile photo...'),
              ],
            ),
            duration: Duration(days: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await ref.read(authProvider.notifier).updateProfilePhoto(image.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Color(0xFF00674F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Watch trips/bookings count dynamically based on current role
    final isHost = authState.role == AppRole.host;
    final hostBookingsAsync = ref.watch(hostBookingsProvider);
    final guestBookingsAsync = ref.watch(guestBookingsProvider);
    final tripsCount = isHost
        ? hostBookingsAsync.maybeWhen(data: (l) => l.length, orElse: () => 0)
        : guestBookingsAsync.maybeWhen(data: (l) => l.length, orElse: () => 0);

    // Watch user document for real-time reviews count
    final userDocStream = useMemoized(() {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
      return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    }, [FirebaseAuth.instance.currentUser?.uid]);
    final userDocSnapshot = useStream(userDocStream);
    final reviewsCount = userDocSnapshot.data?.data()?['reviewsCount'] ?? 1;

    // Calculate months on Nesty dynamically from creation time
    final user = FirebaseAuth.instance.currentUser;
    final creationTime = user?.metadata.creationTime ?? DateTime.now();
    final diffDays = DateTime.now().difference(creationTime).inDays;
    final monthsCount = (diffDays / 30).ceil().clamp(1, 100);

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
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          title: Text(
            'Profile',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.black,
            ),
          ),
          automaticallyImplyLeading: false,
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.black87,
                    size: 22,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00674F),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(context, authState, ref, tripsCount, reviewsCount, monthsCount),
                const SizedBox(height: 20),
                _buildQuickActions(context, ref),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSideCard(
                        title: 'Past trips',
                        imageUrl: 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?q=80&w=200',
                        isNew: true,
                        onTap: () => context.push('/trips?tab=1'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSideCard(
                        title: 'Connections',
                        imageUrl: 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?q=80&w=200',
                        isNew: true,
                        onTap: () => context.push('/connections'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildBecomeHostBanner(context, authState),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: _buildSwitchFloatingButton(context, authState),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const NestyBottomNav(currentIndex: 4),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context, 
    AuthState authState, 
    WidgetRef ref,
    int tripsCount,
    int reviewsCount,
    int monthsCount,
  ) {
    final displayName = authState.name ?? 'Guest';
    final emailAddress = authState.email ?? '';
    final roleName = authState.role == AppRole.host ? 'Host' : 'Guest';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _updateProfilePicture(context, ref),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade100, width: 2),
                        ),
                        child: ClipOval(
                          child: NestyImage(
                            src: (authState.photoUrl != null && authState.photoUrl!.isNotEmpty)
                                ? authState.photoUrl!
                                : 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=200',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00674F),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (emailAddress.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    emailAddress,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 1,
            height: 140,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            flex: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                _buildStatRow('$tripsCount', tripsCount == 1 ? 'Trip' : 'Trips'),
                Divider(height: 24, color: Colors.grey.shade100),
                _buildStatRow('$reviewsCount', reviewsCount == 1 ? 'Review' : 'Reviews'),
                Divider(height: 24, color: Colors.grey.shade100),
                _buildStatRow('$monthsCount', monthsCount == 1 ? 'Month on Nesty' : 'Months on Nesty'),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String count, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 1.5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSideCard({
    required String title,
    required String imageUrl,
    bool isNew = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Image with "NEW" Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    imageUrl,
                    height: 105,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (isNew)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A), // Dark slate/navy "NEW" badge
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'NEW',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Card Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBecomeHostBanner(BuildContext context, AuthState authState) {
    final bool isApproved = authState.isApproved;
    final bool isSubmitted = authState.isSubmitted;

    String titleText = 'Become a host';
    String subtitleText = "It's easy to start hosting and earn";
    VoidCallback? onTapAction;

    if (isApproved) {
      titleText = 'You are a Host!';
      subtitleText = 'Switch to hosting to manage your properties';
      onTapAction = () => context.push('/switching-hosting');
    } else if (isSubmitted) {
      titleText = 'Application Pending';
      subtitleText = 'We are verifying your host onboarding details';
      onTapAction = () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your host profile is currently under review by admin.',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            backgroundColor: Colors.black87,
          ),
        );
      };
    } else {
      titleText = 'Become a host';
      subtitleText = "It's easy to start hosting and earn";
      onTapAction = () => context.push('/become-host');
    }

    return GestureDetector(
      onTap: onTapAction,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: 3D Illustration of woman waving
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=150',
                width: 54,
                height: 54,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // Right: Banner Text details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        titleText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      if (isSubmitted && !isApproved) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PENDING',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitleText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Actions: Settings & Logout ───────────────
  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            icon: Icons.settings_outlined,
            label: 'Settings',
            iconColor: const Color(0xFF3B82F6),
            iconBg: const Color(0xFFEFF6FF),
            onTap: () => context.push('/settings'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionTile(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            iconColor: const Color(0xFFEF4444),
            iconBg: const Color(0xFFFEF2F2),
            isDestructive: true,
            onTap: () => _confirmLogout(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color iconBg,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive
                ? const Color(0xFFFECACA)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDestructive
                    ? const Color(0xFFEF4444)
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 12),
            Text('Log Out?',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your Nesty account?',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login', extra: {'role': 'guest'});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Log Out',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchFloatingButton(BuildContext context, AuthState authState) {
    final isHost = authState.role == AppRole.host;
    return _PremiumSwitchButton(
      label: isHost ? 'Switch to guest' : 'Switch to hosting',
      icon: Icons.swap_horiz_rounded,
      onTap: () => isHost
          ? context.push('/switching-guest')
          : context.push('/switching-hosting'),
    );
  }
}

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
                    )
                  ]
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
