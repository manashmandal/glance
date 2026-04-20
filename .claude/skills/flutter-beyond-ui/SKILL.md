---
name: flutter-beyond-ui
description: Use when writing, reviewing, architecting, testing, or optimizing Flutter/Dart code beyond pure UI widgets — covers state management, data/backend, app architecture, platform integration (Android/iOS/Web/Desktop), packages & plugins, testing & debugging, and performance/isolates per the official flutter.dev "Beyond UI" docs
---

# Flutter: Beyond UI

Condensed from https://docs.flutter.dev — the Beyond UI sections. This SKILL.md is the index + cross-cutting rules. Open the topic file in this directory for detail when working in that area.

## Topic detail files

| Topic | File | Open when |
|---|---|---|
| State & data | `state-and-data.md` | Fetching/parsing/persisting data; choosing state management |
| Architecture | `architecture.md` | Structuring features, layering, DI, ViewModels/Repositories |
| Platforms | `platforms.md` | MethodChannel/FFI/Pigeon; platform views; Android/iOS/Web/Desktop specifics |
| Packages | `packages.md` | Adding deps, editing `pubspec.yaml`, authoring a plugin, SPM |
| Testing | `testing.md` | Writing/running tests, plugin mocking, debugging, error reporting |
| Performance | `performance.md` | Jank, frame time, app size, isolates, `compute()`, Impeller |

Also applies in this repo: the companion `dart-design` skill for names/types/equality rules.

## Top cross-cutting rules

1. **`UI = f(state)`** — change state; never mutate widgets imperatively.
2. **`const` everywhere possible** — constructors, literals. Let `flutter_lints` enforce.
3. **Unidirectional data flow**: View → ViewModel → Repository → Service; state flows back the other way.
4. **No business logic in widgets.** Widgets render; ViewModels decide; Repositories fetch/mutate.
5. **Prefer named parameters**, especially for booleans.
6. **Never parse large JSON on the root isolate** — `compute()` / `Isolate.run()`.
7. **Profile in `--profile` mode, not debug.** Debug numbers are meaningless.
8. **16.67ms frame budget** at 60Hz: ~8ms build, ~8ms raster. 8.33ms at 120Hz.
9. **Install global error handlers before `runApp()`**: `FlutterError.onError` + `PlatformDispatcher.instance.onError`.
10. **Caret version constraints** (`^1.2.3`) in `pubspec.yaml`. Commit `pubspec.lock` for apps.
11. **Dependencies point inward**: UI → Domain → Data. Data layer never references UI.
12. **Single source of truth per data type** = one repository. Mutations happen only there.
13. **Constructor injection, no globals.** Compose with `MultiProvider` at the app root.
14. **Fakes for cross-layer collaborators; mocks for interaction verification.** Never mock the component under test.
15. **One pump strategy per scenario**: `pumpWidget` once, `pump()` for frames, `pump(Duration)` for timers, `pumpAndSettle()` only with finite animations.

## Red flags — stop and rethink

- HTTP/DB inside `build()` → move to `initState()`, cache the `Future`.
- Overriding `==` on a non-leaf widget → O(N²) rebuilds.
- `Opacity` / `ShaderMask` / `ClipRect` inside an animation → use `Animated*` variants or pre-composed assets.
- `ListView(children: [longList])` → use `ListView.builder`.
- Widget file importing a service or plugin directly → route through a Repository.
- `MissingPluginException` in a unit/widget test → wrap the plugin, mock the wrapper.
- SQL built with string interpolation → use `where: '... = ?', whereArgs: [...]`.
- `pumpAndSettle()` hanging → you have an infinite animation; switch to `pump(Duration)`.
- Service exposed as a public field on a ViewModel → make it private.
- Repository depending on another repository → combine in ViewModel or a use-case.
- Debug build for perf measurement → rerun with `--profile`.
- `dependency_overrides` in a published package → only valid in apps.
- Data access from a `StatelessWidget` / `StatefulWidget` directly → thread through VM + Repo.

## When this skill doesn't apply

- Pure UI composition (layouts, animations, widget catalog) — use the standard widget docs.
- Generated files (`*.g.dart`, `*.freezed.dart`) — never hand-edit.
- Third-party code under `build/`, `.dart_tool/`, `Pods/`, `linux/flutter/`, etc.
- Project-specific conventions in this repo — cross-check `DESIGN.md` and neighboring code first.
