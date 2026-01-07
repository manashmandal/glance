import 'package:flutter_test/flutter_test.dart';
import 'package:glance/models/widget_layout.dart';

void main() {
  group('WidgetLayout', () {
    test('creates with required parameters', () {
      const layout = WidgetLayout(
        widgetId: 'test',
        x: 0.1,
        y: 0.2,
        width: 0.3,
        height: 0.4,
      );

      expect(layout.widgetId, equals('test'));
      expect(layout.x, equals(0.1));
      expect(layout.y, equals(0.2));
      expect(layout.width, equals(0.3));
      expect(layout.height, equals(0.4));
      expect(layout.zIndex, equals(0));
    });

    test('creates with custom zIndex', () {
      const layout = WidgetLayout(
        widgetId: 'test',
        x: 0.1,
        y: 0.2,
        width: 0.3,
        height: 0.4,
        zIndex: 5,
      );

      expect(layout.zIndex, equals(5));
    });

    test('copyWith creates new instance with updated values', () {
      const original = WidgetLayout(
        widgetId: 'test',
        x: 0.1,
        y: 0.2,
        width: 0.3,
        height: 0.4,
      );

      final copied = original.copyWith(x: 0.5, width: 0.6);

      expect(copied.widgetId, equals('test'));
      expect(copied.x, equals(0.5));
      expect(copied.y, equals(0.2));
      expect(copied.width, equals(0.6));
      expect(copied.height, equals(0.4));
    });

    test('toJson returns correct map', () {
      const layout = WidgetLayout(
        widgetId: 'clock',
        x: 0.1,
        y: 0.2,
        width: 0.3,
        height: 0.4,
        zIndex: 2,
      );

      final json = layout.toJson();

      expect(json['widgetId'], equals('clock'));
      expect(json['x'], equals(0.1));
      expect(json['y'], equals(0.2));
      expect(json['width'], equals(0.3));
      expect(json['height'], equals(0.4));
      expect(json['zIndex'], equals(2));
    });

    test('fromJson creates correct instance', () {
      final json = {
        'widgetId': 'weather',
        'x': 0.5,
        'y': 0.6,
        'width': 0.2,
        'height': 0.3,
        'zIndex': 1,
      };

      final layout = WidgetLayout.fromJson(json);

      expect(layout.widgetId, equals('weather'));
      expect(layout.x, equals(0.5));
      expect(layout.y, equals(0.6));
      expect(layout.width, equals(0.2));
      expect(layout.height, equals(0.3));
      expect(layout.zIndex, equals(1));
    });

    test('fromJson handles missing zIndex', () {
      final json = {
        'widgetId': 'logo',
        'x': 0.1,
        'y': 0.2,
        'width': 0.3,
        'height': 0.4,
      };

      final layout = WidgetLayout.fromJson(json);

      expect(layout.zIndex, equals(0));
    });
  });

  group('DashboardLayout', () {
    group('defaultLandscapeLayout', () {
      test('contains all required widget IDs', () {
        final layout = DashboardLayout.defaultLandscapeLayout;

        expect(layout.layouts.containsKey('clock'), isTrue);
        expect(layout.layouts.containsKey('logo'), isTrue);
        expect(layout.layouts.containsKey('weather'), isTrue);
        expect(layout.layouts.containsKey('departures'), isTrue);
        expect(layout.layouts.length, equals(4));
      });

      test('has correct landscape proportions', () {
        final layout = DashboardLayout.defaultLandscapeLayout;

        // Clock, logo, weather should be in top row (small height)
        expect(layout.layouts['clock']!.height, equals(0.32));
        expect(layout.layouts['logo']!.height, equals(0.32));
        expect(layout.layouts['weather']!.height, equals(0.32));

        // Departures should span most of the width at the bottom
        expect(layout.layouts['departures']!.width, equals(0.96));
        expect(layout.layouts['departures']!.height, equals(0.58));
      });

      test('widgets are positioned within bounds', () {
        final layout = DashboardLayout.defaultLandscapeLayout;

        for (final entry in layout.layouts.entries) {
          final widget = entry.value;
          expect(widget.x, greaterThanOrEqualTo(0));
          expect(widget.y, greaterThanOrEqualTo(0));
          expect(widget.x + widget.width, lessThanOrEqualTo(1.0));
          expect(widget.y + widget.height, lessThanOrEqualTo(1.0));
        }
      });
    });

    group('defaultPortraitLayout', () {
      test('contains all required widget IDs', () {
        final layout = DashboardLayout.defaultPortraitLayout;

        expect(layout.layouts.containsKey('clock'), isTrue);
        expect(layout.layouts.containsKey('logo'), isTrue);
        expect(layout.layouts.containsKey('weather'), isTrue);
        expect(layout.layouts.containsKey('departures'), isTrue);
        expect(layout.layouts.length, equals(4));
      });

      test('has correct portrait proportions', () {
        final layout = DashboardLayout.defaultPortraitLayout;

        // Clock should span full width in portrait
        expect(layout.layouts['clock']!.width, equals(0.96));
        expect(layout.layouts['clock']!.height, equals(0.12));

        // Logo and weather should be side by side
        expect(layout.layouts['logo']!.width, equals(0.46));
        expect(layout.layouts['weather']!.width, equals(0.46));

        // Departures should take most of the vertical space
        expect(layout.layouts['departures']!.width, equals(0.96));
        expect(layout.layouts['departures']!.height, equals(0.68));
      });

      test('widgets are positioned within bounds', () {
        final layout = DashboardLayout.defaultPortraitLayout;

        for (final entry in layout.layouts.entries) {
          final widget = entry.value;
          expect(widget.x, greaterThanOrEqualTo(0));
          expect(widget.y, greaterThanOrEqualTo(0));
          expect(widget.x + widget.width, lessThanOrEqualTo(1.0));
          expect(widget.y + widget.height, lessThanOrEqualTo(1.0));
        }
      });
    });

    group('defaultLayout', () {
      test('returns landscape layout by default', () {
        final defaultLayout = DashboardLayout.defaultLayout;
        final landscapeLayout = DashboardLayout.defaultLandscapeLayout;

        expect(
          defaultLayout.layouts['clock']!.width,
          equals(landscapeLayout.layouts['clock']!.width),
        );
      });
    });

    group('widgetIds', () {
      test('contains expected widget identifiers', () {
        expect(DashboardLayout.widgetIds, contains('clock'));
        expect(DashboardLayout.widgetIds, contains('logo'));
        expect(DashboardLayout.widgetIds, contains('weather'));
        expect(DashboardLayout.widgetIds, contains('departures'));
        expect(DashboardLayout.widgetIds.length, equals(4));
      });
    });

    group('updateWidget', () {
      test('updates specific widget layout', () {
        final original = DashboardLayout.defaultLandscapeLayout;
        const newClockLayout = WidgetLayout(
          widgetId: 'clock',
          x: 0.5,
          y: 0.5,
          width: 0.4,
          height: 0.4,
        );

        final updated = original.updateWidget('clock', newClockLayout);

        expect(updated.layouts['clock']!.x, equals(0.5));
        expect(updated.layouts['clock']!.width, equals(0.4));
        // Other widgets unchanged
        expect(updated.layouts['logo']!.x, equals(original.layouts['logo']!.x));
      });
    });

    group('serialization', () {
      test('toJsonString and fromJsonString roundtrip', () {
        final original = DashboardLayout.defaultLandscapeLayout;
        final jsonString = original.toJsonString();
        final restored = DashboardLayout.fromJsonString(jsonString);

        expect(restored.layouts.length, equals(original.layouts.length));
        expect(
          restored.layouts['clock']!.x,
          equals(original.layouts['clock']!.x),
        );
        expect(
          restored.layouts['clock']!.width,
          equals(original.layouts['clock']!.width),
        );
        expect(restored.version, equals(original.version));
      });

      test('handles custom layouts in serialization', () {
        final custom = DashboardLayout(
          layouts: {
            'clock': const WidgetLayout(
              widgetId: 'clock',
              x: 0.1,
              y: 0.1,
              width: 0.2,
              height: 0.2,
              zIndex: 3,
            ),
            'logo': const WidgetLayout(
              widgetId: 'logo',
              x: 0.4,
              y: 0.1,
              width: 0.3,
              height: 0.3,
            ),
            'weather': const WidgetLayout(
              widgetId: 'weather',
              x: 0.7,
              y: 0.1,
              width: 0.2,
              height: 0.3,
            ),
            'departures': const WidgetLayout(
              widgetId: 'departures',
              x: 0.1,
              y: 0.5,
              width: 0.8,
              height: 0.4,
            ),
          },
          version: 2,
        );

        final jsonString = custom.toJsonString();
        final restored = DashboardLayout.fromJsonString(jsonString);

        expect(restored.layouts['clock']!.zIndex, equals(3));
        expect(restored.version, equals(2));
      });
    });

    group('portrait vs landscape differences', () {
      test('portrait clock is wider than landscape clock', () {
        final portrait = DashboardLayout.defaultPortraitLayout;
        final landscape = DashboardLayout.defaultLandscapeLayout;

        expect(
          portrait.layouts['clock']!.width,
          greaterThan(landscape.layouts['clock']!.width),
        );
      });

      test('portrait departures takes more vertical space', () {
        final portrait = DashboardLayout.defaultPortraitLayout;
        final landscape = DashboardLayout.defaultLandscapeLayout;

        expect(
          portrait.layouts['departures']!.height,
          greaterThan(landscape.layouts['departures']!.height),
        );
      });

      test('landscape has widgets in different positions than portrait', () {
        final portrait = DashboardLayout.defaultPortraitLayout;
        final landscape = DashboardLayout.defaultLandscapeLayout;

        // In landscape, logo and weather are side by side with clock
        // In portrait, clock is full width on top
        expect(
          portrait.layouts['clock']!.y,
          isNot(equals(landscape.layouts['clock']!.y)),
        );
      });
    });
  });
}
