import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import '../../../core/providers/auth_provider.dart';

class IncomingCallListener extends ConsumerStatefulWidget {
  final Widget child;

  const IncomingCallListener({super.key, required this.child});

  @override
  ConsumerState<IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends ConsumerState<IncomingCallListener> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Mark user online on startup if authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(isAuthenticatedProvider)) {
        ref.read(presenceServiceProvider).setOnline();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(presenceServiceProvider).setOffline();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!ref.read(isAuthenticatedProvider)) return;

    if (state == AppLifecycleState.resumed) {
      ref.read(presenceServiceProvider).setOnline();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive ||
               state == AppLifecycleState.detached) {
      ref.read(presenceServiceProvider).setOffline();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to authentication changes
    ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
      if (next) {
        ref.read(presenceServiceProvider).setOnline();
      } else {
        ref.read(presenceServiceProvider).setOffline();
      }
    });

    ref.listen<AsyncValue<CallSession?>>(incomingCallProvider, (previous, next) {
      final call = next.asData?.value;
      if (call != null && call.status == 'ringing') {
        _showIncomingCallDialog(context, ref, call);
      }
    });

    return widget.child;
  }

  void _showIncomingCallDialog(BuildContext context, WidgetRef ref, CallSession call) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        final isVideo = call.type == 'video';
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                CircleAvatar(
                  radius: 60,
                  backgroundImage: call.callerAvatar.isNotEmpty ? NetworkImage(call.callerAvatar) : null,
                  backgroundColor: Colors.white12,
                  child: call.callerAvatar.isEmpty
                      ? Text(call.callerName[0].toUpperCase(), style: const TextStyle(fontSize: 36, color: Colors.white))
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  call.callerName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isVideo ? 'Incoming Video Call / Video Call aa rahi hai...' : 'Incoming Voice Call / Call aa rahi hai...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          Navigator.pop(ctx);
                          try {
                            await ref.read(chatServiceProvider).updateCallStatus(call.id, 'declined');
                          } catch (_) {}
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          Navigator.pop(ctx);
                          try {
                            await ref.read(chatServiceProvider).updateCallStatus(call.id, 'accepted');
                            if (context.mounted) {
                              context.push('/call', extra: {'callId': call.id, 'isCaller': false});
                            }
                          } catch (_) {}
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
