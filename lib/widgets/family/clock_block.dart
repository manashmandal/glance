import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/family_palette.dart';
import '../../theme/family_typography.dart';

/// The top-right clock: large time, subdued date underneath, and a
/// three-dot vertical menu affordance on the far right.
class ClockBlock extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const ClockBlock({super.key, this.onMenuTap});

  @override
  State<ClockBlock> createState() => _ClockBlockState();
}

class _ClockBlockState extends State<ClockBlock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat('h:mm a').format(_now);
    final dateText = DateFormat('EEEE, MMMM d').format(_now);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(timeText, style: FamilyType.clock()),
            const SizedBox(height: 4),
            Text(dateText, style: FamilyType.date()),
          ],
        ),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: _MenuDots(onTap: widget.onMenuTap),
        ),
      ],
    );
  }
}

class _MenuDots extends StatelessWidget {
  final VoidCallback? onTap;
  const _MenuDots({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: FamilyPalette.textPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
