import 'package:flutter/material.dart';
import '../../../theme/family_palette.dart';

/// A 3×3 rounded square used to separate inline metadata
/// (e.g. between "Anna" and "Mitte" in the route hint).
class TinyDotSeparator extends StatelessWidget {
  final Color color;

  const TinyDotSeparator({super.key, this.color = FamilyPalette.dividerDim});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
