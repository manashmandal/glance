# Testing & Debugging

Testing pyramid, widget/unit/integration tests, plugin mocking, debugging, error handling.

## Testing pyramid

- **Unit** — many, cheap, fast. One function/method/class. Mock external deps. No disk I/O or rendering. Low confidence, low maintenance.
- **Widget** — more than integration, fewer than unit. One widget or small tree. Uses `testWidgets()` + `WidgetTester`. Medium cost/confidence.
- **Integration** — fewest, slowest, highest confidence. Full app or major flow on real device/emulator/desktop. Uses the `integration_test` package.

## Unit tests

- `dev:test` (pure Dart) or `flutter_test` (Flutter). Files under `test/`, suffix `_test.dart`.
- Use `test()`, `expect()`, `group()`. Run `flutter test path/to/file.dart` or `--plain-name "group"`.
- Mock slow/flaky external deps (HTTP, DB). Inject deps so you can swap real/mock.
- **Mockito** — null-safe (5.0+). Requires `build_runner` codegen. Annotate with `@GenerateMocks` / `@GenerateNiceMocks`. Stub via `when(...).thenAnswer(...)`.
- **Mocktail** — no codegen. Common alternative when codegen is painful.
- **Fakes vs mocks** — fakes are hand-written alternative implementations with working behavior; mocks stub per-call responses. Prefer fakes for value-like collaborators, mocks for verifying interactions.

## Widget tests

### Finder preference order (most robust first)
1. `find.byKey(Key('...'))` — most stable. Add explicit keys to scrollable items and interactive widgets.
2. `find.bySemanticsLabel('...')` — accessible + semantic.
3. `find.byType(FloatingActionButton)` — stable when only one of that type.
4. `find.byIcon(Icons.add)` — good for icon-only widgets.
5. `find.text('Submit')` — brittle to copy changes / i18n.
6. `find.byWidget(instance)` — only when you have the exact instance.

### Matchers
`findsOneWidget`, `findsNothing`, `findsWidgets`, `findsNWidgets(n)`, `matchesGoldenFile(...)`.

### Pumping strategy
- `pumpWidget(widget)` — initial mount. Once per test.
- `pump()` — schedule one frame. Use when driving animations tick-by-tick.
- `pump(Duration)` — advance the fake clock. Use for `Future.delayed`, `Timer`, explicit animation timing.
- `pumpAndSettle()` — pump until no frames are scheduled. After navigation or finite animations. **Hangs on infinite animations** (e.g., `CircularProgressIndicator`) — use `pump(Duration)` instead.

### Interactions
`tester.tap(finder)`, `tester.longPress(finder)`, `tester.drag(finder, Offset(dx, dy))`, `tester.fling(...)`, `tester.enterText(finder, 'text')`. Always `await` and follow with `pump`/`pumpAndSettle`.

### Scrolling
- `tester.scrollUntilVisible(itemFinder, delta, scrollable: find.byType(Scrollable))` handles variable heights.
- Add `Key`s to list items.
- Gesture-style: `tester.dragUntilVisible(...)`.

