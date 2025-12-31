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

class DashboardLayout {
  final Map<String, WidgetLayout> layouts;
  final int version;

  const DashboardLayout({
    required this.layouts,
    this.version = 1,
  });

  static const List<String> widgetIds = ['clock', 'logo', 'weather', 'departures'];

  static DashboardLayout get defaultLayout => DashboardLayout(
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
        (key, value) => MapEntry(key, WidgetLayout.fromJson(value as Map<String, dynamic>)),
      ),
      version: json['version'] as int? ?? 1,
    );
  }
}
