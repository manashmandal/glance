import 'dart:convert';

class WidgetLayout {
  final String widgetId;
  final double x;
  final double y;
  final double width;
  final double height;
  final int zIndex;

  const WidgetLayout({
    required this.widgetId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.zIndex = 0,
  });

  WidgetLayout copyWith({
    String? widgetId,
    double? x,
    double? y,
    double? width,
    double? height,
    int? zIndex,
  }) {
    return WidgetLayout(
      widgetId: widgetId ?? this.widgetId,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'widgetId': widgetId,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'zIndex': zIndex,
    };
  }

  factory WidgetLayout.fromJson(Map<String, dynamic> json) {
    return WidgetLayout(
      widgetId: json['widgetId'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      zIndex: json['zIndex'] as int? ?? 0,
    );
  }
}

class LayoutPreset {
  final String id;
  final String name;
  final String description;
  final DashboardLayout landscapeLayout;
  final DashboardLayout portraitLayout;

  const LayoutPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.landscapeLayout,
    required this.portraitLayout,
  });
}

class DashboardLayout {
  final Map<String, WidgetLayout> layouts;
  final int version;

  const DashboardLayout({
    required this.layouts,
    this.version = 1,
  });

  static const List<String> widgetIds = [
    'clock',
    'logo',
    'weather',
    'departures'
  ];

  static DashboardLayout get defaultLayout => defaultLandscapeLayout;

  // Layout presets for quick configuration
  static List<LayoutPreset> get presets => [
    LayoutPreset(
      id: 'classic',
      name: 'Classic',
      description: 'Info bar on top, departures below',
      landscapeLayout: defaultLandscapeLayout,
      portraitLayout: defaultPortraitLayout,
    ),
    LayoutPreset(
      id: 'focus_departures',
      name: 'Focus Departures',
      description: 'Large departures, compact info sidebar',
      landscapeLayout: _focusDeparturesLandscape,
      portraitLayout: _focusDeparturesPortrait,
    ),
    LayoutPreset(
      id: 'split_view',
      name: 'Split View',
      description: 'Departures left, info panels right',
      landscapeLayout: _splitViewLandscape,
      portraitLayout: _splitViewPortrait,
    ),
    LayoutPreset(
      id: 'compact_header',
      name: 'Compact Header',
      description: 'Minimal header, maximum departures',
      landscapeLayout: _compactHeaderLandscape,
      portraitLayout: _compactHeaderPortrait,
    ),
  ];

  // Focus Departures: Departures take most space, info on right column
  static DashboardLayout get _focusDeparturesLandscape => DashboardLayout(
        layouts: {
          'departures': const WidgetLayout(
            widgetId: 'departures',
            x: 0.02,
            y: 0.02,
            width: 0.72,
            height: 0.96,
          ),
          'clock': const WidgetLayout(
            widgetId: 'clock',
            x: 0.76,
            y: 0.02,
            width: 0.22,
            height: 0.30,
          ),
          'logo': const WidgetLayout(
            widgetId: 'logo',
            x: 0.76,
            y: 0.34,
            width: 0.22,
            height: 0.30,
          ),
          'weather': const WidgetLayout(
            widgetId: 'weather',
            x: 0.76,
            y: 0.66,
            width: 0.22,
            height: 0.32,
          ),
        },
      );

  static DashboardLayout get _focusDeparturesPortrait => DashboardLayout(
        layouts: {
          'clock': const WidgetLayout(
            widgetId: 'clock',
            x: 0.02,
            y: 0.02,
            width: 0.48,
            height: 0.10,
          ),
          'weather': const WidgetLayout(
            widgetId: 'weather',
            x: 0.52,
            y: 0.02,
            width: 0.46,
            height: 0.10,
          ),
          'departures': const WidgetLayout(
            widgetId: 'departures',
            x: 0.02,
            y: 0.14,
            width: 0.96,
            height: 0.76,
          ),
          'logo': const WidgetLayout(
            widgetId: 'logo',
            x: 0.02,
            y: 0.92,
            width: 0.96,
            height: 0.06,
          ),
        },
      );

  // Split View: Departures left, stacked info on right
  static DashboardLayout get _splitViewLandscape => DashboardLayout(
        layouts: {
          'departures': const WidgetLayout(
            widgetId: 'departures',
            x: 0.02,
            y: 0.02,
            width: 0.60,
            height: 0.96,
          ),
          'clock': const WidgetLayout(
            widgetId: 'clock',
            x: 0.64,
            y: 0.02,
            width: 0.34,
            height: 0.32,
          ),
          'weather': const WidgetLayout(
            widgetId: 'weather',
            x: 0.64,
            y: 0.36,
            width: 0.34,
            height: 0.32,
          ),
          'logo': const WidgetLayout(
            widgetId: 'logo',
            x: 0.64,
            y: 0.70,
            width: 0.34,
            height: 0.28,
          ),
        },
      );