### Async
Wrap in `tester.runAsync(() async { ... })` only when you need real async (real HTTP, timers the fake clock can't drive). Otherwise prefer `pump(Duration)`.

## Integration tests

- `dev:integration_test: {sdk: flutter}`. Tests in `integration_test/`.
- Call `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` in `main()`.
- Reuse `flutter_test` APIs (finders, `WidgetTester`, `testWidgets`).
- **`flutter_driver` is legacy** — migrate to `integration_test`. Driver still required only for web (ChromeDriver + `test_driver/integration_test.dart`).
- Run: `flutter test integration_test/app_test.dart` on device/emulator/desktop. `flutter drive ...` only for web + profile-mode perf traces.
- **Profiling**: `binding.traceAction(() async {...}, reportKey: '...')` → convert to `TimelineSummary` → `writeTimelineToFile(pretty: true, includeSummary: true)`. Run with `--profile --no-dds`. Key metrics: `average_frame_build_time_millis`, `missed_frame_*_budget_count`.

## Plugin testing

- **Preferred**: wrap the plugin in your own API, mock the wrapper.
- Mock the plugin's public class if API is class-based. For federated plugins, register a mock platform-interface implementation.
- **Last resort — MethodChannel mock**:
  ```dart
  TestDefaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'foo') return 'bar';
    return null;
  });
  ```
  Without this you get `MissingPluginException(No implementation found for method X on channel Y)`.
- Unit/widget tests **cannot execute native code** — only integration tests do.
- Integration-test each platform-channel call at minimum. Add native unit tests (JUnit under `android/src/test/`, XCTest under `example/ios/RunnerTests/`, GoogleTest under `linux/test/`, `windows/test/`) for native logic.

## Debugging

- **DevTools panels**: Inspector (tree + props), Performance (frames/jank), CPU Profiler, Memory, Network, Logging, Debugger.
- **Run modes**: `debug` (JIT, asserts, hot reload), `profile` (AOT, some instrumentation — for perf on real device), `release` (AOT, stripped, for users).
- **Logging**: `print` (truncated), `debugPrint` (throttled, preferred), `log()` from `dart:developer` (supports `name:`, `error:`, `stackTrace:`).
- **Breakpoints**: IDE breakpoints or `debugger(when: cond)` from `dart:developer`.
- **Tree dumps**: `debugDumpApp()`, `debugDumpRenderTree()`, `debugDumpLayerTree()`, `debugDumpFocusTree()`, `debugDumpSemanticsTree()`.
- **Native debug**: build once (`flutter build ios --config-only --debug`, `flutter build appbundle --debug`, etc.), then attach Xcode/Android Studio/Visual Studio to the running Flutter process — both debuggers coexist.

### Error surfaces
- **`FlutterError.onError`** catches build/layout/paint errors. Call `FlutterError.presentError(details)` inside a custom handler to keep console output.
- **`PlatformDispatcher.instance.onError`** catches errors outside framework callbacks (async, MethodChannel). Must `return true` to mark handled.
- **`ErrorWidget.builder`** customizes the red/grey error widget via `MaterialApp.builder`.

### Top common errors
1. `RenderFlex overflowed` — wrap unconstrained child of `Row`/`Column` in `Expanded`/`Flexible`.
2. `Vertical viewport was given unbounded height` — wrap `ListView`/`GridView` in `Expanded`/`SizedBox` when inside a `Column`.
3. `InputDecorator ... cannot have an unbounded width` — wrap `TextField` in `Expanded`/`SizedBox` inside a `Row`.
4. `RenderBox was not laid out` — usually downstream of a constraint error; fix the root cause.
5. `Incorrect use of ParentDataWidget` — `Positioned` needs `Stack`; `Flexible`/`Expanded` need `Row`/`Column`/`Flex`.
6. `setState called during build` / `setState called after dispose` — defer with `WidgetsBinding.instance.addPostFrameCallback`, or guard with `if (mounted)`.
7. Red/grey "screen of death" — uncaught exception; read the console dump; customize via `ErrorWidget.builder`.
8. `ScrollController attached to multiple scroll views` — one controller per scrollable, or use `PrimaryScrollController`.
9. `MissingPluginException` — plugin not mocked in unit/widget test; wrap plugin and mock the wrapper, or set a `TestDefaultBinaryMessenger` handler.
10. `A Timer is still pending even after the widget tree was disposed` — cancel timers/streams in `dispose()`.

## Error reporting

Initialize handlers **before `runApp()`**. Three-pronged setup:

```dart
FlutterError.onError = (details) {
  FlutterError.presentError(details);
  Sentry.captureException(details.exception, stackTrace: details.stack);
};

PlatformDispatcher.instance.onError = (error, stack) {
  Sentry.captureException(error, stackTrace: stack);
  return true;
};

Isolate.current.addErrorListener(RawReceivePort((pair) {
  final [error, stack] = pair as List;
  Sentry.captureException(error, stackTrace: stack);
}).sendPort);
```

- **`runZonedGuarded`** wraps `runApp` to catch remaining uncaught async errors. With modern `PlatformDispatcher.onError` it's often redundant but Crashlytics docs still use it.
- **Crashlytics**: `FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;` and `PlatformDispatcher.instance.onError = (e, s) { FirebaseCrashlytics.instance.recordError(e, s, fatal: true); return true; };`.
- **Sentry**: `await SentryFlutter.init((o) => o.dsn = '...', appRunner: () => runApp(MyApp()));` — captures Flutter + async + native automatically. Manual: `Sentry.captureException(e, stackTrace: s)`.
- Pass DSN via `--dart-define` — don't hard-code secrets.
- Use `kReleaseMode` to gate behavior: send to backend in release, print to console in debug.
