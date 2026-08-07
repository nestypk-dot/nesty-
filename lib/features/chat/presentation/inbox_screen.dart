import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/nesty_bottom_nav.dart';
import '../providers/chat_provider.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen>
    with SingleTickerProviderStateMixin {
  int _activeTabIndex = 0;
  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  // ── Time Formatters ──────────────────────────
  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) return DateFormat.jm().format(dateTime);
    if (messageDate == yesterday) return 'Yesterday';
    if (now.difference(dateTime).inDays < 7)
      return DateFormat('EEE').format(dateTime);
    return DateFormat('MMM d').format(dateTime);
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }

  // ── Dialogs ─────────────────────────────────
  void _showPromoDialog(String couponCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Coupon Claimed! 🎉',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your discount coupon is active and saved to your wallet.',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    couponCode,
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppTheme.primaryColor,
                        letterSpacing: 1),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Coupon copied!',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700)),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ));
                    },
                    child:
                        const Icon(Icons.copy_rounded, size: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(String hotelName) {
    double ratingValue = 5.0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text('Rate your stay',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 24),
                  ],
                ),
                const SizedBox(height: 4),
                Text(hotelName,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      icon: Icon(
                        starIndex <= ratingValue
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 38,
                      ),
                      onPressed: () =>
                          setStateBuilder(() => ratingValue = starIndex.toDouble()),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share details of your experience...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Review submitted! Thank you.',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700)),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text('Submit',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Swipe to delete ───────────────────────────
  void _confirmDeleteConversation(String conversationId, String peerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Chat',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
        content: Text(
          'Delete your conversation with $peerName? This cannot be undone.',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(chatServiceProvider)
                  .deleteConversation(conversationId);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Conversation deleted.',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700)),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            },
            child: Text('Delete',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── BUILD ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final unreadAsync = ref.watch(totalUnreadCountProvider);
    final totalUnread = unreadAsync.asData?.value ?? 0;

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
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
        title: Row(
          children: [
            Text(
              'Inbox',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black),
            ),
            if (totalUnread > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00674F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalUnread',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined,
                color: Colors.black, size: 22),
            onPressed: () => context.push('/connections'),
            tooltip: 'Connections',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _activeTabIndex == 0
          ? ScaleTransition(
              scale: _fabAnimController,
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/connections'),
                backgroundColor: const Color(0xFF00674F),
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text(
                  'New Chat',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            )
          : null,
      bottomNavigationBar: const NestyBottomNav(currentIndex: 3),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tab Switcher ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Row(
              children: [
                _buildTab('Messages', index: 0),
                const SizedBox(width: 32),
                _buildTab('Notifications', index: 1),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          Expanded(
            child: _activeTabIndex == 0
                ? _buildMessagesTab()
                : _buildNotificationsTab(),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTab(String label, {required int index}) {
    final bool isActive = _activeTabIndex == index;

    // Count unread for messages tab badge
    int tabBadge = 0;
    if (index == 0) {
      tabBadge = ref.watch(totalUnreadCountProvider).asData?.value ?? 0;
    } else if (index == 1) {
      final notifs = ref.watch(notificationsProvider).asData?.value ?? [];
      tabBadge = notifs.where((n) => !n.isRead).length;
    }

    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  color: isActive ? Colors.black : Colors.black38,
                ),
              ),
              if (tabBadge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00674F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$tabBadge',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 3,
            width: isActive ? 28 : 0,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ── MESSAGES TAB ─────────────────────────────
  Widget _buildMessagesTab() {
    final conversationsAsync = ref.watch(conversationsProvider);

    return conversationsAsync.when(
      data: (conversations) {
        if (conversations.isEmpty) return _buildEmptyMessages();

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          itemCount: conversations.length,
          separatorBuilder: (context, index) => const Divider(
              height: 1, thickness: 0.5, indent: 96, color: Color(0xFFEEEEEE)),
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _buildConversationItem(context, conversation);
          },
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      error: (err, stack) => _buildErrorState('messages'),
    );
  }

  Widget _buildConversationItem(
      BuildContext context, ChatConversation conversation) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String currentUid = currentUser?.uid ?? '';
    final isGuest = currentUid == conversation.guestId;

    final peerName = isGuest ? conversation.hostName : conversation.guestName;
    final peerAvatar = isGuest ? conversation.hostAvatar : conversation.guestAvatar;
    final peerId = isGuest ? conversation.hostId : conversation.guestId;
    final hasUnread = conversation.unreadCount > 0;
    final isLastSenderMe = conversation.lastSenderId == currentUid;

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded,
                color: Colors.red.shade400, size: 26),
            const SizedBox(height: 4),
            Text('Delete',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.red.shade400,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        _confirmDeleteConversation(conversation.id, peerName);
        return false;
      },
      child: InkWell(
        onTap: () async {
          // Mark as read when opening
          await ref
              .read(chatServiceProvider)
              .markConversationAsRead(conversation.id);
          if (!mounted) return;
          context.push('/chat', extra: {
            'peerId': peerId,
            'peerName': peerName,
            'peerImageUrl': peerAvatar,
            'conversationId': conversation.id,
          });
        },
        child: Container(
          color: hasUnread
              ? const Color(0xFFF0FDF4) // Light green tint for unread
              : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // ── Avatar ──
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: peerAvatar.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: peerAvatar,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _buildAvatarFallback(peerName, 28),
                          )
                        : _buildAvatarFallback(peerName, 28),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00674F),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            conversation.unreadCount > 9
                                ? '9+'
                                : '${conversation.unreadCount}',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // ── Text ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            peerName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: hasUnread
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatMessageTime(conversation.lastMessageTime),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: hasUnread
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: hasUnread
                                ? const Color(0xFF00674F)
                                : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isLastSenderMe && conversation.lastMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.done_all_rounded,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            conversation.lastMessage.isNotEmpty
                                ? conversation.lastMessage
                                : 'Tap to start chatting',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: hasUnread
                                  ? Colors.black87
                                  : Colors.black45,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade100,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.7,
            color: Colors.black54),
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 52, color: Color(0xFF00674F)),
            ),
            const SizedBox(height: 20),
            Text(
              'No messages yet',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Conversations with hosts or guests will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.push('/connections'),
              icon: const Icon(Icons.people_alt_outlined, size: 18, color: Colors.white),
              label: Text(
                'Find People to Chat',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00674F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── NOTIFICATIONS TAB ─────────────────────────
  Widget _buildNotificationsTab() {
    final notificationsAsync = ref.watch(notificationsProvider);

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) return _buildEmptyNotifications();
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final alert = notifications[index];
            return _buildNotificationCard(alert);
          },
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      error: (err, stack) => _buildErrorState('notifications'),
    );
  }

  Widget _buildNotificationCard(NotificationAlert alert) {
    IconData icon = Icons.security_rounded;
    Color iconBgColor = const Color(0xFFFEE2E2);
    Color iconColor = const Color(0xFFEF4444);
    String? actionText;
    VoidCallback? onAction;

    if (alert.category == 'booking') {
      icon = Icons.vpn_key_rounded;
      iconBgColor = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF10B981);
      actionText = 'View Details';
      onAction = () {
        final isHostRequest = alert.title.contains('Request') ||
            alert.description.contains('requested');
        isHostRequest ? context.push('/bookings') : context.push('/trips');
      };
    } else if (alert.category == 'review') {
      icon = Icons.star_outline_rounded;
      iconBgColor = const Color(0xFFFFF7ED);
      iconColor = const Color(0xFFF59E0B);
      actionText = 'Write Review';
      onAction = () => _showReviewDialog('Your Recent Stay');
    } else if (alert.category == 'promo') {
      icon = Icons.local_offer_outlined;
      iconBgColor = const Color(0xFFEFF6FF);
      iconColor = const Color(0xFF3B82F6);
      actionText = 'Claim Coupon';
      onAction = () => _showPromoDialog('NESTYSWAT15');
    } else if (alert.category == 'message') {
      icon = Icons.chat_bubble_outline_rounded;
      iconBgColor = const Color(0xFFF0FDF4);
      iconColor = const Color(0xFF00674F);
      actionText = 'Open Chat';
      onAction = () => context.push('/inbox');
    }

    return GestureDetector(
      onTap: () {
        if (!alert.isRead) {
          ref.read(chatServiceProvider).markNotificationAsRead(alert.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: alert.isRead ? Colors.white : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: alert.isRead
                ? const Color(0xFFF1F5F9)
                : const Color(0xFFD1FAE5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration:
                  BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatRelativeTime(alert.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    alert.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  if (actionText != null && onAction != null) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (!alert.isRead) {
                          ref
                              .read(chatServiceProvider)
                              .markNotificationAsRead(alert.id);
                        }
                        onAction!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF222222),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        elevation: 0,
                        minimumSize: const Size(0, 32),
                      ),
                      child: Text(
                        actionText,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!alert.isRead) ...[
              const SizedBox(width: 10),
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                    color: Color(0xFF00674F), shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC), shape: BoxShape.circle),
              child: Icon(Icons.notifications_none_rounded,
                  size: 52, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text('All caught up!',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            Text(
              'Booking updates and alerts will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String type) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text('Could not load $type',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Check your internet and try again.',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
