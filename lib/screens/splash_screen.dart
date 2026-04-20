import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/family_palette.dart';
import '../theme/family_typography.dart';
import 'dashboard_screen.dart';

/// Boot splash shown while Glance warms up — reaches BVG and weather
/// services, then hands off to the dashboard.
class SplashScreen extends StatefulWidget {
  final Duration minDuration;
  const SplashScreen(
      {super.key, this.minDuration = const Duration(seconds: 2)});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    Timer(widget.minDuration, _go);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _go() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionDuration: const Duration(milliseconds: 420),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FamilyPalette.background,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProgressMark(progress: _progress),
                const SizedBox(height: 56),
                const _Wordmark(),
                const SizedBox(height: 56),
                Text(
                  'the moment, at a glance.',
                  style: FamilyType.splashTagline(),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: _Footer(),
          ),
        ],
      ),
    );
  }
}

class _ProgressMark extends StatelessWidget {
  final AnimationController progress;
  const _ProgressMark({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 60,
      child: AnimatedBuilder(
        animation: progress,
        builder: (_, __) {
          final t = Curves.easeInOut.transform(progress.value);
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 30,
                child: Container(height: 1, color: FamilyPalette.divider),
              ),
              Positioned(
                left: 200 * t - 8,
                top: 22,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: FamilyPalette.crimson,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: FamilyPalette.crimsonGlow,
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'glance',
          style: FamilyType.splashWordmark(color: FamilyPalette.textPrimary),
        ),
        Text(
          '.',
          style: FamilyType.splashWordmark(color: FamilyPalette.crimson),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LoadingRing(),
            const SizedBox(width: 10),
            Text(
              'reaching BVG · loading your morning',
              style: FamilyType.splashLoading(),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'V 0.2.0 · BERLIN · MMXXVI'.toUpperCase(),
          style: FamilyType.splashVersion(),
        ),
      ],
    );
  }
}

class _LoadingRing extends StatefulWidget {
  const _LoadingRing();

  @override
  State<_LoadingRing> createState() => _LoadingRingState();
}

class _LoadingRingState extends State<_LoadingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: RotationTransition(
        turns: _spin,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          value: 0.75,
          valueColor: AlwaysStoppedAnimation(FamilyPalette.crimson),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
