import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:math' as math;
import '../../../core/providers/auth_provider.dart';

class SwitchingHostingScreen extends ConsumerStatefulWidget {
  const SwitchingHostingScreen({super.key});

  @override
  ConsumerState<SwitchingHostingScreen> createState() => _SwitchingHostingScreenState();
}

class _SwitchingHostingScreenState extends ConsumerState<SwitchingHostingScreen> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _floatController;
  late AnimationController _radialController;
  late AnimationController _shimmerController;

  late Animation<double> _floatAnimation;
  late Animation<double> _radialProgress;
  late Animation<double> _shimmerProgress;

  int _currentStage = 1;
  Timer? _stageTimer;
  Timer? _switchTimer;

  @override
  void initState() {
    super.initState();

    // Majestic slow spin
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Bobbing/breathing float
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // Radial progress from 0% to 100% in 5 seconds
    _radialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _radialProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _radialController, curve: Curves.linear),
    );
    _radialController.forward();

    // Shimmer sweep reflection repeating every 2.5 seconds
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _shimmerProgress = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Transition stage after 2.5s
    _stageTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _currentStage = 2;
        });
      }
    });

    // Auto-transition to Host Dashboard after 5.0 seconds (2.5 seconds per stage)
    _switchTimer = Timer(const Duration(milliseconds: 5000), () {
      if (mounted) {
        // Toggle the state to Host
        ref.read(authProvider.notifier).setRole(AppRole.host);

        // Go back home (which is now in Host Mode!)
        context.go('/home');

        // Show premium welcome snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.yellowAccent, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Welcome to your Host Dashboard!',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00674F), // Premium Emerald Green
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
    _radialController.dispose();
    _shimmerController.dispose();
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
            // Floating 3D and orbital graphic stack
            SizedBox(
              width: 320,
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Pulsing Radar Ring 3 (Outer)
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      final scale = 1.0 + (0.05 * _floatController.value);
                      final opacity = 0.015 + (0.01 * (1.0 - _floatController.value));
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00674F).withOpacity(opacity),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Background Pulsing Radar Ring 2
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      final scale = 1.0 + (0.08 * (1.0 - _floatController.value));
                      final opacity = 0.02 + (0.01 * _floatController.value);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00674F).withOpacity(opacity),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Background Pulsing Radar Ring 1 (Inner)
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      final scale = 1.0 + (0.04 * _floatController.value);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00674F).withOpacity(0.04),
                              width: 2.0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Radial Loader Outer Arc
                  AnimatedBuilder(
                    animation: _radialProgress,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(212, 212),
                        painter: RadialProgressPainter(
                          progress: _radialProgress.value,
                          color: const Color(0xFF00674F), // Premium Emerald Green loader
                        ),
                      );
                    },
                  ),

                  // 3D Perspective Holographic Tilt Villa Container
                  AnimatedBuilder(
                    animation: Listenable.merge([_spinController, _floatController]),
                    builder: (context, child) {
                      final floatOffset = _floatAnimation.value;
                      final scale = 0.96 + (0.06 * _floatController.value);

                      // 3D perspective wobbly path
                      final angle = _spinController.value * 2 * math.pi;
                      final tiltX = math.sin(angle) * 0.12;
                      final tiltY = math.cos(angle) * 0.12;

                      return Transform.translate(
                        offset: Offset(0, floatOffset),
                        child: Transform.scale(
                          scale: scale,
                          child: Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0015) // perspective projection
                              ..rotateX(tiltX)
                              ..rotateY(tiltY),
                            alignment: Alignment.center,
                            child: Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00674F).withOpacity(0.12),
                                    blurRadius: 25,
                                    offset: const Offset(0, 12),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Stack(
                                  children: [
                                    // Slow majestic image spin inside the tilted plate
                                    Positioned.fill(
                                      child: Transform.rotate(
                                        angle: _spinController.value * 0.15 * math.pi, // very slow rotate
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 800),
                                          switchInCurve: Curves.easeInOut,
                                          switchOutCurve: Curves.easeInOut,
                                          transitionBuilder: (Widget child, Animation<double> animation) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: ScaleTransition(
                                                scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: Image.network(
                                            _currentStage == 1
                                                ? 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=400'
                                                : 'https://images.unsplash.com/photo-1618773928121-c32242e63f39?q=80&w=400',
                                            key: ValueKey<int>(_currentStage),
                                            fit: BoxFit.cover,
                                            width: 190,
                                            height: 190,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Elegant Diagonal Shimmer Sweep
                                    Positioned.fill(
                                      child: AnimatedBuilder(
                                        animation: _shimmerProgress,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(_shimmerProgress.value * 190, _shimmerProgress.value * 190),
                                            child: Transform.rotate(
                                              angle: math.pi / 4,
                                              child: Container(
                                                width: 190,
                                                height: 380,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white.withOpacity(0.0),
                                                      Colors.white.withOpacity(0.35),
                                                      Colors.white.withOpacity(0.0),
                                                    ],
                                                    stops: const [0.1, 0.5, 0.9],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Switching text
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
                _currentStage == 1 ? 'Switching to hosting' : 'Preparing your host dashboard',
                key: ValueKey<int>(_currentStage),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF000000), // Solid Black text
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Circular progress text directly below
            AnimatedBuilder(
              animation: _radialProgress,
              builder: (context, child) {
                final percent = (_radialProgress.value * 100).toInt();
                return Text(
                  '$percent%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF00674F), // Emerald Green percent indicator
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RadialProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  RadialProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius, paint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at 12 o'clock
      progress * 2 * math.pi,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RadialProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
