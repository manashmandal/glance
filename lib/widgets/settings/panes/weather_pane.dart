import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/family_palette.dart';
import '../../../theme/family_typography.dart';
import '../common/pane_header.dart';
import '../common/settings_chip_group.dart';
import '../common/settings_row.dart';
import '../common/settings_toggle.dart';
import '../common/tiny_pill.dart';

enum _TempUnit { c, f }

enum _WindUnit { kmh, mph }

enum _Horizon { h6, h12, h24, h48 }

enum _AiVoice { friendly, editorial, concise, poetic }

class WeatherPane extends StatefulWidget {
  const WeatherPane({super.key});

  @override
  State<WeatherPane> createState() => _WeatherPaneState();
}

class _WeatherPaneState extends State<WeatherPane> {
  _TempUnit _temp = _TempUnit.c;
  _WindUnit _wind = _WindUnit.kmh;
  _Horizon _horizon = _Horizon.h12;
  _AiVoice _voice = _AiVoice.editorial;
  bool _aiOn = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaneHeader(
          eyebrow: 'Weather',
          title: "What the sky's doing",
          subtitle: 'A nudge before you walk out the door.',
          trailing: _NowInBerlin(),
        ),
        const SizedBox(height: 36),
        SettingsRow(
          showDivider: false,
          title: 'Location',
          description: 'Follows your station unless overridden.',
          control: _LocationChip(),
        ),
        SettingsRow(
          title: 'Units',
          description: 'Temperature, wind, precipitation.',
          control: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SettingsChipGroup<_TempUnit>(
                value: _temp,
                onSelected: (v) => setState(() => _temp = v),
                items: const [
                  SettingsChip(label: '°C', value: _TempUnit.c),
                  SettingsChip(label: '°F', value: _TempUnit.f),
                ],
              ),
              const SizedBox(width: 14),
              SettingsChipGroup<_WindUnit>(
                value: _wind,
                onSelected: (v) => setState(() => _wind = v),
                items: const [
                  SettingsChip(label: 'km/h', value: _WindUnit.kmh),
                  SettingsChip(label: 'mph', value: _WindUnit.mph),
                ],
              ),
            ],
          ),
        ),
        SettingsRow(
          title: 'AI suggestions',
          trailingBadge: const TinyPill(label: 'BETA'),
          description: 'A short editorial note alongside the forecast.',
          control: SettingsToggle(
            value: _aiOn,
            onChanged: (v) => setState(() => _aiOn = v),
          ),
        ),
        const SizedBox(height: 6),
        _AiVoicePicker(
          voice: _voice,
          onChanged: (v) => setState(() => _voice = v),
        ),
        SettingsRow(
          title: 'Forecast horizon',
          description: 'How far the sparkline reaches into the future.',
          control: SettingsChipGroup<_Horizon>(
            value: _horizon,
            onSelected: (v) => setState(() => _horizon = v),
            items: const [
              SettingsChip(label: '6h', value: _Horizon.h6),
              SettingsChip(label: '12h', value: _Horizon.h12),
              SettingsChip(label: '24h', value: _Horizon.h24),
              SettingsChip(label: '48h', value: _Horizon.h48),
            ],
          ),
        ),
        SettingsRow(
          title: 'Data provider',
          description: 'Open-Meteo is free and ad-free. Recommended.',
          control: _ProviderChip(),
        ),
      ],
    );
  }
}

class _NowInBerlin extends StatelessWidget {
  const _NowInBerlin();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'NOW IN BERLIN',
          style: GoogleFonts.inter(
            color: FamilyPalette.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2 * 10,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '4°',
              style: GoogleFonts.geistMono(
                color: FamilyPalette.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'partly cloudy',
                style: FamilyType.sectionDescription(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocationChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      decoration: BoxDecoration(
        color: FamilyPalette.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FamilyPalette.divider, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TIED TO STATION',
                style: GoogleFonts.inter(
                  color: FamilyPalette.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.18 * 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Berlin · Mitte',
                style: GoogleFonts.interTight(
                  color: FamilyPalette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          const Icon(
            Icons.chevron_right,
            color: FamilyPalette.textSecondary,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _ProviderChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      decoration: BoxDecoration(
        color: FamilyPalette.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FamilyPalette.divider, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Open-Meteo',
            style: GoogleFonts.interTight(
              color: FamilyPalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.chevron_right,
            color: FamilyPalette.textSecondary,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _AiVoicePicker extends StatelessWidget {
  final _AiVoice voice;
  final ValueChanged<_AiVoice> onChanged;

  const _AiVoicePicker({required this.voice, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cards = <_VoiceCard>[
      const _VoiceCard(
        value: _AiVoice.friendly,
        label: 'Friendly',
        sample: '"Bring an umbrella!"',
      ),
      const _VoiceCard(
        value: _AiVoice.editorial,
        label: 'Editorial',
        sample: '"Light jacket weather."',
      ),
      const _VoiceCard(
        value: _AiVoice.concise,
        label: 'Concise',
        sample: 'jacket · umbrella\n18:00',
      ),
      const _VoiceCard(
        value: _AiVoice.poetic,
        label: 'Poetic',
        sample: '"Soft rain by dusk."',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          for (final card in cards) ...[
            Expanded(
              child: _AiVoiceCard(
                voice: card,
                selected: card.value == voice,
                onTap: () => onChanged(card.value),
              ),
            ),
            if (card != cards.last) const SizedBox(width: 14),
          ],
        ],
      ),
    );
  }
}

class _VoiceCard {
  final _AiVoice value;
  final String label;
  final String sample;
  const _VoiceCard({
    required this.value,
    required this.label,
    required this.sample,
  });
}

class _AiVoiceCard extends StatelessWidget {
  final _VoiceCard voice;
  final bool selected;
  final VoidCallback onTap;

  const _AiVoiceCard({
    required this.voice,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isConcise = voice.value == _AiVoice.concise;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
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
              Text(
                voice.label,
                style: FamilyType.sectionTitle().copyWith(fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                voice.sample,
                style: isConcise
                    ? GoogleFonts.geistMono(
                        color: FamilyPalette.textSecondary,
                        fontSize: 12,
                        height: 16 / 12,
                      )
                    : GoogleFonts.instrumentSerif(
                        color: FamilyPalette.textSecondary,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 18 / 14,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
