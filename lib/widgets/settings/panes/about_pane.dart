import 'package:flutter/foundation.dart';
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
  UpdateInfo? _update;
  List<ReleaseEntry> _releases = const [];
  DateTime? _lastCheck;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    // Fire both futures, then await — keeps parallelism without the
    // Object-typed List from Future.wait() forcing downcasts.
    final updateFuture = UpdateService.checkForUpdate(info.version);
    final releasesFuture = UpdateService.fetchRecentReleases(count: 4);
    final update = await updateFuture;
    final releases = await releasesFuture;
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _buildNumber = int.tryParse(info.buildNumber) ?? 0;
      _update = update;
      _releases = releases;
      _lastCheck = DateTime.now();
      _checking = false;
    });
  }

  Future<void> _install() async {
    final url = _update?.downloadUrl;
    if (url == null) return;
    await _open(url);
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('AboutPane._open launch failed for $url: $e');
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
          update: _update,
          currentVersion: _version,
          lastCheck: _lastCheck,
          checking: _checking,
          onInstall: _install,
          onRecheck: _load,
        ),
        if (_releases.isNotEmpty) ...[
          const SizedBox(height: 24),
          _ChangelogList(
            releases: _releases,
            onOpen: (url) => _open(url),
          ),
        ],
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
                  _InfoPair('AI', 'ML Kit · Gemini Nano', dotted: true),
                  _InfoPair('License', 'MIT'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        const _Footer(),
      ],
    );
  }

  String _now() {
    final check = _lastCheck ?? DateTime.now();
    final hh = check.hour.toString().padLeft(2, '0');
    final mm = check.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
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
  final UpdateInfo? update;
  final String currentVersion;
  final DateTime? lastCheck;
  final bool checking;
  final VoidCallback onInstall;
  final VoidCallback onRecheck;

  const _UpdateBanner({
    required this.update,
    required this.currentVersion,
    required this.lastCheck,
    required this.checking,
    required this.onInstall,
    required this.onRecheck,
  });

  @override
  Widget build(BuildContext context) {
    final hasUpdate = update != null;
    final color = hasUpdate ? FamilyPalette.crimson : FamilyPalette.sage;
    final bg = hasUpdate ? FamilyPalette.crimsonTint : FamilyPalette.panel;
    final eyebrow = checking
        ? 'CHECKING…'
        : hasUpdate
            ? 'UPDATE AVAILABLE'
            : 'UP TO DATE';

    final title = hasUpdate
        ? 'v${update!.latestVersion} · ${update!.releaseName}'
        : 'v$currentVersion';
    final subtitle = checking
        ? 'Reaching GitHub for the latest release…'
        : hasUpdate
            ? _shortNotes(update!.releaseNotes)
            : 'You\'re on the latest. Last checked ${_agoLabel(lastCheck)}.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: hasUpdate ? 1.5 : 1),
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
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      eyebrow,
                      style: GoogleFonts.inter(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2 * 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(title, style: FamilyType.sectionTitle()),
                const SizedBox(height: 6),
                Text(subtitle, style: FamilyType.sectionDescription()),
              ],
            ),
          ),
          const SizedBox(width: 20),
          if (hasUpdate)
            _BannerButton(
              label: 'Install',
              filled: true,
              onTap: onInstall,
            )
          else
            _BannerButton(
              label: 'Check again',
              filled: false,
              onTap: checking ? null : onRecheck,
            ),
        ],
      ),
    );
  }

  String _shortNotes(String raw) {
    if (raw.isEmpty) return 'Install to get the latest fixes and features.';
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) =>
            l.isNotEmpty &&
            !l.startsWith('#') &&
            !l.startsWith('---') &&
            !l.startsWith('**Full Changelog'))
        .take(3)
        .map(_stripBullet)
        .toList();
    if (lines.isEmpty) return 'Install to get the latest fixes and features.';
    return lines.join(' · ');
  }

  String _stripBullet(String line) {
    final cleaned = line.replaceFirst(RegExp(r'^[-*]\s+'), '');
    return cleaned;
  }

  String _agoLabel(DateTime? when) {
    if (when == null) return 'just now';
    final diff = DateTime.now().difference(when);
    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _BannerButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  const _BannerButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: filled ? FamilyPalette.crimson : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: filled
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FamilyPalette.divider, width: 1),
                  ),
            child: Text(
              label,
              style: GoogleFonts.interTight(
                color: FamilyPalette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangelogList extends StatelessWidget {
  final List<ReleaseEntry> releases;
  final ValueChanged<String> onOpen;

  const _ChangelogList({required this.releases, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CHANGELOG',
          style: GoogleFonts.inter(
            color: FamilyPalette.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2 * 11,
          ),
        ),
        const SizedBox(height: 12),
        for (final release in releases)
          _ChangelogRow(
            release: release,
            onOpen: () => onOpen(release.htmlUrl),
          ),
      ],
    );
  }
}

class _ChangelogRow extends StatelessWidget {
  final ReleaseEntry release;
  final VoidCallback onOpen;

  const _ChangelogRow({required this.release, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'v${release.version}',
                  style: GoogleFonts.geistMono(
                    color: FamilyPalette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateLabel(release.publishedAt),
                  style: GoogleFonts.geistMono(
                    color: FamilyPalette.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _changelogPreview(release.notes),
              style: FamilyType.sectionDescription().copyWith(
                color: FamilyPalette.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                'Open',
                style: GoogleFonts.interTight(
                  color: FamilyPalette.crimson,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime? when) {
    if (when == null) return '—';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[when.month - 1]} ${when.day}, ${when.year}';
  }

  String _changelogPreview(String raw) {
    if (raw.isEmpty) return 'No notes.';
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) =>
            l.isNotEmpty &&
            !l.startsWith('#') &&
            !l.startsWith('---') &&
            !l.startsWith('**Full Changelog') &&
            !l.startsWith('**Version:'))
        .map((l) => l.replaceFirst(RegExp(r'^[-*]\s+'), ''))
        .take(4)
        .toList();
    if (lines.isEmpty) return 'No notes.';
    return lines.join(' · ');
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
  const _Footer();

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
