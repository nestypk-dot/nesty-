import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/chat_provider.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String callId;
  final bool isCaller;

  const CallScreen({
    super.key,
    required this.callId,
    required this.isCaller,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _callTimer;
  int _secondsElapsed = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCameraOn = true;
  bool _isFrontCamera = true;
  bool _hasCallEndedHandled = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_callTimer != null) return;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _endCall() async {
    if (_hasCallEndedHandled) return;
    _hasCallEndedHandled = true;
    _callTimer?.cancel();
    try {
      await ref.read(chatServiceProvider).updateCallStatus(widget.callId, 'ended');
    } catch (_) {}
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final callAsync = ref.watch(singleCallProvider(widget.callId));

    return callAsync.when(
      data: (call) {
        if (call == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
          return const Scaffold(backgroundColor: Colors.black);
        }

        if ((call.status == 'declined' || call.status == 'ended') && !_hasCallEndedHandled) {
          _hasCallEndedHandled = true;
          _callTimer?.cancel();
          String message = call.status == 'declined' ? 'Call Declined' : 'Call Ended';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(milliseconds: 1500),
              ),
            );
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) context.pop();
            });
          });
        }

        final isAccepted = call.status == 'accepted';
        if (isAccepted) {
          _startTimer();
        }

        final isVideo = call.type == 'video';
        final peerName = widget.isCaller ? call.receiverName : call.callerName;
        final peerAvatar = widget.isCaller ? call.receiverAvatar : call.callerAvatar;

        return Scaffold(
          backgroundColor: isVideo ? const Color(0xFF0F172A) : const Color(0xFF075E54),
          body: Stack(
            children: [
              if (isVideo) ...[
                if (_isCameraOn)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          isAccepted 
                              ? Opacity(
                                  opacity: 0.5,
                                  child: CachedNetworkImage(
                                    imageUrl: peerAvatar,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Center(child: Icon(Icons.person, size: 80, color: Colors.white24)),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.videocam_off_rounded, size: 80, color: Colors.white24),
                                ),
                        ],
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(Icons.videocam_off_rounded, size: 85, color: Colors.white38),
                      ),
                    ),
                  ),

                if (_isCameraOn)
                  Positioned(
                    top: 50,
                    right: 20,
                    child: Container(
                      width: 110,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          color: Colors.grey.shade900,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                peerAvatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return const Center(child: Icon(Icons.camera_alt_outlined, color: Colors.white54));
                                },
                              ),
                              Positioned(
                                bottom: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'You',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],

              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    if (!isAccepted)
                      Center(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              padding: EdgeInsets.all(24 * _pulseController.value),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1 * (1.0 - _pulseController.value)),
                              ),
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white30, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundImage: peerAvatar.isNotEmpty ? NetworkImage(peerAvatar) : null,
                              backgroundColor: Colors.white12,
                              child: peerAvatar.isEmpty
                                  ? Text(peerName[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: Colors.white))
                                  : null,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      if (isVideo) const SizedBox(height: 20),
                      if (!isVideo) ...[
                        const SizedBox(height: 20),
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: peerAvatar.isNotEmpty ? NetworkImage(peerAvatar) : null,
                          backgroundColor: Colors.white12,
                          child: peerAvatar.isEmpty
                              ? Text(peerName[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: Colors.white))
                              : null,
                        ),
                      ],
                    ],

                    const SizedBox(height: 24),
                    Text(
                      peerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAccepted
                          ? _formatDuration(_secondsElapsed)
                          : widget.isCaller
                              ? 'Ringing / گھنٹی ja rahi hai...'
                              : 'Incoming Call / Call aa rahi hai...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isAccepted ? const Color(0xFF25D366) : Colors.white70,
                      ),
                    ),

                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isVideo && isAccepted) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildCircleBtn(
                                  icon: _isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                                  isActive: _isCameraOn,
                                  onTap: () => setState(() => _isCameraOn = !_isCameraOn),
                                  label: 'Camera',
                                ),
                                _buildCircleBtn(
                                  icon: Icons.flip_camera_ios_rounded,
                                  isActive: true,
                                  onTap: () => setState(() => _isFrontCamera = !_isFrontCamera),
                                  label: 'Flip',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildCircleBtn(
                                icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                                isActive: !_isMuted,
                                onTap: () => setState(() => _isMuted = !_isMuted),
                                label: 'Mute',
                              ),

                              GestureDetector(
                                onTap: _endCall,
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                                    ],
                                  ),
                                  child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                                ),
                              ),

                              _buildCircleBtn(
                                icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                                isActive: _isSpeakerOn,
                                onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                                label: 'Speaker',
                              ),
                            ],
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
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF25D366)),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleBtn({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive ? Colors.white24 : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.black87,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
