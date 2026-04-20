# Packages & Plugins

Using, authoring, Swift Package Manager, and the Flutter Favorites program.

## Using packages

- Prefer **caret ranges** over exact pins: `^5.4.0` expands to `>=5.4.0 <6.0.0`. Use explicit ranges `>=5.4.0 <6.0.0` only when you need tighter control.
- **Avoid exact versions** (`'5.4.3'`) — they maximize collision risk across a dep graph.
- `dependencies:` ships with the app. `dev_dependencies:` is test/tooling only and not shipped.
- Add/remove via CLI: `flutter pub add <pkg>`, `flutter pub remove <pkg>`. Otherwise edit `pubspec.yaml`, then `flutter pub get`.
- Unpublished deps: `path:` (local), `git: { url, ref, path }` (branch/tag/commit + optional subdir), SSH URLs for private repos.
- `dependency_overrides:` — use only to resolve incompatible transitive version ranges locally. **Never in published packages** (it's ignored by consumers).
- Android-native conflicts → force versions via Gradle `resolutionStrategy`. CocoaPods has no override — pick compatible plugin versions instead.
- Commit `pubspec.lock` for **apps**.
- `flutter pub upgrade` bumps to the max allowed by constraints (distinct from `flutter upgrade`).
- After changing native plugin code, **hot reload is insufficient** — full restart required or you get `MissingPluginException`.

## Authoring packages

- Pick the narrowest type:
  - **Dart package** — pure Dart, no Flutter framework.
  - **Flutter package** — uses the framework, no platform code.
  - **Plugin** — Dart + platform code.
  - **FFI package** — native code via `dart:ffi` (`flutter create --template=package_ffi`).
- Scaffold: `flutter create --template=plugin --platforms=android,ios,... -a kotlin -i swift <name>`.
- Declare platforms in `pubspec.yaml` under `flutter.plugin.platforms` with `pluginClass` (native) and/or `dartPluginClass` (Dart-only with static `registerWith()`).
- **Federated plugin layout**:
  1. App-facing package (public API consumers import).
  2. Platform interface package (abstract class that implementations extend).
  3. Per-platform implementation packages.
  - Mark implementations with `flutter.plugin.implements: <app_facing>`.
  - Endorsed: app-facing package depends on the platform impl and lists it as `default_package`.
  - Non-endorsed: consumer must add the impl manually (use for overrides).
- **Platform interface rules**:
  - Implementations should `extends` the base class (not `implements`) so adding methods isn't a breaking change.
  - Any signature change to the interface is a **major semver bump**.
- **iOS + macOS shared code**: set `sharedDarwinSource: true` on both platforms (Flutter ≥ 3.7), put code in `darwin/`.
- Ship `README.md`, `CHANGELOG.md`, `LICENSE` (multi-license files separated by 80 hyphens). `dart doc` generates API docs. Validate with `flutter pub publish --dry-run` before `flutter pub publish`. **Publishes are permanent.**
- iOS privacy manifest: add `PrivacyInfo.xcprivacy` as a `resource_bundles` entry in the podspec.

## Swift Package Manager

### For app developers
- Enable: `flutter config --enable-swift-package-manager`. Then `flutter run` triggers auto-migration.
- Per-project opt-out: `flutter.config.enable-swift-package-manager: false` in `pubspec.yaml`.
- CocoaPods coexists as fallback. **Add-to-app is unsupported.**
- Removal: disable SPM → `flutter clean` → delete `FlutterGeneratedPluginSwiftPackage` from Xcode deps and the "Prepare Flutter Framework Script" pre-action.
- OS-mismatch errors: raise Xcode Minimum Deployments, then `flutter build ios --config-only`.

### For plugin authors
- **Ship both SPM and CocoaPods.** SPM-only breaks pre-migration apps; CocoaPods-only breaks migrated apps.
- Layout: `ios/<plugin>/Package.swift` + `Sources/<plugin>/` (Obj-C public headers under `include/<plugin>/`). Library name replaces `_` with `-`.
- Minimum platforms in `Package.swift`: `.iOS("13.0")`, `.macOS("10.15")`. Declare `FlutterFramework` dep (Flutter ≥ 3.41, Dart ^3.11).
- Resources: `resources: [.process("PrivacyInfo.xcprivacy")]`. Access via `Bundle.module` (Swift) or `SWIFTPM_MODULE_BUNDLE` guarded by `#if SWIFT_PACKAGE` (Obj-C).
- Keep podspec `source_files` / `public_header_files` / `resource_bundles` in sync with new paths. Pigeon outputs must target the new `Sources/` paths.
- Default linking is dynamic (Apple-recommended). Avoid `type: .static`.
- Test both: `pod lib lint ... --use-modular-headers` and `flutter run` with SPM enabled. Add `.build/` and `.swiftpm/` to `.gitignore`.

## Flutter Favorites

- Curated pub.dev packages vetted by the Flutter Ecosystem Committee on license, score, docs, feature-completeness, verified publisher, and runtime quality.
- Use as a first-pick shortlist — **not** a quality guarantee.
