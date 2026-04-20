import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/feature_flags.dart';
import '../../../theme/family_palette.dart';
import '../../../theme/family_typography.dart';
import '../common/pane_header.dart';
import '../common/settings_row.dart';
import '../common/settings_toggle.dart';

/// Pane that lists every [FeatureFlag] with a live toggle. Overrides
/// are persisted via `SharedPreferences` in debug builds only — release
/// builds ignore stored overrides. The settings screen also hides this
/// pane in release builds. Flipping a flag rebuilds the pane in place
/// so the new state is visible without a hot reload.
class DevPane extends StatefulWidget {
  final VoidCallback? onChanged;

  const DevPane({super.key, this.onChanged});

  @override
  State<DevPane> createState() => _DevPaneState();
}

class _DevPaneState extends State<DevPane> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaneHeader(
          eyebrow: 'Dev',
          title: 'Feature flags',
          subtitle:
              'Local overrides for debug builds. Release builds use defaults.',
          trailing: const _DebugBadge(),
        ),
        const SizedBox(height: 30),
        for (var i = 0; i < FeatureFlags.all.length; i++)
          _FlagRow(
            flag: FeatureFlags.all[i],
            showDivider: i != 0,
            onToggle: (v) async {
              await FeatureFlags.setOverride(FeatureFlags.all[i], v);
              if (!mounted) return;
              setState(() {});
              widget.onChanged?.call();
            },
            onReset: FeatureFlags.hasOverride(FeatureFlags.all[i])
                ? () async {
                    await FeatureFlags.clearOverride(FeatureFlags.all[i]);
                    if (!mounted) return;
                    setState(() {});
                    widget.onChanged?.call();
                  }
                : null,
          ),
      ],
    );
  }
}

class _FlagRow extends StatelessWidget {
  final FeatureFlag flag;
  final bool showDivider;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onReset;

  const _FlagRow({
    required this.flag,
    required this.showDivider,
    required this.onToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final overridden = FeatureFlags.hasOverride(flag);
    return SettingsRow(
      showDivider: showDivider,
      title: flag.label,
      description:
          '${flag.description}  •  default: ${flag.defaultValue ? "on" : "off"}',
      trailingBadge: overridden ? const _OverrideBadge() : null,
      control: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onReset != null) ...[
            _ResetLink(onTap: onReset!),
            const SizedBox(width: 12),
          ],
          SettingsToggle(
            value: FeatureFlags.isEnabled(flag),
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

class _DebugBadge extends StatelessWidget {
  const _DebugBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: FamilyPalette.amberTint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FamilyPalette.amber, width: 1),
      ),
      child: Text(
        'DEBUG ONLY',
        style: GoogleFonts.inter(
          color: FamilyPalette.amber,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2 * 10,
        ),
      ),
    );
  }
}

class _OverrideBadge extends StatelessWidget {
  const _OverrideBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FamilyPalette.amberTint,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'OVERRIDE',
        style: GoogleFonts.inter(
          color: FamilyPalette.amber,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2 * 9,
        ),
      ),
    );
  }
}

class _ResetLink extends StatelessWidget {
  final VoidCallback onTap;
  const _ResetLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'Reset',
            style: FamilyType.sectionDescription().copyWith(
              color: FamilyPalette.textSecondary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}
