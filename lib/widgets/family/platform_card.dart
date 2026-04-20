import 'package:flutter/material.dart';
import '../../theme/family_palette.dart';
import '../../theme/family_typography.dart';
import 'common/station_dot.dart';

/// Rounded card on the hero's right side showing the line code ("RE8
/// Regional") at top and the platform number below.
class PlatformCard extends StatelessWidget {
  final String lineCode;
  final String category;
  final String platform;

  const PlatformCard({
    super.key,
    required this.lineCode,
    required this.category,
    required this.platform,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 184,
      height: 140,
      decoration: BoxDecoration(
        color: FamilyPalette.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FamilyPalette.divider, width: 1),
      ),
      child: Column(
        children: [
          _Header(lineCode: lineCode, category: category),
          Expanded(child: _PlatformRow(platform: platform)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String lineCode;
  final String category;
  const _Header({required this.lineCode, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: FamilyPalette.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          const StationDot(color: FamilyPalette.crimson, size: 7),
          const SizedBox(width: 8),
          Text(lineCode, style: FamilyType.lineCodeLarge()),
          const Spacer(),
          Text(category.toUpperCase(), style: FamilyType.lineCategory()),
        ],
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  final String platform;
  const _PlatformRow({required this.platform});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('PLATFORM', style: FamilyType.metaCaps()),
          const Spacer(),
          Text(platform, style: FamilyType.platformNumber()),
        ],
      ),
    );
  }
}
