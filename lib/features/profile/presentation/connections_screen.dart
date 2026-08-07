import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../shared/widgets/nesty_bottom_nav.dart';
import '../../chat/providers/chat_provider.dart';
import '../../../core/theme/app_theme.dart';

// ─── Shimmer painter for skeleton loading ───────────────────────────────────

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter(this.progress) : super();

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment(-1.5 + progress * 3, 0),
      end: Alignment(-0.5 + progress * 3, 0),
      colors: const [
        Color(0xFFF0F0F0),
        Color(0xFFE0E0E0),
        Color(0xFFF0F0F0),
      ],
    );
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ─── Pulsing online dot widget ──────────────────────────────────────────────

class _PulsingOnlineDot extends StatefulWidget {
  const _PulsingOnlineDot();

  @override
  State<_PulsingOnlineDot> createState() => _PulsingOnlineDotState();
}

class _PulsingOnlineDotState extends State<_PulsingOnlineDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: const Color(0xFF00C47D),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C47D).withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer card skeleton ───────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _shimmerBox({double? w, double h = 14, double radius = 8}) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _ShimmerPainter(_ctrl.value),
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(w: 60, h: 60, radius: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(w: 160, h: 16),
                    const SizedBox(height: 8),
                    _shimmerBox(w: 110, h: 12),
                    const SizedBox(height: 8),
                    _shimmerBox(w: 80, h: 22, radius: 6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _shimmerBox(h: 38, radius: 10)),
              const SizedBox(width: 12),
              Expanded(child: _shimmerBox(h: 38, radius: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Animated connection card ────────────────────────────────────────────────

class _AnimatedConnectionCard extends StatefulWidget {
  final ConnectionItem item;
  final int index;
  final bool isLoadingChat;
  final VoidCallback onViewProfile;
  final VoidCallback onMessage;

  const _AnimatedConnectionCard({
    super.key,
    required this.item,
    required this.index,
    required this.isLoadingChat,
    required this.onViewProfile,
    required this.onMessage,
  });

  @override
  State<_AnimatedConnectionCard> createState() => _AnimatedConnectionCardState();
}

class _AnimatedConnectionCardState extends State<_AnimatedConnectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Stagger based on index
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: _ConnectionCard(
          item: widget.item,
          isLoadingChat: widget.isLoadingChat,
          onViewProfile: widget.onViewProfile,
          onMessage: widget.onMessage,
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatefulWidget {
  final ConnectionItem item;
  final bool isLoadingChat;
  final VoidCallback onViewProfile;
  final VoidCallback onMessage;

  const _ConnectionCard({
    required this.item,
    required this.isLoadingChat,
    required this.onViewProfile,
    required this.onMessage,
  });

  @override
  State<_ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<_ConnectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Widget _buildRoleBadge(String role) {
    Color bg, fg;
    IconData icon;

    if (role == 'Superhost') {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFC2410C);
      icon = Icons.workspace_premium_rounded;
    } else if (role == 'Host') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF047857);
      icon = Icons.home_work_outlined;
    } else {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF1D4ED8);
      icon = Icons.person_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            role,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) {
        _pressCtrl.forward();
        setState(() => _isHovered = true);
      },
      onTapUp: (_) {
        _pressCtrl.reverse();
        setState(() => _isHovered = false);
      },
      onTapCancel: () {
        _pressCtrl.reverse();
        setState(() => _isHovered = false);
      },
      child: AnimatedBuilder(
        animation: _pressAnim,
        builder: (_, child) => Transform.scale(
          scale: _pressAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primaryColor.withOpacity(0.25)
                  : const Color(0xFFF1F5F9),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppTheme.primaryColor.withOpacity(0.07)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _isHovered ? 20 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar with live presence ring ──
                    Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: item.isOnline
                                ? const LinearGradient(
                                    colors: [Color(0xFF00C47D), Color(0xFF00674F)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: item.isOnline ? null : Colors.transparent,
                          ),
                          child: CircleAvatar(
                            radius: 29,
                            backgroundImage: NetworkImage(item.imageUrl),
                            backgroundColor: Colors.grey.shade200,
                            onBackgroundImageError: (_, __) {},
                            child: item.imageUrl.isEmpty
                                ? Text(
                                    item.name.isNotEmpty
                                        ? item.name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        if (item.isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: const _PulsingOnlineDot(),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // ── Info column ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + verified
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF111827),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.isVerified) ...[
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF00674F),
                                  size: 15,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),

                          // Location + rating
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 11, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  item.location,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.reviewsCount > 0) ...[
                                const SizedBox(width: 10),
                                const Icon(Icons.star_rounded,
                                    size: 12, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 2),
                                Text(
                                  item.rating.toStringAsFixed(1),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  ' (${item.reviewsCount})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Role badge + online status + joined
                          Row(
                            children: [
                              _buildRoleBadge(item.role),
                              const SizedBox(width: 6),
                              if (item.isOnline)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C47D).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Online',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF00874D),
                                    ),
                                  ),
                                )
                              else if (item.lastActive != null && item.lastActive != 'Offline')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.lastActive!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                'Joined ${item.connectedSince}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100),
                const SizedBox(height: 12),

                // ── Action buttons ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onViewProfile,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: Colors.transparent,
                        ),
                        child: Text(
                          'View Profile',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF374151),
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.isLoadingChat ? null : widget.onMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00674F),
                          disabledBackgroundColor:
                              const Color(0xFF00674F).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        child: widget.isLoadingChat
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Message',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
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
}

// ─── Live connections count badge ────────────────────────────────────────────

class _LiveCountBadge extends StatefulWidget {
  final int count;
  const _LiveCountBadge({required this.count});

  @override
  State<_LiveCountBadge> createState() => _LiveCountBadgeState();
}

class _LiveCountBadgeState extends State<_LiveCountBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  int _displayed = 0;

  @override
  void initState() {
    super.initState();
    _displayed = widget.count;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(_LiveCountBadge old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) {
      _displayed = widget.count;
      _ctrl.forward(from: 0).then((_) => _ctrl.reverse());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00674F), Color(0xFF00875F)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00674F).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF7FFFCB),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$_displayed ${_displayed == 1 ? 'person' : 'people'}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main screen ─────────────────────────────────────────────────────────────

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _activeFilterIndex = 0;
  String _searchQuery = '';
  final Set<String> _loadingChats = {};

  late AnimationController _headerCtrl;
  late Animation<double> _headerOpacity;

  // For live online count indicator in header
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _headerOpacity = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);

    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 10;
      if (scrolled != _isScrolled) {
        setState(() => _isScrolled = scrolled);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  List<ConnectionItem> _getFilteredConnections(List<ConnectionItem> all) {
    return all.where((item) {
      if (_activeFilterIndex == 1 && !item.role.contains('Host')) return false;
      if (_activeFilterIndex == 2 && item.role.contains('Host')) return false;
      if (_searchQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !item.location.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _startChat(ConnectionItem item) async {
    HapticFeedback.lightImpact();
    setState(() => _loadingChats.add(item.id));
    try {
      final conversationId =
          await ref.read(chatServiceProvider).getOrCreateConversation(
                peerId: item.id,
                peerName: item.name,
                peerImageUrl: item.imageUrl,
              );
      if (!mounted) return;
      context.push('/chat', extra: {
        'peerId': item.id,
        'peerName': item.name,
        'peerImageUrl': item.imageUrl,
        'conversationId': conversationId,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not start chat. Please try again.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingChats.remove(item.id));
    }
  }

  void _showUserProfileSheet(BuildContext context, ConnectionItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileSheet(
        item: item,
        onMessage: () {
          Navigator.pop(ctx);
          _startChat(item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerScrolled) => [
          _buildSliverHeader(usersAsync),
        ],
        body: usersAsync.when(
          data: (allConnections) {
            final filtered = _getFilteredConnections(allConnections);
            return _buildList(filtered, allConnections);
          },
          loading: () => _buildSkeletonList(),
          error: (err, _) => _buildError(),
        ),
      ),
      bottomNavigationBar: const NestyBottomNav(currentIndex: 4),
    );
  }

  Widget _buildSliverHeader(AsyncValue<List<ConnectionItem>> usersAsync) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 168,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: _isScrolled ? 2 : 0,
      shadowColor: Colors.black.withOpacity(0.08),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.black, size: 20),
        onPressed: () => context.pop(),
      ),
      actions: [
        usersAsync.when(
          data: (list) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _LiveCountBadge(count: list.length)),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapsed = constraints.maxHeight < 120;
          return FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
            title: collapsed
                ? Text(
                    'Connections',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  )
                : null,
            background: FadeTransition(
              opacity: _headerOpacity,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connections',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    usersAsync.when(
                      data: (list) {
                        final onlineCount =
                            list.where((e) => e.isOnline).length;
                        return Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00C47D),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$onlineCount online now',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(108),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name or city...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.grey.shade500, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.black54, size: 18),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              }),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                    ),
                  ),
                ),
              ),
              // Filter pills
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    _buildFilterPill(0, 'All', Icons.people_outline_rounded),
                    const SizedBox(width: 8),
                    _buildFilterPill(1, 'Hosts', Icons.home_work_outlined),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                        2, 'Guests', Icons.person_outline_rounded),
                    const Spacer(),
                    usersAsync.when(
                      data: (list) {
                        final filtered = _getFilteredConnections(list);
                        return Text(
                          '${filtered.length} result${filtered.length != 1 ? 's' : ''}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.grey.shade200,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(int index, String label, IconData icon) {
    final bool isSelected = _activeFilterIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeFilterIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<ConnectionItem> filtered, List<ConnectionItem> all) {
    if (filtered.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        // Riverpod StreamProvider refreshes automatically — just wait a tick
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          return _AnimatedConnectionCard(
            key: ValueKey(item.id),
            item: item,
            index: index,
            isLoadingChat: _loadingChats.contains(item.id),
            onViewProfile: () => _showUserProfileSheet(context, item),
            onMessage: () => _startChat(item),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 4,
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 44, color: Colors.red.shade300),
            ),
            const SizedBox(height: 20),
            Text(
              'Connection failed',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final labels = ['people', 'hosts', 'guests'];
    final label = labels[_activeFilterIndex];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery"'
                  : 'No $label found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different name or city.'
                  : 'When users join Nesty, they will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile bottom sheet ────────────────────────────────────────────────────

class _ProfileSheet extends StatefulWidget {
  final ConnectionItem item;
  final VoidCallback onMessage;

  const _ProfileSheet({required this.item, required this.onMessage});

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildRoleBadge(String role) {
    Color bg, fg;
    IconData icon;
    if (role == 'Superhost') {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFC2410C);
      icon = Icons.workspace_premium_rounded;
    } else if (role == 'Host') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF047857);
      icon = Icons.home_work_outlined;
    } else {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF1D4ED8);
      icon = Icons.person_outline_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(role,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w900, color: fg)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_anim),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),

              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: item.isOnline
                            ? const Color(0xFF00C47D)
                            : Colors.grey.shade200,
                        width: 3,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(item.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (item.isOnline)
                    const Positioned(
                      bottom: 3,
                      right: 3,
                      child: _PulsingOnlineDot(),
                    ),
                  if (item.isVerified && !item.isOnline)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00674F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded,
                            color: Colors.white, size: 13),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  if (item.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF00674F), size: 18),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRoleBadge(item.role),
                  const SizedBox(width: 10),
                  if (item.isOnline)
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C47D),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active now',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00874D),
                          ),
                        ),
                      ],
                    )
                  else if (item.lastActive != null && item.lastActive != 'Offline')
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          item.lastActive!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(
                          item.location,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 22),

              // Stats row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEF2FF)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('${item.rating.toStringAsFixed(1)} ★', 'Rating'),
                    _buildVerticalDivider(),
                    _buildStat('${item.reviewsCount}', 'Reviews'),
                    _buildVerticalDivider(),
                    _buildStat(item.connectedSince, 'Joined'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Trust signals
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    _buildTrustRow(
                        Icons.mail_outline_rounded, 'Verified Email Address'),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: Colors.grey.shade100),
                    const SizedBox(height: 10),
                    _buildTrustRow(
                        Icons.phone_outlined, 'Verified Phone Number'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  if (item.role.contains('Host')) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/host/${item.id}');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFF00674F), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Listings',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF00674F),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: item.role.contains('Host') ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: widget.onMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00674F),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 15, color: Colors.white),
                          const SizedBox(width: 7),
                          Text(
                            'Send Message',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildTrustRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF00674F)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
            ),
          ),
        ),
        const Icon(Icons.check_circle_rounded,
            size: 16, color: Color(0xFF10B981)),
      ],
    );
  }
}
