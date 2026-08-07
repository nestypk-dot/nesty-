import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/nesty_image.dart';
import '../../host_onboarding/data/host_profile_repository.dart';
import '../providers/listings_provider.dart';

class HostSettingsScreen extends HookConsumerWidget {
  const HostSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = useState(0);

    // Watch Listings Statistics
    final listings = ref.watch(hostListingsProvider);
    final activeCount = listings.where((p) => p.status == 'published').length;
    final draftCount = listings.where((p) => p.status == 'pending' || p.status == 'draft').length;
    final pausedCount = listings.where((p) => p.status == 'paused' || p.status == 'rejected').length;

    // Watch Host Profile Settings
    final authState = ref.watch(authProvider);
    final hostProfileAsync = ref.watch(currentHostProfileProvider);
    final profile = hostProfileAsync.value;

    final displayNameController = useTextEditingController(text: profile?.fullName ?? authState.name ?? '');
    final aboutController = useTextEditingController(text: profile?.aboutHost ?? '');
    final customRulesController = useTextEditingController(text: profile?.customRules ?? '');
    final bookingConfirmationController = useTextEditingController(text: profile?.bookingConfirmationMessage ?? 'Thank you for booking! We\'re excited to host you...');
    final preCheckInController = useTextEditingController(text: profile?.preCheckInMessage ?? 'Looking forward to your arrival tomorrow! Here are the check-in details...');

    final selectedLanguages = useState<List<String>>(['English', 'Urdu']);
    final contactPreference = useState('In-app messaging only');
    
    // Rules State
    final checkInTime = useState('02:00 PM');
    final checkOutTime = useState('11:00 AM');
    final smokingAllowed = useState(false);
    final petsAllowed = useState(false);
    final eventsAllowed = useState(false);
    final familyFriendly = useState(true);
    final bachelorAllowed = useState(false);
    final selectedPolicy = useState('Flexible');

    // Guest Requirements State
    final idRequired = useState(true);
    final photoRequired = useState(false);
    final messageRequired = useState(true);
    final phoneRequired = useState(true);
    final manualApproval = useState(false);

    // Messaging State
    final autoReplyEnabled = useState(false);

    // Alerts State
    final notifyBookingRequests = useState(true);
    final notifyBookingConfirmations = useState(true);
    final notifyMessages = useState(true);
    final notifyPayouts = useState(true);
    final notifyReviews = useState(true);
    final notifyEmail = useState(true);
    final notifySMS = useState(false);

