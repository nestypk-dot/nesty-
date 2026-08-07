import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Account Section ──────────────────────
          _sectionHeader('Account'),
          _buildCard([
            _buildNavItem(
              Icons.person_outline_rounded,
              'Edit Profile',
              'Update your name, photo, and bio',
              const Color(0xFF3B82F6),
              onTap: () => context.push('/profile'),
            ),
            _buildDivider(),
            _buildNavItem(
              Icons.lock_outline_rounded,
              'Change Password',
              'Update your account password',
              const Color(0xFF8B5CF6),
              onTap: () {
                final email = authState.email;
                if (email != null && email.isNotEmpty) {
                  _showChangePasswordDialog(email);
                } else {
                  _showComingSoon('Change Password (No email registered)');
                }
              },
            ),
            _buildDivider(),
            _buildNavItem(
              Icons.phone_outlined,
              'Phone Number',
              authState.phone ?? 'Not set',
              const Color(0xFF10B981),
              onTap: () => _showPhoneUpdateDialog(authState.phone ?? 'Not set'),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Notifications Section ─────────────────
          _sectionHeader('Notifications'),
          _buildCard([
            _buildToggleItem(
              Icons.calendar_today_outlined,
              'Booking Updates',
              'New bookings, cancellations & confirmations',
              const Color(0xFF00674F),
              authState.bookingNotifs,
              (val) => ref.read(authProvider.notifier).updateUserSettings(bookingNotifs: val),
            ),
            _buildDivider(),
            _buildToggleItem(
              Icons.chat_bubble_outline_rounded,
              'Messages',
              'New messages from hosts & guests',
              const Color(0xFF3B82F6),
              authState.messageNotifs,
              (val) => ref.read(authProvider.notifier).updateUserSettings(messageNotifs: val),
            ),
            _buildDivider(),
            _buildToggleItem(
              Icons.star_outline_rounded,
              'Reviews',
              'When someone leaves you a review',
              const Color(0xFFF59E0B),
              authState.reviewNotifs,
              (val) => ref.read(authProvider.notifier).updateUserSettings(reviewNotifs: val),
            ),
            _buildDivider(),
            _buildToggleItem(
              Icons.local_offer_outlined,
              'Promotions & Offers',
              'Deals, coupons and special events',
              const Color(0xFFEC4899),
              authState.promoNotifs,
              (val) => ref.read(authProvider.notifier).updateUserSettings(promoNotifs: val),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Privacy Section ───────────────────────
          _sectionHeader('Privacy'),
          _buildCard([
            _buildToggleItem(
              Icons.visibility_outlined,
              'Online Status',
              'Let others see when you\'re active',
              const Color(0xFF10B981),
              authState.showOnlineStatus,
              (val) => ref.read(authProvider.notifier).updateUserSettings(showOnlineStatus: val),
            ),
            _buildDivider(),
            _buildToggleItem(
              Icons.public_rounded,
              'Public Profile',
              'Allow your profile to be visible to others',
              const Color(0xFF6366F1),
              authState.showProfilePublicly,
              (val) => ref.read(authProvider.notifier).updateUserSettings(showProfilePublicly: val),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Support Section ───────────────────────
          _sectionHeader('Support'),
          _buildCard([
            _buildNavItem(
              Icons.help_outline_rounded,
              'Help Center',
              'FAQs and support articles',
              const Color(0xFF0EA5E9),
              onTap: () => context.push('/help-center'),
            ),
            _buildDivider(),
            _buildNavItem(
              Icons.feedback_outlined,
              'Send Feedback',
              'Tell us what you think',
              const Color(0xFF8B5CF6),
              onTap: () => _showSendFeedbackDialog(),
            ),
            _buildDivider(),
            _buildNavItem(
              Icons.policy_outlined,
              'Privacy Policy',
              'How we handle your data',
              const Color(0xFF6B7280),
              onTap: () => context.push('/privacy-policy'),
            ),
            _buildDivider(),
            _buildNavItem(
              Icons.description_outlined,
              'Terms of Service',
              'Our rules and guidelines',
              const Color(0xFF6B7280),
              onTap: () => context.push('/terms-of-service'),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Danger Zone ───────────────────────────
          _sectionHeader('Account Actions'),
          _buildCard([
            _buildNavItem(
              Icons.logout_rounded,
              'Log Out',
              'Sign out of your account',
              const Color(0xFFEF4444),
              isDestructive: true,
              onTap: () => _showLogoutDialog(),
            ),
            _buildDivider(),
            _buildNavItem(
              Icons.delete_outline_rounded,
              'Delete Account',
              'Permanently remove your account',
              const Color(0xFFDC2626),
              isDestructive: true,
              onTap: () => _showDeleteAccountDialog(),
            ),
          ]),

          const SizedBox(height: 32),

          // App version
          Center(
            child: Text(
              'Nesty v1.0.0',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() =>
      const Divider(height: 1, thickness: 0.5, indent: 56, color: Color(0xFFF1F5F9));

  Widget _buildNavItem(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDestructive ? const Color(0xFFEF4444) : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDestructive ? Colors.red.shade200 : Colors.grey.shade400,
        size: 20,
      ),
    );
  }

  Widget _buildToggleItem(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showSendFeedbackDialog() {
    final feedbackController = TextEditingController();
    double rating = 5.0;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Send Feedback 💬',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How is your experience with Nesty?',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      starIndex <= rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 32,
                    ),
                    onPressed: () =>
                        setDialogState(() => rating = starIndex.toDouble()),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your suggestions or issues...',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade600, fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final text = feedbackController.text.trim();
                      setDialogState(() => isSubmitting = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        await FirebaseFirestore.instance
                            .collection('feedback')
                            .add({
                          'userId': user?.uid ?? 'guest',
                          'userEmail': user?.email ?? 'anonymous',
                          'userName': user?.displayName ?? 'User',
                          'rating': rating,
                          'feedback': text,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Thank you for your feedback! / آپ کی رائے کا شکریہ',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: const Color(0xFF00674F),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Submit',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        '$feature coming soon!',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.black87,
    ));
  }

  void _showChangePasswordDialog(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Password?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
        content: Text(
          'We will send a password reset link to your registered email address:\n\n$email',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password reset email sent to $email / پاسورڈ ری سیٹ لنک بھیج دیا گیا ہے'),
                    backgroundColor: const Color(0xFF00674F),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Send Link',
                style:
                    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showPhoneUpdateDialog(String currentPhone) {
    final controller = TextEditingController(text: currentPhone == 'Not set' ? '' : currentPhone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Update Phone Number',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your new phone number below:',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'e.g. 03304582501',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPhone = controller.text.trim();
              if (newPhone.isNotEmpty) {
                Navigator.pop(ctx);
                try {
                  await ref.read(authProvider.notifier).updatePhoneNumber(newPhone);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number updated successfully! / فون نمبر تبدیل ہو گیا ہے'),
                      backgroundColor: Color(0xFF00674F),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save',
                style:
                    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: const Color(0xFFEF4444))),
        content: Text(
          'Are you sure you want to permanently delete your Nesty account? This action is permanent and cannot be undone.',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(authProvider.notifier).deleteAccount();
                if (!mounted) return;
                context.go('/login', extra: {'role': 'guest'});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your account has been deleted. / آپ کا اکاؤنٹ حذف کر دیا گیا ہے'),
                    backgroundColor: Colors.black87,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                if (e.toString().contains('requires-recent-login')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log out and log back in to delete your account for security reasons.'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete',
                style:
                    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
        content: Text(
          'Are you sure you want to log out of your Nesty account?',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (!mounted) return;
              context.go('/login', extra: {'role': 'guest'});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Log Out',
                style:
                    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
