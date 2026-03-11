import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Global Gradient Background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              gradient: RadialGradient(
                center: const Alignment(0, -1.2), // Top Center Glow
                radius: 1.5,
                colors: isDark
                    ? [
                        const Color(0xFF3B82F6).withOpacity(0.15), // Blue Glow (Dark)
                        Colors.transparent,
                      ]
                    : [
                        const Color(0xFF6366F1).withOpacity(0.10), // Indigo Glow (Light)
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        ),
        
        // Main Content
        Positioned.fill(child: child),
      ],
    );
  }
}