    useEffect(() {
      if (profile != null) {
        displayNameController.text = profile.fullName;
        aboutController.text = profile.aboutHost;
        selectedLanguages.value = profile.languages.isNotEmpty ? profile.languages : ['English', 'Urdu'];
        contactPreference.value = profile.contactPreference.isNotEmpty ? profile.contactPreference : 'In-app messaging only';
        checkInTime.value = profile.checkInTime.isNotEmpty ? profile.checkInTime : '02:00 PM';
        checkOutTime.value = profile.checkOutTime.isNotEmpty ? profile.checkOutTime : '11:00 AM';
        smokingAllowed.value = profile.smokingAllowed;
        petsAllowed.value = profile.petsAllowed;
        eventsAllowed.value = profile.eventsAllowed;
        familyFriendly.value = profile.familyFriendly;
        bachelorAllowed.value = profile.bachelorAllowed;
        selectedPolicy.value = profile.cancellationPolicy.isNotEmpty ? profile.cancellationPolicy : 'Flexible';
        customRulesController.text = profile.customRules;

        idRequired.value = profile.idRequired;
        photoRequired.value = profile.photoRequired;
        messageRequired.value = profile.messageRequired;
        phoneRequired.value = profile.phoneRequired;
        manualApproval.value = profile.manualApproval;

        autoReplyEnabled.value = profile.autoReplyEnabled;
        bookingConfirmationController.text = profile.bookingConfirmationMessage;
        preCheckInController.text = profile.preCheckInMessage;

        notifyBookingRequests.value = profile.notifyBookingRequests;
        notifyBookingConfirmations.value = profile.notifyBookingConfirmations;
        notifyMessages.value = profile.notifyMessages;
        notifyPayouts.value = profile.notifyPayouts;
        notifyReviews.value = profile.notifyReviews;
        notifyEmail.value = profile.notifyEmail;
        notifySMS.value = profile.notifySMS;
      } else if (authState.name != null) {
        displayNameController.text = authState.name!;
      }
    }, [profile, authState.name]);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Host Settings',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.black),
            ),
            Text(
              'میزبان کی ترتیبات',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Back'),
            ),
          ),
        ],
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          if (profile?.status == 'rejected')
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gavel_rounded, color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Application Rejected',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile?.rejectionReason ?? 'Please update and re-submit your profile.',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () => context.push('/become-host'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Update Profile',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Custom Tab Bar
          _buildTabBar(tabIndex),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: _buildTabContent(
                context,
                ref,
                tabIndex.value, 
                selectedLanguages, 
                contactPreference,
                smokingAllowed,
                petsAllowed,
                eventsAllowed,
                familyFriendly,
                bachelorAllowed,
                selectedPolicy,
                idRequired,
                photoRequired,
                messageRequired,
                phoneRequired,
                manualApproval,
                autoReplyEnabled,
                bookingConfirmationController,
                preCheckInController,
                notifyBookingRequests,
                notifyBookingConfirmations,
                notifyMessages,
                notifyPayouts,
                notifyReviews,
                notifyEmail,
                notifySMS,
                activeCount,
                draftCount,
                pausedCount,
                displayNameController,
                aboutController,
                customRulesController,
                checkInTime,
                checkOutTime,
                authState,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ValueNotifier<int> tabIndex) {
    final tabs = [
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
      {'icon': Icons.home_work_outlined, 'label': 'Listings'},
      {'icon': Icons.rule_rounded, 'label': 'Rules'},
      {'icon': Icons.people_outline_rounded, 'label': 'Guests'},
      {'icon': Icons.message_outlined, 'label': 'Messages'},
      {'icon': Icons.notifications_none_rounded, 'label': 'Alerts'},
      {'icon': Icons.security_outlined, 'label': 'Security'},
    ];

    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.sectionColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = tabIndex.value == index;
          return GestureDetector(
            onTap: () => tabIndex.value = index,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tabs[index]['icon'] as IconData, size: 20, color: isSelected ? Colors.black : Colors.grey),
                  const SizedBox(height: 4),
                  Text(
                    tabs[index]['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.black : Colors.grey,
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

  Widget _buildTabContent(
    BuildContext context,
    WidgetRef ref,
    int index,
    ValueNotifier<List<String>> selectedLanguages,
    ValueNotifier<String> contactPreference,
    ValueNotifier<bool> smokingAllowed,
    ValueNotifier<bool> petsAllowed,
    ValueNotifier<bool> eventsAllowed,
    ValueNotifier<bool> familyFriendly,
    ValueNotifier<bool> bachelorAllowed,
    ValueNotifier<String> selectedPolicy,
    ValueNotifier<bool> idRequired,
    ValueNotifier<bool> photoRequired,
    ValueNotifier<bool> messageRequired,
    ValueNotifier<bool> phoneRequired,
    ValueNotifier<bool> manualApproval,
    ValueNotifier<bool> autoReplyEnabled,
    TextEditingController bookingConfirmationController,
    TextEditingController preCheckInController,
    ValueNotifier<bool> notifyBookingRequests,
    ValueNotifier<bool> notifyBookingConfirmations,
    ValueNotifier<bool> notifyMessages,
    ValueNotifier<bool> notifyPayouts,
    ValueNotifier<bool> notifyReviews,
    ValueNotifier<bool> notifyEmail,
    ValueNotifier<bool> notifySMS,
    int activeCount,
    int draftCount,
    int pausedCount,
    TextEditingController displayNameController,
    TextEditingController aboutController,
    TextEditingController customRulesController,
    ValueNotifier<String> checkInTime,
    ValueNotifier<String> checkOutTime,
    AuthState authState,
  ) {
    switch (index) {
      case 0: return _buildProfileTab(context, ref, displayNameController, aboutController, selectedLanguages, contactPreference, authState);
      case 1: return _buildListingsTab(context, activeCount, draftCount, pausedCount);
      case 2: return _buildRulesTab(
        context,
        ref,
        checkInTime,
        checkOutTime,
        smokingAllowed,
        petsAllowed,
        eventsAllowed,
        familyFriendly,
        bachelorAllowed,
        selectedPolicy,
        customRulesController,
      );
      case 3: return _buildGuestsTab(
        context,
        ref,
        idRequired,
        photoRequired,
        messageRequired,
        phoneRequired,
        manualApproval,
      );
      case 4: return _buildMessagesTab(
        context,
        ref,
        autoReplyEnabled,
        bookingConfirmationController,
        preCheckInController,
      );
      case 5: return _buildAlertsTab(
        context,
        ref,
        notifyBookingRequests,
        notifyBookingConfirmations,
        notifyMessages,
        notifyPayouts,
        notifyReviews,
        notifyEmail,
        notifySMS,
      );
      case 6: return _buildSecurityTab(context, ref);
      default: return const Center(child: Text('Coming Soon...'));
    }
  }

  Widget _buildProfileTab(
    BuildContext context,
    WidgetRef ref,
    TextEditingController displayNameController,
    TextEditingController aboutController,
    ValueNotifier<List<String>> selectedLanguages,
    ValueNotifier<String> contactPreference,
    AuthState authState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Host Profile', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16)),
              Text('Build trust with potential guests', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipOval(
                          child: NestyImage(
                            src: (authState.photoUrl != null && authState.photoUrl!.isNotEmpty)
                                ? authState.photoUrl!
                                : 'https://i.pravatar.cc/150?u=muhammad',
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          bottom: 0, 
                          right: 0, 
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 82,
                                maxWidth: 400,
                              );
                              if (picked != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Updating profile photo...')),
                                );
                                await ref.read(authProvider.notifier).updateProfilePhoto(picked.path);
                                ScaffoldMessenger.of(context).clearSnackBars();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white, 
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                              ),
                              child: Icon(Icons.camera_alt_rounded, color: AppTheme.primaryColor, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Profile photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildInputLabel('Display Name'),
              TextField(
                controller: displayNameController,
                decoration: InputDecoration(
                  hintText: 'Display Name',
                  filled: true,
                  fillColor: AppTheme.sectionColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 24),
              _buildInputLabel('About Host', urdu: 'میزبان کے بارے میں'),
              TextField(
                controller: aboutController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tell guests about yourself...',
                  filled: true,
                  fillColor: AppTheme.sectionColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 24),
              _buildInputLabel('Languages Spoken'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'English', 'Urdu', 'Punjabi', 'Sindhi', 'Pashto'
                ].map((lang) => _buildChip(lang, selectedLanguages)).toList(),
              ),
              const SizedBox(height: 24),
              _buildInputLabel('Contact Preference'),
              _buildDropdown(contactPreference),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saving profile settings...')),
                    );
                    await ref.read(hostProfileRepositoryProvider).updateHostSettings(
                      fullName: displayNameController.text.trim(),
                      aboutHost: aboutController.text.trim(),
                      languages: selectedLanguages.value,
                      contactPreference: contactPreference.value,
                    );
                    await ref.read(authProvider.notifier).refreshUserProfile();
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile settings saved successfully!'),
                        backgroundColor: Color(0xFF008E6B),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving profile settings: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008E6B),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Profile Settings', 
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildPerformanceStats(),
      ],
    );
  }

  Widget _buildListingsTab(BuildContext context, int activeCount, int draftCount, int pausedCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manage Listings', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16)),
          Text('Control your properties', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildListingStatCard('$activeCount', 'Active Listings', const Color(0xFFE8FDF5), const Color(0xFF008E6B)),
              const SizedBox(width: 10),
              _buildListingStatCard('$draftCount', 'Draft Listings', const Color(0xFFFFF7E6), const Color(0xFFFFA500)),
              const SizedBox(width: 10),
              _buildListingStatCard('$pausedCount', 'Paused Listings', const Color(0xFFF3F4F6), Colors.grey.shade600),
            ],
          ),
          const SizedBox(height: 32),
          _buildListingButton(
            context,
            Icons.home_outlined, 
            'View All Listings', 
            Colors.white, 
            Colors.black, 
            border: Border.all(color: Colors.grey.shade200),
            onTap: () => context.push('/listings'),
          ),
          const SizedBox(height: 12),
          _buildListingButton(
            context,
            Icons.home_work_outlined, 
            'Add New Listing', 
            const Color(0xFF008E6B), 
            Colors.white, 
            onTap: () => context.push('/add-property'),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesTab(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String> checkInTime,
    ValueNotifier<String> checkOutTime,
    ValueNotifier<bool> smokingAllowed,
    ValueNotifier<bool> petsAllowed,
    ValueNotifier<bool> eventsAllowed,
    ValueNotifier<bool> familyFriendly,
    ValueNotifier<bool> bachelorAllowed,
    ValueNotifier<String> selectedPolicy,
    TextEditingController customRulesController,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24), 
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Check-in & Check-out', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTimePicker(context, 'Check-in Time', checkInTime)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimePicker(context, 'Check-out Time', checkOutTime)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24), 
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('House Rules', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 15)),
              Text('Set expectations for guests', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              const SizedBox(height: 24),
              _buildRuleSwitch('Smoking Allowed', 'تمباکو نوشی کی اجازت', smokingAllowed),
              _buildRuleSwitch('Pets Allowed', 'پالتو جانوروں کی اجازت', petsAllowed),
              _buildRuleSwitch('Events Allowed', 'تقریبات کی اجازت', eventsAllowed),
              _buildRuleSwitch('Family Friendly', 'خاندانوں کے لیے موزوں', familyFriendly),
              _buildRuleSwitch('Bachelor Allowed', 'اکیلے افراد کی اجازت', bachelorAllowed),
              const SizedBox(height: 24),
              _buildInputLabel('Custom House Rules'),
              TextField(
                controller: customRulesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add any additional rules for guests...',
                  filled: true,
                  fillColor: AppTheme.sectionColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 24),
              Text('Cancellation Policy', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 12),
              _buildPolicyCard('Flexible', 'Full refund 24 hours before check-in', selectedPolicy),
              _buildPolicyCard('Moderate', 'Full refund 5 days before check-in', selectedPolicy),
              _buildPolicyCard('Strict', '50% refund up to 7 days before', selectedPolicy),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saving house rules...')),
                    );
                    await ref.read(hostProfileRepositoryProvider).updateHostSettings(
                      checkInTime: checkInTime.value,
                      checkOutTime: checkOutTime.value,
                      smokingAllowed: smokingAllowed.value,
                      petsAllowed: petsAllowed.value,
                      eventsAllowed: eventsAllowed.value,
                      familyFriendly: familyFriendly.value,
                      bachelorAllowed: bachelorAllowed.value,
                      cancellationPolicy: selectedPolicy.value,
                      customRules: customRulesController.text.trim(),
                    );
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('House rules saved successfully!'),
                        backgroundColor: Color(0xFF008E6B),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving house rules: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008E6B),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Save House Rules', 
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- REUSABLE COMPONENTS ---

  Widget _buildInputLabel(String label, {String? urdu}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black)),
        if (urdu != null) ...[
          const SizedBox(height: 2),
          Text(urdu, style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTextField(String value, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.sectionColor, 
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }

  Widget _buildTextArea(String hint) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.sectionColor, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildChip(String label, ValueNotifier<List<String>> selectedLanguages) {
    final isSelected = selectedLanguages.value.contains(label);
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          selectedLanguages.value = selectedLanguages.value.where((l) => l != label).toList();
        } else {
          selectedLanguages.value = [...selectedLanguages.value, label];
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF008E6B) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFF008E6B) : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF008E6B).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87, 
            fontWeight: FontWeight.w800, 
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(ValueNotifier<String> contactPreference) {
    return PopupMenuButton<String>(
      onSelected: (val) => contactPreference.value = val,
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        'In-app messaging only',
        'In-app messaging & Email',
        'Direct Phone Call',
      ].map((opt) => PopupMenuItem(
        value: opt,
        child: Text(
          opt,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.sectionColor, 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              contactPreference.value, 
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance Stats', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatItem('0', 'Active Listings'),
              _buildStatItem('0', 'Avg Rating'),
              _buildStatItem('0', 'Total Reviews'),
              _buildStatItem('95%', 'Response Rate'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.sectionColor, 
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF008E6B))),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildListingStatCard(String val, String label, Color bg, Color text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: bg, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: text.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: text.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: text)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: text.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildListingButton(
    BuildContext context,
    IconData icon, 
    String label, 
    Color bg, 
    Color text, {
    BoxBorder? border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg, 
          borderRadius: BorderRadius.circular(14), 
          border: border,
          boxShadow: [
            if (bg != Colors.white)
              BoxShadow(
                color: bg.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: text, size: 20),
            const SizedBox(width: 12),
            Text(
              label, 
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: text, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context, String label, ValueNotifier<String> timeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.black87)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            TimeOfDay initialTime = const TimeOfDay(hour: 14, minute: 0);
            try {
              final cleanTime = timeState.value.replaceAll(RegExp(r'\s+'), ' ');
              final parts = cleanTime.split(' ');
              final timeParts = parts[0].split(':');
              int hour = int.parse(timeParts[0]);
              int minute = int.parse(timeParts[1]);
              final amPm = parts[1].toUpperCase();
              if (amPm == 'PM' && hour < 12) hour += 12;
              if (amPm == 'AM' && hour == 12) hour = 0;
              initialTime = TimeOfDay(hour: hour, minute: minute);
            } catch (_) {}

            final picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
            );
            if (picked != null) {
              final formatted = picked.format(context);
              timeState.value = formatted;
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(timeState.value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black)),
                const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleSwitch(String title, String urdu, ValueNotifier<bool> state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.sectionColor, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: state.value ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black)),
                Text(urdu, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Switch(
            value: state.value,
            onChanged: (v) => state.value = v,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF008E6B),
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(String title, String desc, ValueNotifier<String> selectedPolicy) {
    final isSelected = selectedPolicy.value == title;
    return GestureDetector(
      onTap: () => selectedPolicy.value = title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF008E6B) : Colors.grey.shade200, 
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF008E6B).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 22, 
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF008E6B) : Colors.grey.shade300, 
                  width: 2,
                ),
              ),
              child: isSelected 
                ? Center(
                    child: Container(
                      width: 12, 
                      height: 12, 
                      decoration: const BoxDecoration(color: Color(0xFF008E6B), shape: BoxShape.circle),
                    ),
                  ) 
                : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black),
                  ),
                  Text(
                    desc, 
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 4: GUESTS ---
  Widget _buildGuestsTab(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> idRequired,
    ValueNotifier<bool> photoRequired,
    ValueNotifier<bool> messageRequired,
    ValueNotifier<bool> phoneRequired,
    ValueNotifier<bool> manualApproval,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Guest Requirements', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16)),
              Text('Safety & filtering options', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 24),
              _buildGuestRequirementSwitch(
                'Government ID Required', 
                'Guests must provide CNIC or passport', 
                idRequired
              ),
              _buildGuestRequirementSwitch(
                'Profile Photo Required', 
                'Guests must have a profile picture', 
                photoRequired
              ),
              _buildGuestRequirementSwitch(
                'Booking Message Required', 
                'Guests must send a message with request', 
                messageRequired
              ),
              _buildGuestRequirementSwitch(
                'Phone Verified Required', 
                'Only verified phone numbers', 
                phoneRequired
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF3F4F6), thickness: 1),
              const SizedBox(height: 16),
              _buildGuestRequirementSwitch(
                'Manual Approval', 
                'Review all booking requests before accepting', 
                manualApproval,
                isHighlighted: true,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saving guest requirements...')),
                    );
                    await ref.read(hostProfileRepositoryProvider).updateHostSettings(
                      idRequired: idRequired.value,
                      photoRequired: photoRequired.value,
                      messageRequired: messageRequired.value,
                      phoneRequired: phoneRequired.value,
                      manualApproval: manualApproval.value,
                    );
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Guest requirements saved successfully!'),
                        backgroundColor: Color(0xFF008E6B),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving guest requirements: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008E6B),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Guest Requirements', 
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuestRequirementSwitch(
    String title, 
    String subtitle, 
    ValueNotifier<bool> state,
    {bool isHighlighted = false}
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? const Color(0xFFE8F3FF) // Light blue for highlighted
            : const Color(0xFFF9FAFB), // Regular light gray
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted 
              ? const Color(0xFFC7E2FF) 
              : Colors.transparent
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800, 
                    fontSize: 14, 
                    color: isHighlighted ? const Color(0xFF1E40AF) : Colors.black
                  )
                ),
                Text(
                  subtitle, 
                  style: TextStyle(
                    fontSize: 11, 
                    color: isHighlighted ? const Color(0xFF3B82F6) : Colors.grey.shade500, 
                    fontWeight: FontWeight.w600
                  )
                ),
              ],
            ),
          ),
          Switch(
            value: state.value,
            onChanged: (v) => state.value = v,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF80E8DD), // Light cyan/teal as in image
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  // --- TAB 5: MESSAGES ---
  Widget _buildMessagesTab(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> autoReplyEnabled,
    TextEditingController bookingConfirmationController,
    TextEditingController preCheckInController,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Messaging & Communication', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16)),
              Text('Auto-replies and templates', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 24),
              
              _buildGuestRequirementSwitch(
                'Auto-Reply Enabled', 
                'Send automatic replies to new messages', 
                autoReplyEnabled
              ),
              
              const SizedBox(height: 24),
              _buildInputLabel('Booking Confirmation Message'),
              _buildEditableTextArea(bookingConfirmationController),
              
              const SizedBox(height: 24),
              _buildInputLabel('Pre-Check-in Message'),
              _buildEditableTextArea(preCheckInController),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saving messaging settings...')),
                    );
                    await ref.read(hostProfileRepositoryProvider).updateHostSettings(
                      autoReplyEnabled: autoReplyEnabled.value,
                      bookingConfirmationMessage: bookingConfirmationController.text.trim(),
                      preCheckInMessage: preCheckInController.text.trim(),
                    );
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Messaging settings saved successfully!'),
                        backgroundColor: Color(0xFF008E6B),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving messaging settings: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008E6B),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Messaging Settings', 
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableTextArea(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sectionColor, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: 4,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
        decoration: InputDecoration(
          hintText: 'Type your message here...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  // --- TAB 5: ALERTS ---
  Widget _buildAlertsTab(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> notifyBookingRequests,
    ValueNotifier<bool> notifyBookingConfirmations,
    ValueNotifier<bool> notifyMessages,
    ValueNotifier<bool> notifyPayouts,
    ValueNotifier<bool> notifyReviews,
    ValueNotifier<bool> notifyEmail,
    ValueNotifier<bool> notifySMS,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notification Preferences', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16)),
              Text('Stay informed about your hosting activity', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 24),
              
              Text('What to notify', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 16),
              
              _buildGuestRequirementSwitch('Booking Requests', 'New booking requests', notifyBookingRequests),
              _buildGuestRequirementSwitch('Booking Confirmations', 'Confirmed bookings', notifyBookingConfirmations),
              _buildGuestRequirementSwitch('Messages', 'New guest messages', notifyMessages),
              _buildGuestRequirementSwitch('Payout Updates', 'Earnings and withdrawals', notifyPayouts),
              _buildGuestRequirementSwitch('Reviews', 'New guest reviews', notifyReviews),
              
              const SizedBox(height: 24),
              
              Text('Notification Channels', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 16),
              
              _buildGuestRequirementSwitch('Email Notifications', 'muhammad.haad96@gmail.com', notifyEmail),
              _buildGuestRequirementSwitch('SMS Notifications', 'Add phone number', notifySMS),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saving notification settings...')),
                    );
                    await ref.read(hostProfileRepositoryProvider).updateHostSettings(
                      notifyBookingRequests: notifyBookingRequests.value,
                      notifyBookingConfirmations: notifyBookingConfirmations.value,
                      notifyMessages: notifyMessages.value,
                      notifyPayouts: notifyPayouts.value,
                      notifyReviews: notifyReviews.value,
                      notifyEmail: notifyEmail.value,
                      notifySMS: notifySMS.value,
                    );
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification settings saved successfully!'),
                        backgroundColor: Color(0xFF008E6B),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving notification settings: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008E6B),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Notification Settings', 
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityTab(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final hostProfileAsync = ref.watch(currentHostProfileProvider);
    final profile = hostProfileAsync.value;

    final String email = (authState.email != null && authState.email!.isNotEmpty) ? authState.email! : (FirebaseAuth.instance.currentUser?.email ?? 'Not available');
    final phone = profile?.primaryPhone.isNotEmpty == true ? profile!.primaryPhone : (authState.phone ?? 'Not added');

    Widget cnicTrailing;
    if (profile?.isApproved == true) {
      cnicTrailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      );
    } else if (profile?.isSubmitted == true) {
      cnicTrailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pending_actions_rounded, size: 16, color: Color(0xFFF59E0B)),
          const SizedBox(width: 4),
          Text(
            'Pending Review',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
      );
    } else if (profile?.cnicNumber.isNotEmpty == true) {
      cnicTrailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            'Submitted',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.blue,
            ),
          ),
        ],
      );
    } else {
      cnicTrailing = Text(
        'Optional',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account Security Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Security',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Protect your hosting account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
              
              // Email
              _buildSecurityItem(
                title: 'Email',
                subtitle: email,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Phone Number
              _buildSecurityItem(
                title: 'Phone Number',
                subtitle: phone,
                trailing: phone == 'Not added'
                  ? SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        onPressed: () {
                          context.push('/become-host');
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Add',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
              ),

              // CNIC Verification
              _buildSecurityItem(
                title: 'CNIC Verification',
                subtitle: 'Government ID verification',
                trailing: cnicTrailing,
                showBorder: false,
              ),
              
              const SizedBox(height: 24),
              
              // Change Password Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () async {
                    if (email == 'Not available' || email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email address not found. Please log in again.')),
                      );
                      return;
                    }
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sending password reset email to $email...')),
                      );
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Password reset link sent to $email!'),
                          backgroundColor: const Color(0xFF008E6B),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sending password reset: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Change Password',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text(
                          'Logout',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
                        ),
                        content: Text(
                          'Are you sure you want to log out of Nesty?',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Logout',
                              style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logging out...')),
                      );
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        context.go('/login');
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Logout from All Devices',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Performance & Reviews Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance & Reviews',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      value: '0',
                      label: 'Avg Rating',
                      valueColor: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      value: '0',
                      label: 'Reviews',
                      valueColor: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      value: '95%',
                      label: 'Response Rate',
                      valueColor: const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      value: '92%',
                      label: 'Acceptance Rate',
                      valueColor: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // View Full Stats Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Performance stats details feature coming soon!'),
                        backgroundColor: Color(0xFF008E6B),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'View Full Performance Stats',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityItem({
    required String title,
    required String subtitle,
    required Widget trailing,
    bool showBorder = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
