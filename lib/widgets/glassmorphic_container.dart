import 'package:flutter/material.dart';
import 'dart:ui';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadows;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.backgroundColor = const Color(0xFF252931),
    this.borderColor = Colors.white,
    this.borderWidth = 1,
    this.boxShadows,
    this.padding,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? backgroundColor.withValues(alpha: 0.6) : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.1),
          width: borderWidth,
        ),
        boxShadow: boxShadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: gradient != null
                ? BoxDecoration(color: backgroundColor.withValues(alpha: 0.5))
                : null,
            child: child,
          ),
        ),
      ),
    );
  }
}
