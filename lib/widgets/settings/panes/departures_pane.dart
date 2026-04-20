import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/station.dart';
import '../../../models/transport_type.dart';
import '../../../services/settings_service.dart';
import '../../../theme/family_palette.dart';
import '../../../theme/family_typography.dart';
import '../common/pane_header.dart';
import '../common/settings_chip_group.dart';
import '../common/settings_row.dart';
import '../common/settings_toggle.dart';
import '../common/tiny_pill.dart';

enum _RefreshCadence { s30, m1, m2, m5 }

class DeparturesPane extends StatefulWidget {
  const DeparturesPane({super.key});

  @override
  State<DeparturesPane> createState() => _DeparturesPaneState();
}

class _DeparturesPaneState extends State<DeparturesPane> {
  Station _station = Station.defaultStation;
  Station? _destination;
  TransportType _transport = TransportType.regional;
  int _skipMinutes = 5;
  int _durationMinutes = 60;
  bool _weatherSuggestions = true;
  _RefreshCadence _cadence = _RefreshCadence.m1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stationId = await SettingsService.readDefaultStationId();
    final destinationId = await SettingsService.readDestinationStationId();
    final transport = await SettingsService.readDefaultTransportType();
    final skip = await SettingsService.readSkipMinutes();
    final duration = await SettingsService.readDurationMinutes();
    final suggestions = await SettingsService.readShowWeatherActions();
    if (!mounted) return;
    setState(() {
      if (stationId != null) {
        _station = Station.popularStations.firstWhere(
          (s) => s.id == stationId,
          orElse: () => Station.defaultStation,
        );
      }
      _destination = destinationId == null
          ? null
          : Station.popularStations.firstWhere(
              (s) => s.id == destinationId,
              orElse: () => Station(id: destinationId, name: destinationId),
            );
      _transport = transport;
      _skipMinutes = skip;
      _durationMinutes = duration;
      _weatherSuggestions = suggestions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaneHeader(
          eyebrow: 'Departures',
          title: "What you'll see",
          subtitle: 'Tune the trains and times that anchor your dashboard.',
          trailing: const _LivePreviewTag(),
        ),
        const SizedBox(height: 36),
        SettingsRow(
          showDivider: false,
          title: 'Default station',
          description: 'Where Glance starts each morning. Tap to switch.',
          control: _StationChip(station: _station, onTap: _pickStation),
        ),
        SettingsRow(
          title: 'Destination',
          description:
              'Where you usually head. Powers the route rail on the dashboard.',
          control: _DestinationChip(
            station: _destination,
            onTap: _pickDestination,
          ),
        ),
        SettingsRow(
          title: 'Transport mode',
          description: 'Which BVG departures show up first in your list.',
          control: SettingsChipGroup<TransportType>(
            value: _transport,
            onSelected: (v) async {
              setState(() => _transport = v);
              await SettingsService.saveDefaultTransportType(v);
            },
            items: const [
              SettingsChip(label: 'Regional', value: TransportType.regional),
              SettingsChip(label: 'S-Bahn', value: TransportType.sBahn),
              SettingsChip(label: 'Bus', value: TransportType.bus),
            ],
          ),
        ),
        SettingsRow(
          title: 'Time window',
          description:
              'How long it takes you to walk to the platform, and how far ahead to look.',
          control: _TimeWindowControls(
            skip: _skipMinutes,
            duration: _durationMinutes,
            onSkip: (v) async {
              setState(() => _skipMinutes = v);
              await SettingsService.saveSkipMinutes(v);
            },
            onDuration: (v) async {
              setState(() => _durationMinutes = v);
              await SettingsService.saveDurationMinutes(v);
            },
          ),
        ),
        SettingsRow(
          title: 'Weather suggestions',
          trailingBadge: const TinyPill(label: 'AI'),
          description: '"Light jacket weather. Bring an umbrella after 18:00."',
          control: SettingsToggle(
            value: _weatherSuggestions,
            onChanged: (v) async {
              setState(() => _weatherSuggestions = v);
              await SettingsService.saveShowWeatherActions(v);
            },
          ),
        ),
        SettingsRow(
          title: 'Refresh cadence',
          description: 'How often Glance reaches out to BVG. Faster uses more battery.',
          control: SettingsChipGroup<_RefreshCadence>(
            value: _cadence,
            onSelected: (v) => setState(() => _cadence = v),
            items: const [
              SettingsChip(label: '30s', value: _RefreshCadence.s30),
              SettingsChip(label: '1 min', value: _RefreshCadence.m1),
              SettingsChip(label: '2 min', value: _RefreshCadence.m2),
              SettingsChip(label: '5 min', value: _RefreshCadence.m5),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _LivePreview(),
      ],
    );
  }

  Future<void> _pickStation() async {
    final picked = await showModalBottomSheet<Station>(
      context: context,
      backgroundColor: FamilyPalette.panel,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final station in Station.popularStations)
              ListTile(
                title: Text(
                  station.name,
                  style: const TextStyle(color: FamilyPalette.textPrimary),
                ),
                onTap: () => Navigator.of(ctx).pop(station),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked.id != _station.id) {
      setState(() => _station = picked);
      await SettingsService.saveDefaultStationId(picked.id);
    }
  }

  Future<void> _pickDestination() async {
    const clearSentinel = Station(id: '', name: '__clear__');
    final picked = await showModalBottomSheet<Station>(
      context: context,
      backgroundColor: FamilyPalette.panel,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'None',
                style: TextStyle(color: FamilyPalette.textSecondary),
              ),
              onTap: () => Navigator.of(ctx).pop(clearSentinel),
            ),
            for (final station in Station.popularStations)
              ListTile(
                title: Text(
                  station.name,
                  style: const TextStyle(color: FamilyPalette.textPrimary),
                ),
                onTap: () => Navigator.of(ctx).pop(station),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    if (picked == clearSentinel) {
      setState(() => _destination = null);
      await SettingsService.saveDestinationStationId(null);
      return;
    }
    if (picked.id != _destination?.id) {
      setState(() => _destination = picked);
      await SettingsService.saveDestinationStationId(picked.id);
    }
  }
}

class _LivePreviewTag extends StatelessWidget {
  const _LivePreviewTag();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'LIVE PREVIEW',
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
              'Synced',
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

class _StationChip extends StatelessWidget {
  final Station station;
  final VoidCallback onTap;

  const _StationChip({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                    'BERLIN',
                    style: GoogleFonts.inter(
                      color: FamilyPalette.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.18 * 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    station.name,
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
        ),
      ),
    );
  }
}

class _DestinationChip extends StatelessWidget {
  final Station? station;
  final VoidCallback onTap;

  const _DestinationChip({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasStation = station != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                    'TO',
                    style: GoogleFonts.inter(
                      color: FamilyPalette.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.18 * 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasStation ? station!.name : 'Not set',
                    style: GoogleFonts.interTight(
                      color: hasStation
                          ? FamilyPalette.textPrimary
                          : FamilyPalette.textSecondary,
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
        ),
      ),
    );
  }
}

class _TimeWindowControls extends StatelessWidget {
  final int skip;
  final int duration;
  final ValueChanged<int> onSkip;
  final ValueChanged<int> onDuration;

  const _TimeWindowControls({
    required this.skip,
    required this.duration,
    required this.onSkip,
    required this.onDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperField(
          caption: 'SKIP FIRST',
          value: '$skip′',
          onMinus: () => onSkip((skip - 1).clamp(0, 60)),
          onPlus: () => onSkip((skip + 1).clamp(0, 60)),
        ),
        const SizedBox(width: 14),
        _StepperField(
          caption: 'SHOW NEXT',
          value: '$duration′',
          onMinus: () => onDuration((duration - 15).clamp(15, 240)),
          onPlus: () => onDuration((duration + 15).clamp(15, 240)),
        ),
      ],
    );
  }
}

class _StepperField extends StatelessWidget {
  final String caption;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _StepperField({
    required this.caption,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          caption,
          style: GoogleFonts.inter(
            color: FamilyPalette.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.18 * 10,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: FamilyPalette.panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FamilyPalette.divider, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepIcon(icon: Icons.remove, onTap: onMinus),
              const SizedBox(width: 14),
              SizedBox(
                width: 46,
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.geistMono(
                    color: FamilyPalette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              _StepIcon(icon: Icons.add, onTap: onPlus),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: FamilyPalette.textSecondary),
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  const _LivePreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'LIVE PREVIEW',
              style: GoogleFonts.inter(
                color: FamilyPalette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2 * 13,
              ),
            ),
            Text(
              'based on your settings',
              style: GoogleFonts.instrumentSerif(
                color: FamilyPalette.textSecondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            color: FamilyPalette.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FamilyPalette.crimson, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      'in',
                      style: GoogleFonts.interTight(
                        color: FamilyPalette.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '8',
                    style: GoogleFonts.geistMono(
                      color: FamilyPalette.crimson,
                      fontSize: 44,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.04 * 44,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      'min',
                      style: GoogleFonts.interTight(
                        color: FamilyPalette.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Container(width: 1, height: 38, color: FamilyPalette.divider),
              const SizedBox(width: 24),
              Text(
                'Flughafen BER',
                style: GoogleFonts.interTight(
                  color: FamilyPalette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.02 * 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: FamilyPalette.crimson.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: FamilyPalette.crimson,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'RE8',
                      style: GoogleFonts.geistMono(
                        color: FamilyPalette.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '14:48',
                style: GoogleFonts.geistMono(
                  color: FamilyPalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
