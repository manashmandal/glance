import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/feature_flags.dart';
import '../../../data/layout_preset.dart';
import '../../../services/settings_service.dart';
import '../../../theme/family_palette.dart';
import '../../../theme/family_typography.dart';
import '../common/pane_header.dart';
import '../common/settings_chip_group.dart';
import '../common/settings_row.dart';
import '../common/settings_toggle.dart';

enum _EditMode { longPress, alwaysOn }

class LayoutPane extends StatefulWidget {
  const LayoutPane({super.key});

  @override
  State<LayoutPane> createState() => _LayoutPaneState();
}

class _LayoutPaneState extends State<LayoutPane> {
  LayoutPreset _preset = LayoutPreset.editorial;
  _EditMode _editMode = _EditMode.longPress;
  bool _snapToGrid = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preset = await SettingsService.readLayoutPreset();
    if (!mounted) return;
    setState(() {
      _preset = preset;
      _loaded = true;
    });
  }

  Future<void> _select(LayoutPreset preset) async {
    if (preset == _preset) return;
    setState(() => _preset = preset);
    await SettingsService.saveLayoutPreset(preset);
  }

  @override
  Widget build(BuildContext context) {
    final showEditMode = FeatureFlags.isEnabled(FeatureFlags.layoutEditMode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaneHeader(
          eyebrow: 'Layout',
          title: "How it's arranged",
          subtitle: 'Pick a starting point for your dashboard.',
          trailing: showEditMode
              ? const _EnterEditButton()
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 30),
        Text('Presets', style: FamilyType.sectionTitle()),
        const SizedBox(height: 6),
        Text(
          _loaded ? _subtitleFor(_preset) : 'Loading…',
          style: FamilyType.sectionDescription(),
        ),
        const SizedBox(height: 16),
        _PresetRow(selected: _preset, onChanged: _select),
        const SizedBox(height: 20),
        if (showEditMode) ...[
          SettingsRow(
            title: 'Edit mode behavior',
            description:
                'Long-press to enter, or always show drag handles.',
            control: SettingsChipGroup<_EditMode>(
              value: _editMode,
              onSelected: (v) => setState(() => _editMode = v),
              items: const [
                SettingsChip(label: 'Long-press', value: _EditMode.longPress),
                SettingsChip(label: 'Always on', value: _EditMode.alwaysOn),
              ],
            ),
          ),
          SettingsRow(
            title: 'Snap to grid',
            description:
                'Widgets align to a 12-column rhythm. Off for free placement.',
            control: SettingsToggle(
              value: _snapToGrid,
              onChanged: (v) => setState(() => _snapToGrid = v),
            ),
          ),
        ],
        SettingsRow(
          title: 'Reset to Editorial',
          description: 'The original magazine-style layout.',
          control: _ResetButton(onTap: () => _select(LayoutPreset.editorial)),
        ),
      ],
    );
  }

  String _subtitleFor(LayoutPreset preset) => switch (preset) {
        LayoutPreset.editorial =>
          'Editorial — hero countdown, route rail, upcoming, and weather together.',
        LayoutPreset.heroOnly =>
          'Hero only — just the countdown and destination. Ideal for a glance.',
        LayoutPreset.split =>
          'Split — equal weight between upcoming trains and weather.',
        LayoutPreset.dense =>
          'Dense — tighter spacing, more information per square inch.',
      };
}

class _EnterEditButton extends StatelessWidget {
  const _EnterEditButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: FamilyPalette.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FamilyPalette.crimson, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter edit mode',
            style: GoogleFonts.interTight(
              color: FamilyPalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.chevron_right,
            color: FamilyPalette.crimson,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  final LayoutPreset selected;
  final ValueChanged<LayoutPreset> onChanged;

  const _PresetRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final presets = <_PresetCard>[
      const _PresetCard(
        value: LayoutPreset.editorial,
        label: 'Editorial',
        footer: 'Default',
        kind: _PresetKind.editorial,
      ),
      const _PresetCard(
        value: LayoutPreset.heroOnly,
        label: 'Hero only',
        footer: 'Glanceable',
        kind: _PresetKind.hero,
      ),
      const _PresetCard(
        value: LayoutPreset.split,
        label: 'Split',
        footer: 'Trains · Weather',
        kind: _PresetKind.split,
      ),
      const _PresetCard(
        value: LayoutPreset.dense,
        label: 'Dense',
        footer: 'Power user',
        kind: _PresetKind.dense,
      ),
    ];
    return Row(
      children: [
        for (final preset in presets) ...[
          Expanded(
            child: _PresetTile(
              preset: preset,
              selected: preset.value == selected,
              onTap: () => onChanged(preset.value),
            ),
          ),
          if (preset != presets.last) const SizedBox(width: 14),
        ],
      ],
    );
  }
}

enum _PresetKind { editorial, hero, split, dense }

class _PresetCard {
  final LayoutPreset value;
  final String label;
  final String footer;
  final _PresetKind kind;
  const _PresetCard({
    required this.value,
    required this.label,
    required this.footer,
    required this.kind,
  });
}

class _PresetTile extends StatelessWidget {
  final _PresetCard preset;
  final bool selected;
  final VoidCallback onTap;

  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FamilyPalette.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? FamilyPalette.crimson : FamilyPalette.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 110,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FamilyPalette.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _PresetArt(kind: preset.kind),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    preset.label,
                    style: FamilyType.sectionTitle().copyWith(fontSize: 15),
                  ),
                  Text(
                    preset.footer,
                    style: GoogleFonts.geistMono(
                      color: FamilyPalette.textTertiary,
                      fontSize: 11,
                      letterSpacing: 0.04 * 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetArt extends StatelessWidget {
  final _PresetKind kind;
  const _PresetArt({required this.kind});

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case _PresetKind.editorial:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '8',
                  style: GoogleFonts.geistMono(
                    color: FamilyPalette.crimson,
                    fontSize: 38,
                    fontWeight: FontWeight.w500,
                    height: 0.85,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'min',
                  style: GoogleFonts.interTight(
                    color: FamilyPalette.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(child: _bar()),
                const SizedBox(width: 6),
                Expanded(child: _bar()),
              ],
            ),
          ],
        );
      case _PresetKind.hero:
        return Center(
          child: Text(
            '8',
            style: GoogleFonts.geistMono(
              color: FamilyPalette.textPrimary,
              fontSize: 58,
              fontWeight: FontWeight.w500,
              height: 0.85,
            ),
          ),
        );
      case _PresetKind.split:
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: FamilyPalette.panel,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: FamilyPalette.panel,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        );
      case _PresetKind.dense:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            5,
            (_) => Container(
              height: 8,
              decoration: BoxDecoration(
                color: FamilyPalette.panel,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
    }
  }

  Widget _bar() {
    return Container(
      height: 22,
      decoration: BoxDecoration(
        color: FamilyPalette.panel,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ResetButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FamilyPalette.divider, width: 1),
          ),
          child: Text(
            'Reset',
            style: GoogleFonts.interTight(
              color: FamilyPalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
