import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:math' as math;
import '../../../core/providers/auth_provider.dart';

class SwitchingGuestScreen extends ConsumerStatefulWidget {
  const SwitchingGuestScreen({super.key});

  @override
  ConsumerState<SwitchingGuestScreen> createState() => _SwitchingGuestScreenState();
}

class _SwitchingGuestScreenState extends ConsumerState<SwitchingGuestScreen> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  int _currentStage = 1;
  Timer? _stageTimer;
  Timer? _switchTimer;

  @override
  void initState() {
    super.initState();
    
    // Rotation animation
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Bobbing float animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -12.0, end: 12.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Transition from Stage 1 to Stage 2 after 2.5 seconds
    _stageTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _currentStage = 2;
        });
      }
    });

    // Transition back to guest mode after 5.0 seconds (2.5 seconds per stage)
    _switchTimer = Timer(const Duration(milliseconds: 5000), () {
      if (mounted) {
        // Toggle the state to Guest
        ref.read(authProvider.notifier).setRole(AppRole.guest);
        
        // Go back home (which is now in Guest Mode!)
        context.go('/home');
        
        // Show premium feedback welcome back snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: Color(0xFF00674F), size: 22),
                const SizedBox(width: 12),
                Text(
                  'Switched back to Guest mode!',
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
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _floatController.dispose();
    _stageTimer?.cancel();
    _switchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floating, breathing, and rotating 3D island/house graphic
            AnimatedBuilder(
              animation: Listenable.merge([_spinController, _floatController]),
              builder: (context, child) {
                final floatOffset = _floatAnimation.value;
                final scale = 0.96 + (0.08 * _floatController.value);
                
                return Transform.translate(
                  offset: Offset(0, floatOffset),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Transform.rotate(
                          angle: _spinController.value * 2 * math.pi,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 800),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Image.network(
                              _currentStage == 1
                                  ? 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?q=80&w=400'
                                  : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=400',
                              key: ValueKey<int>(_currentStage),
                              fit: BoxFit.cover,
                              width: 200,
                              height: 200,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                _currentStage == 1 ? 'Switching to guest mode' : 'Preparing your guest feed',
                key: ValueKey<int>(_currentStage),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF000000),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 40,
              height: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const LinearProgressIndicator(
                  color: Colors.black, // Dark loader for guest transition
                  backgroundColor: Color(0xFFF3F4F6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
