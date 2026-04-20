# Performance & Optimization

Impeller, rendering budget, profiling, app size, isolates, anti-patterns.

## Impeller

- **iOS** — only engine. Cannot switch to Skia.
- **Android** — default on API 29+ with Vulkan. Falls back to legacy OpenGL otherwise. Disable with `flutter run --no-enable-impeller` or `AndroidManifest.xml` meta-data `io.flutter.embedding.android.EnableImpeller=false`.
- **macOS** — opt-in via `flutter run --enable-impeller` or `Info.plist` `FLTEnableImpeller=true` (opt-out being removed).
- **Web** — still Skia (CanvasKit/Skwasm); Impeller may come later.
- Shader jank on legacy Skia → switch to Impeller. Impeller compiles all shaders at build time — no runtime compile stutter, no shader warm-up needed. File issues prefixed `[Impeller]` with device/chip info + a DevTools trace export.

## Best practices (DO / DON'T)

- **DO** use `const` constructors everywhere possible. Enable `flutter_lints` to enforce.
- **DO** keep `setState()` local to the smallest subtree. Split large `build()` methods into smaller widgets.
- **DO** prefer `StatelessWidget` subclasses over helper functions returning widgets (enables const + rebuild short-circuit).
- **DON'T** override `operator ==` on widgets (O(N²) behavior). Exception: leaf widgets with significantly cheaper comparison.
- **DON'T** use `Opacity` — prefer `AnimatedOpacity`, `FadeInImage`, `FadeTransition`, or apply opacity directly to the image/color.
- **DON'T** clip during animations. Pre-clip. Prefer `borderRadius` over rectangle clipping.
- **DON'T** use `Clip.antiAliasWithSaveLayer` unless required (forces `saveLayer()`).
- **DON'T** call `saveLayer()` indirectly via `ShaderMask`, `ColorFilter`, `Chip`, or `Text` with `overflowShader` unless necessary. Detect via `PerformanceOverlayLayer.checkerboardOffscreenLayers`.
- **DO** precache images (`precacheImage`) and use placeholders.
- **DO** use `ListView.builder` / `GridView.builder` for long/large lists. Never pass a full `List` of children to `ListView()` when most are offscreen.
- **DO** pass the static subtree as `child:` to `AnimatedBuilder` so it isn't rebuilt every tick.
- **DO** fix cell sizes up front to avoid intrinsic passes. Enable DevTools "Track layouts" to spot them.
- **DO** push heavy async work off the UI thread via `compute()` / `Isolate.run`.

## App size

- Measure: `flutter build <apk|appbundle|ios|linux|macos|windows> --analyze-size`. Upload the generated `*-code-size-analysis_*.json` to DevTools "App size tool" for function-level treemap drill-down.
- **Android**: upload `.aab` to Play Console → Android vitals → App size for download/install size.
- **iOS**: `flutter build ipa --export-method development`. Distribute archive with "all compatible device variants" + "Strip Swift symbols". Inspect `App Thinning Size Report.txt`.
- Reduce: `--split-debug-info` for obfuscation + symbol removal. Platform-gated code (`if (Platform.isX)`) is tree-shaken on other platforms. Strip unused deps. Compress PNG/JPEG. Remove unused assets.
- **Never use debug builds for size comparison.**

## Deferred components (Android + Web)

- Android: requires `com.google.android.play:core:1.8.0`, `FlutterPlayStoreSplitApplication` in manifest, `PlayStoreDeferredComponentManager` injected via `FlutterInjector`.
- Only effective in release/profile. Debug treats deferred imports as regular.
- Dart: `import 'foo.dart' deferred as foo;` then `await foo.loadLibrary();`. Guard all usage behind the future.
- One loading unit per component. Assets may duplicate across components. Base component is implicit. List components in `pubspec.yaml` under `deferred-components:` and in `android/settings.gradle`.
- Assets-only components use `DeferredComponent` service utility, not `loadLibrary()`.

## Rendering performance

