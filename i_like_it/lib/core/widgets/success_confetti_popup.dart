import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as dart_math;
import 'dart:async';
import '../../theme/app_theme.dart';

class SuccessConfettiPopup {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    debugPrint('[CONFETTI] SuccessConfettiPopup.show called');
    final completer = Completer<void>();

    // Use the overlay from the root navigator to be safe across different contexts
    final overlay = Navigator.of(context, rootNavigator: true).overlay;

    if (overlay == null) {
      debugPrint('[CONFETTI] Error: No overlay found in context');
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        debugPrint('[CONFETTI] Building OverlayEntry');
        return _SuccessConfettiDialog(
          title: title,
          message: message,
          onComplete: () {
            debugPrint('[CONFETTI] Removing OverlayEntry');
            entry.remove();
            if (!completer.isCompleted) completer.complete();
          },
        );
      },
    );

    overlay.insert(entry);
    return completer.future;
  }
}

class _SuccessConfettiDialog extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onComplete;

  const _SuccessConfettiDialog({
    required this.title,
    required this.message,
    required this.onComplete,
  });

  @override
  State<_SuccessConfettiDialog> createState() => _SuccessConfettiDialogState();
}

class _SuccessConfettiDialogState extends State<_SuccessConfettiDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    _animationController.forward();
    _confettiController.play();

    // Auto-dismiss after celebration
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _animationController.reverse().then((_) => widget.onComplete());
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (dart_math.pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);
    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * dart_math.cos(step),
        halfWidth + externalRadius * dart_math.sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * dart_math.cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * dart_math.sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    const themeColors = [
      AppTheme.primaryColor,
      AppTheme.primaryDark,
      AppTheme.successColor,
      Color(0xFF26973C),
      Color(0xFFA5D6A7),
      Color(0xFF1B5E20),
    ];

    return Scaffold(
      backgroundColor: Colors.black45,
      body: Stack(
        children: [
          // Background dismiss trigger
          GestureDetector(
            onTap: () =>
                _animationController.reverse().then((_) => widget.onComplete()),
            child: Container(color: Colors.transparent),
          ),

          // The actual popup dialog
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.2),
                              AppTheme.successColor.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.primaryColor,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.title,
                        style: AppTheme.heading3.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.message,
                        style: AppTheme.bodyMedium.copyWith(
                          fontSize: 15,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Confetti Emitters (In front of everything)
          IgnorePointer(
            child: Stack(
              children: [
                Align(
                  alignment: const Alignment(-1.0, 0),
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: 0,
                    emissionFrequency: 0.1,
                    numberOfParticles: 30,
                    maxBlastForce: 60,
                    minBlastForce: 20,
                    gravity: 0.1,
                    particleDrag: 0.05,
                    colors: themeColors,
                    createParticlePath: drawStar,
                  ),
                ),
                Align(
                  alignment: const Alignment(1.0, 0),
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: dart_math.pi,
                    emissionFrequency: 0.1,
                    numberOfParticles: 30,
                    maxBlastForce: 60,
                    minBlastForce: 20,
                    gravity: 0.1,
                    particleDrag: 0.05,
                    colors: themeColors,
                    createParticlePath: drawStar,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.05,
                    numberOfParticles: 20,
                    gravity: 0.05,
                    colors: themeColors,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