  static DashboardLayout get _splitViewPortrait => DashboardLayout(
        layouts: {
          'clock': const WidgetLayout(
            widgetId: 'clock',
            x: 0.02,
            y: 0.02,
            width: 0.46,
            height: 0.14,
          ),
          'weather': const WidgetLayout(
            widgetId: 'weather',
            x: 0.52,
            y: 0.02,
            width: 0.46,
            height: 0.14,
          ),
          'logo': const WidgetLayout(
            widgetId: 'logo',
            x: 0.02,
            y: 0.18,
            width: 0.96,
            height: 0.10,
          ),
          'departures': const WidgetLayout(
            widgetId: 'departures',
            x: 0.02,
            y: 0.30,
            width: 0.96,
            height: 0.68,
          ),
        },
      );

  // Compact Header: Very small header, maximize departures space
  static DashboardLayout get _compactHeaderLandscape => DashboardLayout(
        layouts: {
          'clock': const WidgetLayout(
            widgetId: 'clock',
            x: 0.02,
            y: 0.02,
            width: 0.24,
            height: 0.16,
          ),
          'logo': const WidgetLayout(
            widgetId: 'logo',
            x: 0.28,
            y: 0.02,
            width: 0.20,
            height: 0.16,
          ),
          'weather': const WidgetLayout(
            widgetId: 'weather',
            x: 0.50,
            y: 0.02,
            width: 0.48,
            height: 0.16,
          ),
          'departures': const WidgetLayout(
            widgetId: 'departures',
            x: 0.02,
            y: 0.20,
            width: 0.96,
            height: 0.78,
          ),
        },
      );

  static DashboardLayout get _compactHeaderPortrait => DashboardLayout(
        layouts: {
          'clock': const WidgetLayout(
            widgetId: 'clock',
            x: 0.02,
            y: 0.02,
            width: 0.48,
            height: 0.08,
          ),
          'weather': const WidgetLayout(
            widgetId: 'weather',
            x: 0.52,
            y: 0.02,
            width: 0.46,
            height: 0.08,
          ),
          'logo': const WidgetLayout(
            widgetId: 'logo',
            x: 0.02,
            y: 0.12,
            width: 0.96,
            height: 0.06,
          ),
          'departures': const WidgetLayout(
            widgetId: 'departures',
            x: 0.02,
            y: 0.20,
            width: 0.96,
            height: 0.78,
          ),
        },
      );

  static DashboardLayout get defaultLandscapeLayout => DashboardLayout(
        layouts: {
          'clock': const WidgetLayout(
            widgetId: 'clock',
            x: 0.02,
            y: 0.02,
            width: 0.30,
            height: 0.32,
          ),
          'logo': const WidgetLayout(
            widgetId: 'logo',
            x: 0.35,
            y: 0.02,
            width: 0.30,
            height: 0.32,
          ),
          'weather': const WidgetLayout(
            widgetId: 'weather',
            x: 0.68,
            y: 0.02,
            width: 0.30,
            height: 0.32,
          ),
          'departures': const WidgetLayout(
            widgetId: 'departures',
            x: 0.02,
            y: 0.38,
            width: 0.96,
            height: 0.58,
          ),
        },
      );

  static DashboardLayout get defaultPortraitLayout => DashboardLayout(
        layouts: {
          'clock': const WidgetLayout(
            widgetId: 'clock',
            x: 0.02,
            y: 0.01,
            width: 0.96,
            height: 0.12,
          ),
          'logo': const WidgetLayout(
            widgetId: 'logo',
            x: 0.02,
            y: 0.14,
            width: 0.46,
            height: 0.14,
          ),
          'weather': const WidgetLayout(
            widgetId: 'weather',
            x: 0.52,
            y: 0.14,
            width: 0.46,
            height: 0.14,
          ),
          'departures': const WidgetLayout(
            widgetId: 'departures',
            x: 0.02,
            y: 0.30,
            width: 0.96,
            height: 0.68,
          ),
        },
      );

  DashboardLayout copyWith({
    Map<String, WidgetLayout>? layouts,
    int? version,
  }) {
    return DashboardLayout(
      layouts: layouts ?? Map.from(this.layouts),
      version: version ?? this.version,
    );
  }

  DashboardLayout updateWidget(String widgetId, WidgetLayout layout) {
    final newLayouts = Map<String, WidgetLayout>.from(layouts);
    newLayouts[widgetId] = layout;
    return DashboardLayout(layouts: newLayouts, version: version);
  }

  String toJsonString() {
    return jsonEncode({
      'layouts': layouts.map((key, value) => MapEntry(key, value.toJson())),
      'version': version,
    });
  }

  factory DashboardLayout.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final layoutsJson = json['layouts'] as Map<String, dynamic>;

    return DashboardLayout(
      layouts: layoutsJson.map(
        (key, value) =>
            MapEntry(key, WidgetLayout.fromJson(value as Map<String, dynamic>)),
      ),
      version: json['version'] as int? ?? 1,
    );
  }
}