- **Frame budget**: 16.67ms at 60Hz (8.33ms at 120Hz). Aim ~8ms build + ~8ms render.
- **UI thread** runs Dart + builds layer tree. **Raster thread** hands layer tree to GPU via Impeller/Skia.
- Performance overlay: bottom graph = UI thread, top = raster thread. White lines = 16ms marks. Red bars = jank frames (last 300 shown).
- Red on UI graph → Dart too expensive. Red on raster graph → scene too complex. Both red → **fix UI first.**
- **`RepaintBoundary`** — wrap subtrees that repaint independently of their parents (complex static content beside a frequently-repainting sibling; individual cells in an animated list). Don't wrap everything — each boundary has memory/compositing cost.
- Shader warm-up is unnecessary on Impeller. Only legacy Skia needed it.

## Profiling

- Always measure in **`--profile` mode** (`flutter run --profile`, VS Code `flutterMode: profile`, or AS/IJ "Run in Profile Mode"). Debug mode numbers are meaningless.
- Open DevTools → Performance → enable Performance Overlay (or press `P` in terminal).
- Test on **lower-end target devices**, not just your dev machine.
- **Web** (Flutter ≥ 3.14): run in profile mode, use Chrome DevTools Performance panel. Optional `main()` flags: `debugProfileBuildsEnabled`, `debugProfileBuildsEnabledUserWidgets`, `debugProfileLayoutsEnabled`, `debugProfilePaintsEnabled`.
- Track widget rebuild storms with "Track widget rebuilds" (DevTools / IntelliJ).

## Metrics

- **`FrameTiming`**: `buildDuration`, `rasterDuration`, `totalSpan`. Log average, p90, p99, worst.
- **Startup**: `WidgetsBinding.instance.firstFrameRasterized` flag. Dashboard metric `timeToFirstFrameRasterizedMicros`.
- Custom timeline events via `dart:developer` `Timeline` / `TimelineTask`.
- App size metric: `release_size_bytes`.
- CPU/GPU energy: approximated via trace events (`profiling_summarizer.dart`).

## Concurrency & isolates

- One-shot heavy work → **`Isolate.run(() => ...)`**.
- Cross-platform (falls back to main thread on web) → **`compute(fn, msg)`**.
- Long-lived workers doing repeated computation → `Isolate.spawn` + `SendPort`/`ReceivePort`.
- **Good fits**: JSON decode, image/audio/video processing, DB reads, large list filtering, FFI async, push notifications.
- **CAN** cross an isolate: custom objects, `List`, `Map`, JSON, file bytes (copied); `String`, numbers, unmodifiable byte arrays, immutables (by reference). Transfer ownership via `Isolate.exit()` to avoid a copy.
- **CANNOT** cross: any `dart:ui` / widget / `rootBundle` access; file handles, socket connections, streams with active listeners; global mutable state (each isolate has its own copy).
- **Root-isolate only**: UI, painting, `rootBundle`, generating `RootIsolateToken`. Load assets in root; pass bytes/strings into the worker.
- **Background isolates + platform channels**: get `RootIsolateToken.instance!` in root, pass to spawn, then call `BackgroundIsolateBinaryMessenger.ensureInitialized(token)` in the worker before using plugins.
- Background isolates support query/response platform calls but **cannot** receive unsolicited host messages (e.g., Firestore push listeners won't work there).
- **Web has no isolate support** — `compute()` falls back to main thread.

## Common perf anti-patterns

- Heavy work inside `build()` → move out, cache results.
- `Opacity` / `ClipRect` / `ImageFilter` in animations → swap for animated variants or pre-composed assets.
- Unnecessary `saveLayer()` (direct or via `ShaderMask`, `Chip`, `ColorFilter`, `overflowShader`).
- `ListView(children: [...])` with many offscreen items → use `.builder`.
- `AnimatedBuilder` rebuilding unrelated subtrees → move them to `child:`.
- `setState()` at the top of the tree for a local change.
- Overriding `operator ==` on non-leaf widgets.
- Measuring in debug mode or only on flagship dev devices.
- Blocking UI thread with sync JSON parse / crypto / file I/O → offload via `compute()`.
- Large PNG/JPEG assets shipped uncompressed. Debug-info not split.
- Ignoring p99/worst frame time in favor of averages only.
