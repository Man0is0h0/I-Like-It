import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class CustomSplashScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;

  const CustomSplashScreen({
    super.key,
    required this.onInitializationComplete,
  });

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Remove native splash screen as soon as the first Flutter frame is painted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    // Display the custom Flutter splash screen for 2.5 seconds to showcase the branding
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onInitializationComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen background image
          Positioned.fill(
            child: Image.asset(
              'assets/flutter_splash.png',
              fit: BoxFit.cover,
            ),
          ),
          // Animated progress indicator and complete text overlay (transparent background)
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50), // Branding Green
                    strokeWidth: 3.0,
                  ),
                ),
                const SizedBox(height: 24),
                const AnimatedLoadingText(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedLoadingText extends StatefulWidget {
  const AnimatedLoadingText({super.key});

  @override
  State<AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<AnimatedLoadingText> {
  int _dotCount = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;
    final paddingDots = ' ' * (3 - _dotCount);

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          fontFamily: 'Inter',
          color: Colors.white,
        ),
        children: [
          const TextSpan(text: 'Loading '),
          const TextSpan(
            text: 'your',
            style: TextStyle(
              color: Color(0xFF4CAF50), // Branding Green
              fontWeight: FontWeight.w500,
            ),
          ),
          const TextSpan(text: ' favorites'),
          // Use a TextSpan with constant character width (dots + padding spaces)
          // to prevent text shift/jumping during dot count updates
          TextSpan(
            text: '$dots$paddingDots',
            style: const TextStyle(fontFamily: 'Courier'), // Monospace font for exact padding alignment
          ),
        ],
      ),
    );
  }
}
