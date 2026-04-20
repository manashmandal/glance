import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/family_palette.dart';
import '../theme/family_typography.dart';
import '../widgets/family/common/brand_mark.dart';
import '../widgets/settings/common/settings_nav_list.dart';
import '../widgets/settings/panes/about_pane.dart';
import '../widgets/settings/panes/departures_pane.dart';
import '../widgets/settings/panes/display_pane.dart';
import '../widgets/settings/panes/layout_pane.dart';
import '../widgets/settings/panes/weather_pane.dart';

/// Full-screen settings overlay. A compact brand strip sits across the
/// top, a sidebar with five sections hugs the left, and the selected
/// pane occupies the rest of the surface.
class SettingsScreen extends StatefulWidget {
  final String initialPaneId;
  const SettingsScreen({super.key, this.initialPaneId = 'display'});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _activeId = widget.initialPaneId;

  static const _entries = <SettingsNavEntry>[
    SettingsNavEntry(
      id: 'display',
      title: 'Display',
      subtitle: 'Theme · Scale · Fullscreen',
    ),
    SettingsNavEntry(
      id: 'departures',
      title: 'Departures',
      subtitle: 'Station · Transport · Window',
    ),
    SettingsNavEntry(
      id: 'weather',
      title: 'Weather',
      subtitle: 'Location · AI suggestions',
    ),
    SettingsNavEntry(
      id: 'layout',
      title: 'Layout',
      subtitle: 'Presets · Edit mode',
    ),
    SettingsNavEntry(
      id: 'about',
      title: 'About',
      subtitle: 'Version · Updates · Credits',
    ),
  ];

  Widget _pane() {
    switch (_activeId) {
      case 'departures':
        return const DeparturesPane();
      case 'weather':
        return const WeatherPane();
      case 'layout':
        return const LayoutPane();
      case 'about':
        return const AboutPane();
      case 'display':
      default:
        return const DisplayPane();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FamilyPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onClose: () => Navigator.of(context).pop()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 12, 40, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Sidebar(
                      activeId: _activeId,
                      onSelected: (id) => setState(() => _activeId = id),
                    ),
                    const SizedBox(width: 36),
                    Expanded(
                      child: SingleChildScrollView(child: _pane()),
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

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 10),
      child: Row(
        children: [
          const BrandMark(),
          const SizedBox(width: 10),
          Text(
            'glance.',
            style: FamilyType.brandWordmark().copyWith(fontSize: 20),
          ),
          const SizedBox(width: 16),
          Text('v 0.1.0'.toUpperCase(), style: FamilyType.metaMono()),
          const Spacer(),
          Text(
            'TAP OUTSIDE TO CLOSE',
            style: GoogleFonts.inter(
              color: FamilyPalette.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.16 * 11,
              height: 14 / 11,
            ),
          ),
          const SizedBox(width: 14),
          _CloseButton(onTap: onClose),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: FamilyPalette.panel,
            shape: BoxShape.circle,
            border: Border.all(color: FamilyPalette.divider, width: 1),
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 16,
            color: FamilyPalette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String activeId;
  final ValueChanged<String> onSelected;

  const _Sidebar({required this.activeId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings', style: FamilyType.settingsSidebarTitle()),
                const SizedBox(height: 6),
                Text(
                  'your glance, tuned.',
                  style: FamilyType.settingsSidebarTagline(),
                ),
              ],
            ),
          ),
          SettingsNavList(
            entries: _SettingsScreenState._entries,
            activeId: activeId,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}
