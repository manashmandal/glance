import 'package:flutter/material.dart';
import '../../../theme/family_palette.dart';
import '../../../theme/family_typography.dart';

/// A segmented control of chips — the active one fills crimson.
class SettingsChipGroup<T> extends StatelessWidget {
  final List<SettingsChip<T>> items;
  final T value;
  final ValueChanged<T> onSelected;

  const SettingsChipGroup({
    super.key,
    required this.items,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: FamilyPalette.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FamilyPalette.divider, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            _ChipButton(
              label: item.label,
              active: item.value == value,
              onTap: () => onSelected(item.value),
            ),
        ],
      ),
    );
  }
}

class SettingsChip<T> {
  final String label;
  final T value;
  const SettingsChip({required this.label, required this.value});
}

class _ChipButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ChipButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? FamilyPalette.crimson : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: FamilyType.chipText(active: active)),
      ),
    );
  }
}
