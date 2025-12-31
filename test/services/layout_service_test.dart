import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glance/services/layout_service.dart';
import 'package:glance/models/widget_layout.dart';

void main() {
  group('LayoutService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('getLayout', () {
      test('returns default landscape layout when no saved layout exists', () async {
        final layout = await LayoutService.getLayout(isPortrait: false);

        expect(layout.layouts.length, equals(4));
        expect(layout.layouts.containsKey('clock'), isTrue);
        expect(layout.layouts.containsKey('logo'), isTrue);
        expect(layout.layouts.containsKey('weather'), isTrue);
        expect(layout.layouts.containsKey('departures'), isTrue);
      });

      test('returns default portrait layout when no saved layout exists', () async {
        final layout = await LayoutService.getLayout(isPortrait: true);

        expect(layout.layouts.length, equals(4));
        // Portrait layout has different dimensions
        expect(layout.layouts['clock']!.width, equals(0.96));
        expect(layout.layouts['clock']!.height, equals(0.12));
      });

      test('returns saved landscape layout when it exists', () async {
        final customLayout = DashboardLayout(
          layouts: {
            'clock': const WidgetLayout(
              widgetId: 'clock',
              x: 0.1,
              y: 0.1,
              width: 0.5,
              height: 0.5,
            ),
            'logo': const WidgetLayout(
              widgetId: 'logo',
              x: 0.6,
              y: 0.1,
              width: 0.3,
              height: 0.3,
            ),
            'weather': const WidgetLayout(
              widgetId: 'weather',
              x: 0.1,
              y: 0.6,
              width: 0.3,
              height: 0.3,
            ),
            'departures': const WidgetLayout(
              widgetId: 'departures',
              x: 0.5,
              y: 0.5,
              width: 0.4,
              height: 0.4,
            ),
          },
        );

        await LayoutService.saveLayout(customLayout, isPortrait: false);
        final retrieved = await LayoutService.getLayout(isPortrait: false);

        expect(retrieved.layouts['clock']!.x, equals(0.1));
        expect(retrieved.layouts['clock']!.width, equals(0.5));
      });

      test('returns saved portrait layout when it exists', () async {
        final customLayout = DashboardLayout(
          layouts: {
            'clock': const WidgetLayout(
              widgetId: 'clock',
              x: 0.05,
              y: 0.05,
              width: 0.9,
              height: 0.15,
            ),
            'logo': const WidgetLayout(
              widgetId: 'logo',
              x: 0.05,
              y: 0.2,
              width: 0.4,
              height: 0.2,
            ),
            'weather': const WidgetLayout(
              widgetId: 'weather',
              x: 0.55,
              y: 0.2,
              width: 0.4,
              height: 0.2,
            ),
            'departures': const WidgetLayout(
              widgetId: 'departures',
              x: 0.05,
              y: 0.45,
              width: 0.9,
              height: 0.5,
            ),
          },
        );

        await LayoutService.saveLayout(customLayout, isPortrait: true);
        final retrieved = await LayoutService.getLayout(isPortrait: true);

        expect(retrieved.layouts['clock']!.x, equals(0.05));
        expect(retrieved.layouts['clock']!.width, equals(0.9));
      });

      test('landscape and portrait layouts are stored separately', () async {
        final landscapeLayout = DashboardLayout(
          layouts: {
            'clock': const WidgetLayout(
              widgetId: 'clock',
              x: 0.1,
              y: 0.1,
              width: 0.3,
              height: 0.3,
            ),
            'logo': const WidgetLayout(widgetId: 'logo', x: 0.4, y: 0.1, width: 0.3, height: 0.3),
            'weather': const WidgetLayout(widgetId: 'weather', x: 0.7, y: 0.1, width: 0.2, height: 0.3),
            'departures': const WidgetLayout(widgetId: 'departures', x: 0.1, y: 0.5, width: 0.8, height: 0.4),
          },
        );

        final portraitLayout = DashboardLayout(
          layouts: {
            'clock': const WidgetLayout(
              widgetId: 'clock',
              x: 0.05,
              y: 0.05,
              width: 0.9,
              height: 0.1,
            ),
            'logo': const WidgetLayout(widgetId: 'logo', x: 0.05, y: 0.2, width: 0.4, height: 0.15),
            'weather': const WidgetLayout(widgetId: 'weather', x: 0.55, y: 0.2, width: 0.4, height: 0.15),
            'departures': const WidgetLayout(widgetId: 'departures', x: 0.05, y: 0.4, width: 0.9, height: 0.55),
          },
        );

        await LayoutService.saveLayout(landscapeLayout, isPortrait: false);
        await LayoutService.saveLayout(portraitLayout, isPortrait: true);

        final retrievedLandscape = await LayoutService.getLayout(isPortrait: false);
        final retrievedPortrait = await LayoutService.getLayout(isPortrait: true);

        expect(retrievedLandscape.layouts['clock']!.width, equals(0.3));
        expect(retrievedPortrait.layouts['clock']!.width, equals(0.9));
      });

      test('falls back to legacy key for landscape when new key missing', () async {
        // Simulate legacy layout saved under old key
        final prefs = await SharedPreferences.getInstance();
        final legacyLayout = DashboardLayout(
          layouts: {
            'clock': const WidgetLayout(widgetId: 'clock', x: 0.15, y: 0.15, width: 0.25, height: 0.25),
            'logo': const WidgetLayout(widgetId: 'logo', x: 0.4, y: 0.1, width: 0.3, height: 0.3),
            'weather': const WidgetLayout(widgetId: 'weather', x: 0.7, y: 0.1, width: 0.2, height: 0.3),
            'departures': const WidgetLayout(widgetId: 'departures', x: 0.1, y: 0.5, width: 0.8, height: 0.4),
          },
        );
        await prefs.setString('dashboard_layout', legacyLayout.toJsonString());

        final retrieved = await LayoutService.getLayout(isPortrait: false);

        expect(retrieved.layouts['clock']!.x, equals(0.15));
        expect(retrieved.layouts['clock']!.width, equals(0.25));
      });
    });

    group('saveLayout', () {
      test('saves landscape layout with correct key', () async {
        final layout = DashboardLayout.defaultLandscapeLayout;
        await LayoutService.saveLayout(layout, isPortrait: false);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('dashboard_layout_landscape'), isTrue);
        expect(prefs.containsKey('dashboard_layout_portrait'), isFalse);
      });

      test('saves portrait layout with correct key', () async {
        final layout = DashboardLayout.defaultPortraitLayout;
        await LayoutService.saveLayout(layout, isPortrait: true);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('dashboard_layout_portrait'), isTrue);
      });
    });

    group('resetToDefault', () {
      test('removes landscape layout key', () async {
        await LayoutService.saveLayout(DashboardLayout.defaultLandscapeLayout, isPortrait: false);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('dashboard_layout_landscape'), isTrue);

        await LayoutService.resetToDefault(isPortrait: false);

        expect(prefs.containsKey('dashboard_layout_landscape'), isFalse);
      });

      test('removes portrait layout key', () async {
        await LayoutService.saveLayout(DashboardLayout.defaultPortraitLayout, isPortrait: true);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('dashboard_layout_portrait'), isTrue);

        await LayoutService.resetToDefault(isPortrait: true);

        expect(prefs.containsKey('dashboard_layout_portrait'), isFalse);
      });

      test('after reset, getLayout returns default', () async {
        final customLayout = DashboardLayout(
          layouts: {
            'clock': const WidgetLayout(widgetId: 'clock', x: 0.5, y: 0.5, width: 0.2, height: 0.2),
            'logo': const WidgetLayout(widgetId: 'logo', x: 0.4, y: 0.1, width: 0.3, height: 0.3),
            'weather': const WidgetLayout(widgetId: 'weather', x: 0.7, y: 0.1, width: 0.2, height: 0.3),
            'departures': const WidgetLayout(widgetId: 'departures', x: 0.1, y: 0.5, width: 0.8, height: 0.4),
          },
        );
        await LayoutService.saveLayout(customLayout, isPortrait: false);
        await LayoutService.resetToDefault(isPortrait: false);

        final layout = await LayoutService.getLayout(isPortrait: false);

        // Should return default landscape layout values
        expect(layout.layouts['clock']!.x, equals(0.02));
        expect(layout.layouts['clock']!.width, equals(0.30));
      });
    });

    group('resetAllLayouts', () {
      test('removes all layout keys including legacy', () async {
        await LayoutService.saveLayout(DashboardLayout.defaultLandscapeLayout, isPortrait: false);
        await LayoutService.saveLayout(DashboardLayout.defaultPortraitLayout, isPortrait: true);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('dashboard_layout', 'legacy_data');

        await LayoutService.resetAllLayouts();

        expect(prefs.containsKey('dashboard_layout_landscape'), isFalse);
        expect(prefs.containsKey('dashboard_layout_portrait'), isFalse);
        expect(prefs.containsKey('dashboard_layout'), isFalse);
      });
    });
  });
}
