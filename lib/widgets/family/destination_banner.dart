import 'package:flutter/material.dart';
import '../../theme/family_palette.dart';
import '../../theme/family_typography.dart';

/// The huge destination headline that caps off the hero (e.g.
/// "Flughafen BER"). Has a divider rule above it.
class DestinationBanner extends StatelessWidget {
  final String destination;

  const DestinationBanner({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: FamilyPalette.divider, width: 1),
        ),
      ),
      child: Text(destination, style: FamilyType.destination()),
    );
  }
}
