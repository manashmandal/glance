# Platform Integration

Platform channels, FFI, and per-platform (Android/iOS/Web/Desktop) specifics.

## Platform channels & FFI

- **MethodChannel** — one-off async calls Dart ↔ native. Not type-safe. Default `StandardMessageCodec`. Wrap `invokeMethod` in try/catch for `PlatformException`.
- **EventChannel** — streaming/continuous events from platform to Flutter.
- **BasicMessageChannel** — simple async messaging with custom codecs when method semantics don't fit.
- **Pigeon** — preferred for complex/typed interactions. Eliminates string matching, supports nested classes, async wrappers, bidirectional. Use on any non-trivial project.
- **FFI (`dart:ffi`)** — direct C/C++ binding, synchronous, compile-time linked.
  - Scaffold: `flutter create --template=package_ffi` (Flutter 3.38+) with build hooks (`hook/build.dart`) instead of CMake/podspec/gradle.
  - Generate bindings with `package:ffigen`. Use `jnigen` for Java/Kotlin.
  - Same filename across architectures (no `_arm64` suffix). Same framework name across iOS device+simulator (no `_sim`). Identical Asset ID set across SDKs.
- **System libs** — `DynamicLibrary.process()` on Android/iOS/Linux/macOS; `DynamicLibrary.open()` for shipped libs; `DynamicLoadingSystem()` on Windows.
- **Threading** — channel calls hit the platform main/UI thread. Use `makeBackgroundTaskQueue()` (Android/iOS) for background handlers. From a background Dart isolate, call `BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken)` first.
- **Channel names must be unique.** Prefix with domain (e.g., `samples.flutter.dev/battery`).
- `StandardMessageCodec` supports: null, bool, int, double, String, typed byte lists, List, Map.
- **Web uses JS interop**, not platform channels.

## Android

- Supported: API 24–36, x64/Arm32/Arm64. Target API 36.
- **Splash screen**: Android 12+ uses `SplashScreen` API (`windowSplashScreenBackground`, `windowSplashScreenAnimatedIcon`). Pre-12 `windowBackground` pattern is deprecated. Define launch + normal themes in `styles.xml` + `NormalTheme` metadata. Normal-theme background should match the first Flutter frame to avoid flicker.
- **Predictive back**: API 33+. Requires `android:enableOnBackInvokedCallback="true"` in manifest, Flutter 3.22.2+, AND explicit opt-in via `PageTransitionsTheme` using `PredictiveBackPageTransitionsBuilder`. Still off by default on user devices.
- **Platform views**:
  - *Hybrid Composition* — best native fidelity, worst Flutter FPS. Some widget transforms break on platform views. Requires `minSdk = 19`.
  - *TLHC (Texture Layer Hybrid Composition)* — best Flutter perf, all transforms work. Breaks with fast scrolling, SurfaceViews, and text magnifier. Requires `minSdk = 20`.
  - SurfaceViews are problematic — prefer TextureView. Manually call `invalidate()` for non-auto-invalidating views. Use placeholder textures during animations.
- **Jetpack APIs**: search pub.dev first; else FFI (sync, efficient) via `jnigen`, or MethodChannel (always async) via Pigeon.
- **Sensitive content**: `SensitiveContent` widget obscures screen during media projection on API 35+. No effect on API 34-. Any one `sensitive` widget obscures the entire screen. `autoSensitive` not implemented as of 3.35.

## iOS

- Supported: iOS 13–26, Arm64 only.
- Setup: latest Xcode; `xcode-select`, `xcodebuild -runFirstLaunch`, `xcodebuild -license`; CocoaPods required; Rosetta 2 on Apple Silicon.
- **Launch screen**: `LaunchScreen.storyboard` is mandatory for App Store submission. Customize via `Runner/Assets.xcassets/LaunchImage`.
- **Platform views (`UiKitView`)**: hybrid composition only. Register factory in `AppDelegate` or plugin. `ShaderMask` and `ColorFiltered` unsupported on platform views. `BackdropFilter` limited.
- **Apple frameworks via pub.dev plugins** (prefer over rolling your own): `image_picker` (PhotoKit), `camera` (AVFoundation), `geolocator` (CoreLocation), `in_app_purchase` (StoreKit), `health` (HealthKit), `home_widget` (WidgetKit), `intelligence` (AppIntents/Siri).
- **Debug on device**: iOS 14+ requires accepting Local Network permission for hot-reload/DevTools (debug/profile only, not release).
- **Not yet implemented in Flutter** (as of docs date): Liquid Glass, eye tracking, hover typing, iOS formatting menu, iOS-style zoom page transition, iPad-style tab bar, iPhone mirroring, large content viewer, virtual trackpad, writing tools.

## Web

- **Renderers**:
  - *CanvasKit* (~1.5 MB) — default. All modern browsers. Single-threaded.
  - *Skwasm* (~1.1 MB) — Wasm mode only. Multi-threaded with `SharedArrayBuffer`. Needs WasmGC. Auto-falls back to CanvasKit when unsupported.
- **Wasm** (Flutter 3.24+): `flutter build web --wasm` / `flutter run -d chrome --wasm`. Requires WasmGC — Chrome 119+, Firefox 120+ (broken), Safari (bug). **All iOS browsers cannot run Wasm** (WebKit mandate).
- Wasm server headers for multi-threading: `Cross-Origin-Embedder-Policy: credentialless|require-corp` + `Cross-Origin-Opener-Policy: same-origin`.
- Wasm bans: `dart:html`, `package:js`, `dart:js`. Use `package:web` and `dart:js_interop`.
- Detect Wasm at compile time: `const bool.fromEnvironment('dart.tool.dart2wasm')`.
- **Doesn't work on web**: `dart:io`, `Platform.is` (use `kIsWeb` / `os_detect`), isolates (use web workers), SEO-heavy static content (use Jaspr). Browser owns HTTP headers — the server must send them.
- Embedding HTML: `HtmlElementView.fromTagName` (simple) or `registerViewFactory` from `dart:ui_web` (control). Full pages via `webview_flutter`.
- Browsers: Chrome/Edge latest 2 (JS+Wasm), Firefox latest 2 (JS only), Safari 15.6+ (JS only).

## Desktop (macOS / Linux / Windows)

- Enable: `flutter create --platforms=windows,macos,linux .`; disable with `flutter config --no-enable-windows-desktop` etc. Restart IDE after enabling.
- Run/build: `-d windows|macos|linux`; `flutter build windows|macos|linux`.
- **macOS**: Catalina 10.15 – Tahoe 26, x64+Arm64. Latest Xcode + CocoaPods required. Edit entitlements in `macos/Runner/*.entitlements` for sandbox/network.
- **Linux**: Ubuntu 20.04–24.04 LTS or Debian 10–12, x64+Arm64. Install `clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev` (GTK 3).
- **Windows**: Windows 10/11, x64+Arm64. Requires full Visual Studio (not VS Code) with "Desktop development with C++" workload (`Microsoft.VisualStudio.Workload.NativeDesktop`). Use the `win32` Dart package for Win32 APIs.
- Plugins follow federated architecture — coordinate with plugin authors before adding new platform support.
