import 'package:flutter/material.dart';
import '../../data/family_placeholders.dart';
import '../../theme/family_palette.dart';
import '../../theme/family_typography.dart';

/// The "partner up next" calendar callout: a tinted slab with a bright
/// accent rail on the left, a person label and time range on top, and
/// the event title on the bottom.
class UpNextBlock extends StatelessWidget {
  final PartnerEvent event;

  const UpNextBlock({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 266,
      height: 66,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: FamilyPalette.crimsonTint,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          children: [
            Container(width: 3, color: event.accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          event.person.toUpperCase(),
                          style: FamilyType.eyebrow(color: event.accent),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '· ${event.label}'.toUpperCase(),
                          style:
                              FamilyType.eyebrow(color: FamilyPalette.textMuted),
                        ),
                        const Spacer(),
                        Text(event.timeRange, style: FamilyType.eventTimeRange()),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.title,
                      style: FamilyType.eventTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
