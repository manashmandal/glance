import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/update_service.dart';
import '../../../theme/family_palette.dart';
import '../../../theme/family_typography.dart';
import '../common/pane_header.dart';

class AboutPane extends StatefulWidget {
  const AboutPane({super.key});

  @override
  State<AboutPane> createState() => _AboutPaneState();
}

class _AboutPaneState extends State<AboutPane> {
  String _version = '0.0.0';
  int _buildNumber = 0;
  String? _updateVersion;
  String? _downloadUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    final update = await UpdateService.checkForUpdate(info.version);
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _buildNumber = int.tryParse(info.buildNumber) ?? 0;
      if (update != null && update.updateAvailable) {
        _updateVersion = update.latestVersion;
        _downloadUrl = update.downloadUrl;
      }
    });
  }

  Future<void> _install() async {
    if (_downloadUrl == null) return;
    final uri = Uri.parse(_downloadUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaneHeader(
          eyebrow: 'About',
          title: "What's underneath",
          subtitle: 'A small open-source app, made in Berlin.',
          trailing: const _BigWordmark(),
        ),
        const SizedBox(height: 32),
        _UpdateBanner(
          version: _updateVersion ?? '0.2.0 · Live timeline ribbon',
          notes: _updateVersion != null
              ? 'Install to get the latest fixes and features.'
              : 'Adds the new editorial dashboard, dark "Twilight" theme, and S+U fuzzy search.',
          onInstall: _install,
          dimmed: _updateVersion == null,
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoTable(
                heading: 'BUILD',
                rows: [
                  _InfoPair('Version', '$_version ($_buildNumber)'),
                  const _InfoPair('Channel', 'stable'),
                  const _InfoPair('Flutter', '3.27.1'),
                  _InfoPair('Last sync', _now()),
                ],
              ),
            ),
            const SizedBox(width: 40),
            Expanded(
              child: _InfoTable(
                heading: 'SOURCES',
                rows: const [
                  _InfoPair('Transit', 'BVG v6 API', dotted: true),
                  _InfoPair('Weather', 'Open-Meteo', dotted: true),
                  _InfoPair('AI', 'Claude Haiku 4.5', dotted: true),
                  _InfoPair('License', 'MIT'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        _Footer(),
      ],
    );
  }

  String _now() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return '$hh:$mm · 6s ago';
  }
}

class _BigWordmark extends StatelessWidget {
  const _BigWordmark();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'glance',
            style: FamilyType.splashWordmark(color: FamilyPalette.textPrimary)
                .copyWith(fontSize: 60),
          ),
          Text(
            '.',
            style: FamilyType.splashWordmark(color: FamilyPalette.crimson)
                .copyWith(fontSize: 60),
          ),
        ],
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  final String version;
  final String notes;
  final VoidCallback onInstall;
  final bool dimmed;

  const _UpdateBanner({
    required this.version,
    required this.notes,
    required this.onInstall,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FamilyPalette.crimsonTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FamilyPalette.crimson, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: FamilyPalette.crimson,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'UPDATE AVAILABLE',
                      style: GoogleFonts.inter(
                        color: FamilyPalette.crimson,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2 * 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dimmed ? 'v $version' : 'v $version',
                  style: FamilyType.sectionTitle().copyWith(
                    color: dimmed
                        ? FamilyPalette.textPrimary.withValues(alpha: 0.9)
                        : FamilyPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(notes, style: FamilyType.sectionDescription()),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Material(
            color: FamilyPalette.crimson,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onInstall,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                child: Text(
                  'Install',
                  style: GoogleFonts.interTight(
                    color: FamilyPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTable extends StatelessWidget {
  final String heading;
  final List<_InfoPair> rows;

  const _InfoTable({required this.heading, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: GoogleFonts.inter(
            color: FamilyPalette.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2 * 11,
          ),
        ),
        const SizedBox(height: 14),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Text(
                  row.label,
                  style: GoogleFonts.interTight(
                    color: FamilyPalette.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  row.value,
                  style: GoogleFonts.geistMono(
                    color: FamilyPalette.textPrimary,
                    fontSize: 13,
                  ),
                ),
                if (row.dotted) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: FamilyPalette.sage,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoPair {
  final String label;
  final String value;
  final bool dotted;
  const _InfoPair(this.label, this.value, {this.dotted = false});
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 1, color: FamilyPalette.divider),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Made for the morning rush.',
                      style: FamilyType.settingsSubtitle(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manash Mandal · Berlin · MMXXVI',
                      style: FamilyType.sectionDescription().copyWith(
                        color: FamilyPalette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _FooterButton(label: 'GitHub'),
              const SizedBox(width: 10),
              _FooterButton(label: 'Changelog'),
              const SizedBox(width: 10),
              _FooterButton(label: 'Privacy'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final String label;
  const _FooterButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: FamilyPalette.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FamilyPalette.divider, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.interTight(
          color: FamilyPalette.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
