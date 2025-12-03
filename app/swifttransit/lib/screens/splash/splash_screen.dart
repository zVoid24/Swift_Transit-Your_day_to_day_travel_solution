import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Native splash screen using an asset logo (assets/stlogo.png).
/// Shows a rotating + pulsing logo while `initApp()` runs in background.
/// Text "SWIFT TRANSIT" is shown statically below the logo and is responsive
/// to different screen sizes.
class SplashScreen extends StatefulWidget {
  /// Minimum time to show splash even if init finishes fast.
  final Duration minDisplayDuration;

  /// Optional callback that performs initialization work and returns when done.
  /// If null, a simulated delay is used (see code below).
  final Future<void> Function()? initCallback;

  const SplashScreen({
    super.key,
    this.minDisplayDuration = const Duration(seconds: 20),
    this.initCallback,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Smooth continuous rotation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6), // rotation speed
    )..repeat();

    // Subtle pulse (scale up/down)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start initialization sequence
    _startInitialization();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Replace this with your real initialization (network check, auth, DB, etc)
  Future<void> initApp() async {
    if (widget.initCallback != null) {
      await widget.initCallback!.call();
      return;
    }

    // --- SIMULATION FOR TESTING ---
    // Simulate some async work like network check / service init.
    await Future.delayed(const Duration(seconds: 3));
    // --------------------------------
  }

  Future<void> _startInitialization() async {
    final started = DateTime.now();

    try {
      await initApp();
    } catch (e) {
      // If initialization fails, you may choose to:
      // - Retry
      // - Show an error dialog
      // - Navigate to an offline screen
      // For now we just print and continue to the next step.
      debugPrint('Splash init error: $e');
    }

    // Ensure minimum display time
    final elapsed = DateTime.now().difference(started);
    if (elapsed < widget.minDisplayDuration) {
      final remaining = widget.minDisplayDuration - elapsed;
      await Future.delayed(remaining);
    }

    // Navigate away (comment out while testing if desired)
    if (!mounted) return;
    // For testing: comment the next line and uncomment the Timer below if you want delayed navigation.
    //Navigator.pushReplacementNamed(context, '/login');

    // Alternative test approach: if you prefer explicitly navigate after a delay,
    // comment the line above and uncomment these lines:
    //
    Timer(const Duration(seconds: 60), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;

    final double computedFontSize = (width * 0.055).clamp(18.0, 32.0);
    final double subTextSize = math.max(12.0, computedFontSize * 0.45);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// TOP SPACER
            const SizedBox(height: 50),

            /// LOGO stays centered
            Expanded(
              flex: 3,
              child: Center(
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: RotationTransition(
                    turns: _rotationController,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage('assets/stlogo.png'),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// TEXT stays near the bottom dynamically
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'SWIFT TRANSIT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: computedFontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.0,
                      color: const Color(0xFF258BA1),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your day-to-day travel solution',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: subTextSize,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 40), // spacing from bottom
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
