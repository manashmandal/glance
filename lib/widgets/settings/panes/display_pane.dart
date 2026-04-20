import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../main.dart';
import '../../../theme/family_palette.dart';
import '../../../theme/family_typography.dart';
import '../common/pane_header.dart';
import '../common/settings_chip_group.dart';
import '../common/settings_row.dart';
import '../common/settings_toggle.dart';
import '../common/tiny_pill.dart';

enum _ThemeChoice { light, dark, auto }

enum _Orientation { auto, landscape, portrait }

class DisplayPane extends StatefulWidget {
  const DisplayPane({super.key});

  @override
  State<DisplayPane> createState() => _DisplayPaneState();
}

class _DisplayPaneState extends State<DisplayPane> {
  double _typeScale = 1.15;
  bool _dimAtNight = true;
  bool _alwaysOn = true;
  _Orientation _orientation = _Orientation.landscape;

  _ThemeChoice _currentTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _ThemeChoice.dark : _ThemeChoice.light;
  }

  void _pickTheme(_ThemeChoice choice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wantsDark = choice == _ThemeChoice.dark ||
        (choice == _ThemeChoice.auto && DateTime.now().hour >= 18);
    if (wantsDark != isDark) {
      GlanceApp.of(context)?.toggleTheme();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _currentTheme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaneHeader(
          eyebrow: 'Display',
          title: 'How it looks',
          subtitle: 'Soft on the eyes. Easy on the OLED.',
          trailing: _MountedBadge(),
        ),
        const SizedBox(height: 36),
        _ThemeSection(selected: theme, onChanged: _pickTheme),
        const SizedBox(height: 32),
        _TypeScaleRow(
          value: _typeScale,
          onChanged: (v) => setState(() => _typeScale = v),
        ),
        SettingsRow(
          title: 'Dim at night',
          trailingBadge: const TinyPill(label: 'OLED'),
          description: 'Reduces brightness 22:00 — 06:00 to protect the panel.',
          control: SettingsToggle(
            value: _dimAtNight,
            onChanged: (v) => setState(() => _dimAtNight = v),
          ),
        ),
        SettingsRow(
          title: 'Always-on display',
          description: 'Keeps the next departure visible even when the screen sleeps.',
          control: SettingsToggle(
            value: _alwaysOn,
            onChanged: (v) => setState(() => _alwaysOn = v),
          ),
        ),
        SettingsRow(
          title: 'Orientation',
          description: 'Lock the canvas to one direction or follow the device.',
          control: SettingsChipGroup<_Orientation>(
            value: _orientation,
            onSelected: (v) => setState(() => _orientation = v),
            items: const [
              SettingsChip(label: 'Auto', value: _Orientation.auto),
              SettingsChip(label: 'Landscape', value: _Orientation.landscape),
              SettingsChip(label: 'Portrait', value: _Orientation.portrait),
            ],
          ),
        ),
      ],
    );
  }
}

class _MountedBadge extends StatelessWidget {
  const _MountedBadge();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'MOUNTED IN',
          style: GoogleFonts.inter(
            color: FamilyPalette.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2 * 10,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: FamilyPalette.sage,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'Kitchen · Always-on',
              style: FamilyType.sectionDescription().copyWith(
                color: FamilyPalette.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThemeSection extends StatelessWidget {
  final _ThemeChoice selected;
  final ValueChanged<_ThemeChoice> onChanged;

  const _ThemeSection({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme', style: FamilyType.sectionTitle()),
        const SizedBox(height: 6),
        Text(
          'Glance can switch automatically with sunset.',
          style: FamilyType.sectionDescription(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ThemeCard(
                title: 'Light',
                footer: 'Newsprint',
                value: _ThemeChoice.light,
                selected: selected == _ThemeChoice.light,
                onTap: () => onChanged(_ThemeChoice.light),
                background: const Color(0xFFF5ECE2),
                digitColor: const Color(0xFFD4525E),
                accentColor: const Color(0xFF1B1720),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ThemeCard(
                title: 'Dark',
                footer: 'Twilight · OLED',
                value: _ThemeChoice.dark,
                selected: selected == _ThemeChoice.dark,
                onTap: () => onChanged(_ThemeChoice.dark),
                background: const Color(0xFF14141F),
                digitColor: FamilyPalette.crimson,
                accentColor: FamilyPalette.textPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ThemeCard(
                title: 'Auto',
                footer: 'Sunrise → Sunset',
                value: _ThemeChoice.auto,
                selected: selected == _ThemeChoice.auto,
                onTap: () => onChanged(_ThemeChoice.auto),
                background: const Color(0xFFE7E1D7),
                digitColor: FamilyPalette.textPrimary,
                accentColor: FamilyPalette.textPrimary,
                split: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String title;
  final String footer;
  final _ThemeChoice value;
  final bool selected;
  final VoidCallback onTap;
  final Color background;
  final Color digitColor;
  final Color accentColor;
  final bool split;

  const _ThemeCard({
    required this.title,
    required this.footer,
    required this.value,
    required this.selected,
    required this.onTap,
    required this.background,
    required this.digitColor,
    required this.accentColor,
    this.split = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FamilyPalette.panel.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? FamilyPalette.crimson : FamilyPalette.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: split
                    ? _splitPreview(digitColor, accentColor)
                    : _standardPreview(digitColor, accentColor),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: FamilyType.sectionTitle().copyWith(fontSize: 18),
                  ),
                  Text(
                    footer,
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

  Widget _standardPreview(Color digit, Color accent) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '8',
                style: GoogleFonts.geistMono(
                  color: digit,
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.04 * 40,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'min',
                style: GoogleFonts.interTight(
                  color: accent.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Flughafen BER',
            style: GoogleFonts.interTight(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _splitPreview(Color digit, Color accent) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              Expanded(
                child: Container(color: const Color(0xFFF5ECE2)),
              ),
              Expanded(
                child: Container(color: FamilyPalette.panel),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '8',
                style: GoogleFonts.geistMono(
                  color: accent,
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.04 * 40,
                  height: 1.0,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'BER',
                  style: GoogleFonts.interTight(
                    color: FamilyPalette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeScaleRow extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _TypeScaleRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      showDivider: false,
      title: 'Type scale',
      description: 'Bigger for wall-mount viewing, smaller for handheld.',
      control: SizedBox(
        width: 360,
        child: Row(
          children: [
            Text(
              'A',
              style: GoogleFonts.interTight(
                color: FamilyPalette.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2.5,
                  activeTrackColor: FamilyPalette.crimson,
                  inactiveTrackColor: FamilyPalette.divider,
                  thumbColor: FamilyPalette.textPrimary,
                  overlayColor: FamilyPalette.crimson.withValues(alpha: 0.12),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  min: 0.8,
                  max: 1.4,
                  value: value,
                  onChanged: onChanged,
                ),
              ),
            ),
            Text(
              'A',
              style: GoogleFonts.interTight(
                color: FamilyPalette.textSecondary,
                fontSize: 26,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '${value.toStringAsFixed(2)}×',
              style: GoogleFonts.geistMono(
                color: FamilyPalette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
