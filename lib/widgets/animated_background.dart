import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Blob positions (normalized 0.0 to 1.0)
  // We'll animate these using the controller
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final bg = Theme.of(context).scaffoldBackgroundColor; // This should be transparent in theme ideally, but we use a base color here layer 0

    // Base background color (Solid)
    // If scaffold is transparent in theme, we need a solid base here.
    // We use the "original" theme background colors manually.
    final baseColor = isDark ? AppTheme.darkBackground : AppTheme.softBeige;

    return Stack(
      children: [
        // Layer 0: Solid Base
        Container(color: baseColor),

        // Layer 1: Animated Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            // Blob 1: Moving Top-Left to Center
            final blob1X = -0.5 + (0.5 * sin(t * 2 * pi));
            final blob1Y = -0.5 + (0.3 * cos(t * 2 * pi));

            // Blob 2: Moving Bottom-Right to Center
            final blob2X = 1.5 - (0.5 * cos(t * 2 * pi)); 
            final blob2Y = 1.5 - (0.5 * sin(t * 2 * pi));

            // Blob 3: Pulsing in Middle
            final blob3Scale = 1.0 + (0.5 * sin(t * pi));

            return Stack(
              children: [
                // Blob 1 (Primary Color - Top Left)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.2 + (100 * sin(t * pi)),
                  left: MediaQuery.of(context).size.width * 0.2 + (50 * cos(t * pi)),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.15),
                          blurRadius: 100,
                          spreadRadius: 50,
                        ),
                      ],
                    ),
                  ),
                ),
                 // Blob 2 (Secondary Color - Bottom Right)
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.1 - (100 * sin(t * pi)),
                  right: -50 + (50 * cos(t * pi)),
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: secondary.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                          color: secondary.withOpacity(0.15),
                          blurRadius: 120,
                          spreadRadius: 40,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Layer 2: Blur for "Mesh" effect
        // NOTE: BackdropFilter applies to everything BEHIND it.
        // Putting it here creates the mesh effect on blobs.
        /* BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(color: Colors.transparent),
        ), */ 
        // Logic: BackdropFilter is expensive. Just using high blurRadius in BoxShadow is often enough and faster.
        // We will skip explicit BackdropFilter global layer for performance unless requested.

        // Layer 3: Content
        widget.child,
      ],
    );
  }
}
