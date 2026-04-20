import 'package:flutter/material.dart';
import '../../../theme/family_palette.dart';
import '../../../theme/family_typography.dart';

/// Left-side navigation list used on every settings pane.
class SettingsNavList extends StatelessWidget {
  final List<SettingsNavEntry> entries;
  final String activeId;
  final ValueChanged<String> onSelected;

  const SettingsNavList({
    super.key,
    required this.entries,
    required this.activeId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries)
          _NavItem(
            entry: entry,
            active: entry.id == activeId,
            onTap: () => onSelected(entry.id),
          ),
      ],
    );
  }
}

class SettingsNavEntry {
  final String id;
  final String title;
  final String subtitle;
  const SettingsNavEntry({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

class _NavItem extends StatelessWidget {
  final SettingsNavEntry entry;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.entry,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: active ? FamilyPalette.panel : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 4,
                child: active
                    ? Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: FamilyPalette.crimson,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title,
                        style: FamilyType.navTitle(active: active)),
                    const SizedBox(height: 4),
                    Text(entry.subtitle, style: FamilyType.navSubtitle()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
