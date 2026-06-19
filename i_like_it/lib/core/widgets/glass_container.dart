import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? borderColor;
  final double blur;
  final bool enableBlur; // New parameter
  final List<BoxShadow>? boxShadow; // New parameter for shadow

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.blur = 10,
    this.enableBlur = true,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(16);

    // Dynamic defaults based on theme
    final defaultColor = isDark
        ? const Color(0xFF0F172A).withOpacity(0.6) // Slate 900 @ 60%
        : const Color(0xFFFFFFFF).withOpacity(
            0.65,
          ); // White @ 65% (More transparent for glass effect)

    final defaultBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(
            0.08,
          ); // Contrast increased for light mode (0.05 -> 0.08)

    // Default shadow only for light mode if not provided
    final defaultShadow =
        boxShadow ??
        (isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]);

    // If blur is disabled, return a simple container
    if (!enableBlur) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: borderColor ?? defaultBorder, width: 1),
          color: color ?? defaultColor,
          boxShadow: defaultShadow,
        ),
        child: child,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: borderColor ?? defaultBorder, width: 1),
        color: color ?? defaultColor,
        boxShadow: defaultShadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
