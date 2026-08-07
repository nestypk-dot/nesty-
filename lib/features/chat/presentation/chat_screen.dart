import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';

// ──────────────────────────────────────────────
// EMOJI PICKER (lightweight inline)
// ──────────────────────────────────────────────
class _EmojiPanel extends StatelessWidget {
  final void Function(String emoji) onEmoji;
  const _EmojiPanel({super.key, required this.onEmoji});

  static const _emojis = [
    '😀','😂','😍','🥰','😎','😢','😡','👍','👎','❤️',
    '🔥','✅','🙏','👏','😮','😭','🤣','😅','💯','🎉',
    '😏','🤔','😴','🤩','😬','🥳','😤','🤗','😇','🫡',
    '💪','🫶','👀','✌️','🤙','💀','🙈','🌟','💬','📷',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: _emojis.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onEmoji(_emojis[i]),
          child: Center(
            child: Text(_emojis[i], style: const TextStyle(fontSize: 26)),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// CHAT SCREEN
// ──────────────────────────────────────────────
class ChatScreen extends ConsumerStatefulWidget {
  final String peerId;
  final String peerName;
  final String peerImageUrl;
  final String? conversationId;

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.peerImageUrl,
    this.conversationId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  String? _conversationId;
  bool _isLoadingConversation = false;
  bool _isSending = false;
  bool _showEmoji = false;

  // Reply-to state
  ChatMessage? _replyingTo;

  // Typing debounce
  Timer? _typingTimer;
  bool _isCurrentlyTyping = false;

  // Swipe animation
  late AnimationController _swipeAnimController;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _swipeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    if (_conversationId == null && widget.peerId.isNotEmpty) {
      _resolveConversation();
    } else if (_conversationId != null) {
      _markAsRead();
    }

    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_conversationId != null) {
      ref.read(chatServiceProvider).setTyping(_conversationId!, false);
    }
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _swipeAnimController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_conversationId == null) return;
    final text = _messageController.text;

    if (text.isNotEmpty && !_isCurrentlyTyping) {
      _isCurrentlyTyping = true;
      ref.read(chatServiceProvider).setTyping(_conversationId!, true);
    }

    _typingTimer?.cancel();
    if (text.isEmpty) {
      _isCurrentlyTyping = false;
      ref.read(chatServiceProvider).setTyping(_conversationId!, false);
    } else {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _isCurrentlyTyping) {
          _isCurrentlyTyping = false;
          ref.read(chatServiceProvider).setTyping(_conversationId!, false);
        }
      });
    }
    setState(() {});
  }

  Future<void> _markAsRead() async {
    if (_conversationId == null) return;
    await ref.read(chatServiceProvider).markConversationAsRead(_conversationId!);
  }

  Future<void> _resolveConversation() async {
    setState(() => _isLoadingConversation = true);
    try {
      final id = await ref.read(chatServiceProvider).getOrCreateConversation(
            peerId: widget.peerId,
            peerName: widget.peerName,
            peerImageUrl: widget.peerImageUrl,
          );
      if (!mounted) return;
      setState(() {
        _conversationId = id;
        _isLoadingConversation = false;
      });
      await _markAsRead();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingConversation = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error starting chat: $e',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _conversationId == null || _isSending) return;

    final reply = _replyingTo;
    setState(() {
      _isSending = true;
      _replyingTo = null;
    });
    _messageController.clear();

    try {
      await ref.read(chatServiceProvider).sendMessage(
            _conversationId!,
            text,
            replyToId: reply?.id,
            replyToText: reply?.text,
            replyToSender: reply?.senderName,
          );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: const Color(0xFFEF4444),
      ));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendPhotoMessage(ImageSource source) async {
    if (_conversationId == null || _isSending) return;
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1024,
      );
      if (image == null) return;

      setState(() => _isSending = true);

      final imageUrl = await ref.read(chatServiceProvider).uploadChatImage(
            _conversationId!,
            image.path,
          );

      await ref.read(chatServiceProvider).sendMessage(
            _conversationId!,
            '📷 Photo',
            type: 'image',
            imageUrl: imageUrl,
          );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to send image: $e',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startReply(ChatMessage message) {
    setState(() => _replyingTo = message);
    _inputFocusNode.requestFocus();
  }

  void _cancelReply() => setState(() => _replyingTo = null);

  void _toggleEmoji() {
    if (_showEmoji) {
      _inputFocusNode.requestFocus();
    } else {
      _inputFocusNode.unfocus();
    }
    setState(() => _showEmoji = !_showEmoji);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── BUILD ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoadingConversation) {
      return _buildLoadingScaffold();
    }
    if (_conversationId == null) {
      return _buildErrorScaffold();
    }

    final messagesAsync = ref.watch(chatMessagesProvider(_conversationId!));
    final peerTypingAsync = ref.watch(peerTypingProvider(
      (conversationId: _conversationId!, peerUid: widget.peerId),
    ));
    final isPeerTyping = peerTypingAsync.asData?.value ?? false;

    messagesAsync.whenData((_) => _markAsRead());

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp-style warm background
      appBar: _buildAppBar(isPeerTyping),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) return _buildEmptyChat();
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final prev = index > 0 ? messages[index - 1] : null;
                    final next = index < messages.length - 1 ? messages[index + 1] : null;
                    final showDate = prev == null || !_isSameDay(prev.time, msg.time);
                    final isFirstInGroup = prev == null || prev.senderId != msg.senderId;
                    final isLastInGroup = next == null || next.senderId != msg.senderId;
                    return Column(
                      children: [
                        if (showDate) _buildDateSeparator(msg.time),
                        _buildSwipeableMessage(
                          msg,
                          isFirstInGroup: isFirstInGroup,
                          isLastInGroup: isLastInGroup,
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor)),
              error: (e, _) => Center(
                child: Text('Error loading messages',
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
              ),
            ),
          ),

          // Typing indicator bubble
          if (isPeerTyping)
            _buildTypingIndicator(),

          // Input area
          _buildInputArea(),

          // Emoji panel (slides up from bottom)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showEmoji
                ? _EmojiPanel(
                    key: const ValueKey('emoji_panel'),
                    onEmoji: (e) {
                      _messageController.text += e;
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _messageController.text.length),
                      );
                    },
                  )
                : const SizedBox.shrink(key: ValueKey('no_emoji')),
          ),
        ],
      ),
    );
  }

  // ── APP BAR ─────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isPeerTyping) {
    return AppBar(
      backgroundColor: const Color(0xFF075E54), // WhatsApp dark green
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
        onPressed: () => context.canPop() ? context.pop() : context.go('/inbox'),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {},
        child: Row(
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'peer_avatar_${widget.peerId}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: widget.peerImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.peerImageUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _peerAvatarFallback(20),
                          )
                        : _peerAvatarFallback(20),
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF075E54), width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peerName,
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isPeerTyping
                        ? Text(
                            'typing...',
                            key: const ValueKey('typing'),
                            style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF25D366),
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          )
                        : Text(
                            'online',
                            key: const ValueKey('online'),
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 24),
          onPressed: () async {
            try {
              final callId = await ref.read(chatServiceProvider).startCall(
                receiverId: widget.peerId,
                receiverName: widget.peerName,
                receiverAvatar: widget.peerImageUrl,
                type: 'video',
              );
              if (context.mounted) {
                context.push('/call', extra: {'callId': callId, 'isCaller': true});
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not start video call: $e')),
                );
              }
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.call_rounded, color: Colors.white, size: 22),
          onPressed: () async {
            try {
              final callId = await ref.read(chatServiceProvider).startCall(
                receiverId: widget.peerId,
                receiverName: widget.peerName,
                receiverAvatar: widget.peerImageUrl,
                type: 'audio',
              );
              if (context.mounted) {
                context.push('/call', extra: {'callId': callId, 'isCaller': true});
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not start voice call: $e')),
                );
              }
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 22),
          onPressed: () => _showChatOptions(),
        ),
      ],
    );
  }

  // ── DATE SEPARATOR ──────────────────────────
  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF54656F)),
          ),
        ),
      ),
    );
  }

  // ── SWIPEABLE MESSAGE WRAPPER ───────────────
  Widget _buildSwipeableMessage(
    ChatMessage message, {
    required bool isFirstInGroup,
    required bool isLastInGroup,
  }) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMe = message.senderId == currentUid;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Swipe right to reply
        if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
          HapticFeedback.lightImpact();
          _startReply(message);
        }
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showMessageOptions(message, isMe);
      },
      child: _buildMessageBubble(
        message,
        isMe: isMe,
        isFirstInGroup: isFirstInGroup,
        isLastInGroup: isLastInGroup,
      ),
    );
  }

  // ── MESSAGE BUBBLE ──────────────────────────
  Widget _buildMessageBubble(
    ChatMessage message, {
    required bool isMe,
    required bool isFirstInGroup,
    required bool isLastInGroup,
  }) {
    final bubbleColor = isMe
        ? const Color(0xFFDCF8C6) // WhatsApp sent green
        : Colors.white;
    final textColor = Colors.black87;

    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isMe ? 18 : (isFirstInGroup ? 4 : 18)),
      topRight: Radius.circular(isMe ? (isFirstInGroup ? 4 : 18) : 18),
      bottomLeft: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 60 : 0,
        right: isMe ? 0 : 60,
        bottom: isLastInGroup ? 6 : 2,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Peer avatar on left (only show for last in group)
          if (!isMe) ...[
            SizedBox(
              width: 36,
              child: isLastInGroup
                  ? _buildMiniAvatar(message.senderAvatar, message.senderName)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 4),
          ],

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name (only for non-me first-in-group messages)
                if (!isMe && isFirstInGroup)
                  Padding(
                    padding: const EdgeInsets.only(left: 14, bottom: 2),
                    child: Text(
                      message.senderName,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _nameColor(message.senderName)),
                    ),
                  ),

                // Bubble container
                Container(
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 3,
                          offset: const Offset(0, 1)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reply preview
                      if (message.replyToText != null && message.replyToText!.isNotEmpty)
                        _buildReplyPreview(message, isMe),

                      // Image message
                      if (message.type == 'image' && message.imageUrl != null)
                        _buildImageContent(message, borderRadius)
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                          child: Text(
                            message.text,
                            style: GoogleFonts.plusJakartaSans(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.4),
                          ),
                        ),

                      // Time + read receipt
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat.jm().format(message.time),
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.black38,
                                  fontWeight: FontWeight.w600),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.isRead
                                    ? Icons.done_all_rounded
                                    : Icons.done_rounded,
                                size: 15,
                                color: message.isRead
                                    ? const Color(0xFF34B7F1) // WhatsApp blue ticks
                                    : Colors.black38,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // My avatar on right (only show for last in group)
          if (isMe) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 28,
              child: isLastInGroup
                  ? _buildMyAvatar()
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyPreview(ChatMessage message, bool isMe) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.6)
            : const Color(0xFFECE5DD).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isMe ? const Color(0xFF075E54) : const Color(0xFF25D366),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToSender ?? 'Unknown',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF075E54)),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyToText ?? '',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(ChatMessage message, BorderRadius borderRadius) {
    return GestureDetector(
      onTap: () => context.push('/media-viewer', extra: message.imageUrl),
      child: ClipRRect(
        borderRadius: borderRadius.subtract(
          const BorderRadius.all(Radius.circular(0)),
        ),
        child: CachedNetworkImage(
          imageUrl: message.imageUrl!,
          fit: BoxFit.cover,
          width: 220,
          height: 180,
          placeholder: (_, __) => Container(
            height: 180,
            width: 220,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
                color: AppTheme.primaryColor, strokeWidth: 2),
          ),
          errorWidget: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildMiniAvatar(String avatarUrl, String name) {
    if (avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _avatarInitial(name, 14),
        ),
      );
    }
    return _avatarInitial(name, 14);
  }

  Widget _buildMyAvatar() {
    final user = FirebaseAuth.instance.currentUser;
    final url = user?.photoURL ?? '';
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
            imageUrl: url,
            width: 28,
            height: 28,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _avatarInitial('Me', 14)),
      );
    }
    return _avatarInitial(user?.displayName ?? 'Me', 14);
  }

  Widget _avatarInitial(String name, double size) {
    return CircleAvatar(
      radius: size,
      backgroundColor: const Color(0xFF128C7E),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.7),
      ),
    );
  }

  Widget _peerAvatarFallback(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade300,
      child: Text(
        widget.peerName.isNotEmpty ? widget.peerName[0].toUpperCase() : 'U',
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
            fontSize: radius * 0.75),
      ),
    );
  }

  // ── TYPING INDICATOR ────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 60, 6),
      child: Row(
        children: [
          _buildMiniAvatar(widget.peerImageUrl, widget.peerName),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 4,
                    offset: const Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(150),
                const SizedBox(width: 4),
                _buildTypingDot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, val, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(Colors.grey.shade300, Colors.grey.shade600, val),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  // ── INPUT AREA ──────────────────────────────
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, 6, 8, MediaQuery.of(context).padding.bottom + 6),
      color: const Color(0xFFECE5DD),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply bar
          if (_replyingTo != null)
            _buildActiveReplyBar(),

          // Input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Message input box
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 130),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Emoji toggle
                      GestureDetector(
                        onTap: _toggleEmoji,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10, bottom: 10),
                          child: Icon(
                            _showEmoji
                                ? Icons.keyboard_rounded
                                : Icons.emoji_emotions_outlined,
                            color: Colors.grey.shade500,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _inputFocusNode,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.w500),
                          onTap: () {
                            if (_showEmoji) setState(() => _showEmoji = false);
                          },
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 5,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Message',
                            border: InputBorder.none,
                            hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                color: Colors.black38,
                                fontWeight: FontWeight.w400),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 11, horizontal: 4),
                          ),
                        ),
                      ),
                      // Attachment
                      GestureDetector(
                        onTap: () => _sendPhotoMessage(ImageSource.gallery),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 9),
                          child: Icon(Icons.attach_file_rounded,
                              color: Colors.grey.shade500, size: 22),
                        ),
                      ),
                      // Camera
                      GestureDetector(
                        onTap: () => _sendPhotoMessage(ImageSource.camera),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10, bottom: 9),
                          child: Icon(Icons.camera_alt_outlined,
                              color: Colors.grey.shade500, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send / Mic button
              AnimatedBuilder(
                animation: _messageController,
                builder: (context, _) {
                  final hasText = _messageController.text.trim().isNotEmpty;
                  return GestureDetector(
                    onTap: hasText ? _sendMessage : () => _showComingSoon('Voice message'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366), // WhatsApp send green
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Icon(
                              hasText
                                  ? Icons.send_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveReplyBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyingTo!.senderName,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF075E54)),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingTo!.text,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _cancelReply,
            child: const Icon(Icons.close_rounded,
                size: 18, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  // ── EMPTY STATE ──────────────────────────────
  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Color(0xFFDCF8C6), shape: BoxShape.circle),
            child: const Icon(Icons.waving_hand_rounded,
                size: 44, color: Color(0xFF075E54)),
          ),
          const SizedBox(height: 16),
          Text(
            'Say Hello! 👋',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Messages you send here are end-to-end encrypted.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── LOADING / ERROR STATES ─────────────────
  Widget _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 22),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/inbox'),
        ),
      ),
      body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor)),
    );
  }

  Widget _buildErrorScaffold() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          elevation: 0, backgroundColor: const Color(0xFF075E54)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Unable to start conversation.',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _resolveConversation,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text('Try Again',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPER: Name colour by hash ────────────
  Color _nameColor(String name) {
    final colors = [
      const Color(0xFF075E54),
      const Color(0xFF128C7E),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF3F51B5),
      const Color(0xFFFF5722),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  // ── CONTEXT MENU ────────────────────────────
  void _showMessageOptions(ChatMessage message, bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: Color(0xFF075E54)),
              title: Text('Reply',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                _startReply(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colors.black54),
              title: Text('Copy',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Copied',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700)),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 1),
                ));
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.info_outline_rounded,
                    color: Colors.black54),
                title: Text('Info',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700)),
                subtitle: Text(
                  message.isRead ? 'Read ✓✓' : 'Delivered ✓',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: Colors.grey),
                ),
                onTap: () => Navigator.pop(context),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.search_rounded, color: Colors.black54),
              title: Text('Search in chat',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Search');
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper_rounded,
                  color: Colors.black54),
              title: Text('Wallpaper',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Wallpaper');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: Colors.red),
              title: Text('Block',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature coming soon!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }
}
