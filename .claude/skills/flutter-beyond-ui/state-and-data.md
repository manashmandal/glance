# State & Data

State management, networking, serialization, persistence, and backend integration.

## State management

- **Ephemeral** (single-widget, simple, not serialized) → `StatefulWidget` + `setState()`.
- **App state** (shared, persisted, cross-widget) → a state management package (Provider, Riverpod, BLoC, Signals, etc.).
- `UI = f(state)` — never call imperative widget methods (`widget.setText()`); change state, rebuild.
- **Lift state up** only as high as all consumers need it — no higher. Don't store shared state in leaf widgets.
- Rebuilding is cheap. Prefer constructing a new widget with new data over mutating.
- `ChangeNotifier` + `notifyListeners()` is the baseline; `ChangeNotifierProvider` / `MultiProvider` exposes it.
- Put `Consumer<T>` **deep** in the tree to minimize rebuild scope. Use the `child:` parameter to cache unchanged subtrees.
- One-shot reads inside callbacks → `Provider.of<T>(context, listen: false)` (or `context.read<T>()`).
- Built-ins: `ValueNotifier`, `InheritedWidget`, `InheritedModel`.
- State is **not** restored across platform restart by default — persist explicitly.

## Networking

- Use the `http` package. Avoid `dart:io`/`dart:html` directly.
- Android: `<uses-permission android:name="android.permission.INTERNET"/>` in manifest. macOS: `com.apple.security.network.client` entitlement.
- **Never call fetch inside `build()`**. Kick off in `initState()` (or `didChangeDependencies()` if you need inherited widgets). Cache the `Future` in a state field.
- `FutureBuilder` branches: `snapshot.hasError` → error UI; `snapshot.hasData` → data UI; else loading.
- Always check `response.statusCode`. `throw Exception('...')` on non-success (including 404). Returning `null` will not trigger `snapshot.hasError`.
- POST JSON: `headers: {'Content-Type': 'application/json; charset=UTF-8'}`, body via `jsonEncode(...)`. Expect 201 on create.
- Auth: `{HttpHeaders.authorizationHeader: 'Basic <token>'}`. Never hardcode tokens — use env vars or secure storage.
- WebSockets: `web_socket_channel` → `WebSocketChannel.connect(Uri.parse('wss://...'))`. Read via `StreamBuilder(stream: channel.stream, ...)`, write via `channel.sink.add(...)`, **always `channel.sink.close()` in `dispose()`**.

## Serialization

- Small/POC: hand-written `fromJson`/`toJson` with `dart:convert`.
- Medium+: `json_serializable` + `json_annotation` + `build_runner`.
- Always cast explicitly: `json['name'] as String`. Untyped access defers typos to runtime.
- For nested models with codegen, annotate with `@JsonSerializable(explicitToJson: true)` or nested `toJson()` is skipped (you'll get `"Instance of 'Address'"` in the output).
- Useful annotations: `@JsonKey(name: ...)`, `defaultValue`, `required: true`, `ignore: true`. Class-level `fieldRename: FieldRename.snake` for snake_case APIs.
- During dev: `dart run build_runner watch --delete-conflicting-outputs`.
- **Never parse large JSON on the main isolate.** If parsing may exceed 16ms, offload with `compute(parseFn, response.body)`.
- `compute` rules: function must be top-level or static (no closures), single argument, message must be primitive-ish. Pass `response.body` (String), not `http.Response`.
- Heavier background work: `worker_manager`, `workmanager`.

## Persistence

### shared_preferences
- Key-value, primitives + `List<String>`. No complex objects, no large blobs.
- No guarantee of cross-restart durability on all platforms.
- Getter throws on type mismatch.
- Testing: `SharedPreferences.setMockInitialValues({...})`.

### Files (path_provider + dart:io)
- `getApplicationDocumentsDirectory()` for app-lifetime data.
- `getTemporaryDirectory()` for cache (system may purge).
- **Not supported on web.** Wrap reads in try/catch.

### SQLite (sqflite + path)
- Mobile/desktop only, no web.
- Call `WidgetsFlutterBinding.ensureInitialized()` before opening.
- Use `join()` to build paths. Specify `version` + `onCreate`.
- **CRITICAL**: never interpolate into `where` strings. Always `where: 'id = ?', whereArgs: [id]` — prevents SQL injection and type issues.
- `ConflictAlgorithm.replace` on `insert` for upserts.
- Define `id INTEGER PRIMARY KEY` for performant updates.
- Typed schema + migrations: consider `drift`.

## Firebase & Google APIs

- Use official FlutterFire plugins (Auth, Firestore, Storage, Crashlytics, Remote Config, Hosting).
- Configure with `flutterfire_cli`.
- Google APIs → `googleapis` + `google_sign_in` + `extension_google_sign_in_as_googleapis_auth`.
- **Only call user-data APIs (Calendar, Gmail, YouTube, Drive) from the client.** Never embed service-account credentials — proxy those through a backend.
- Typical flow: enable API in Cloud Console → `GoogleSignIn.instance.initialize()` → request scopes (silent `authorizationForScopes()` or interactive `authorizeScopes()`) → `authorization.authClient(scopes: ...)` → pass to API constructor.
- Returning users: `attemptLightweightAuthentication()`. Subscribe to `authenticationEvents` for sign-in state.
