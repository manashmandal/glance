# App Architecture

Layering, UI/Data separation, dependency injection, and the official design patterns.

## Layering (UI → Domain → Data)

- Three layers: **UI → (optional) Domain → Data**. Dependencies point inward.
- UI depends on Domain and Data. Data depends only on Domain. Domain depends on nothing.
- **Unidirectional data flow**: state flows Data → ViewModel → View; events flow View → ViewModel → Repository.
- No circular deps. UI never touches services directly — always via a repository.
- Data layer never references UI. Data mutations happen only in the data layer (Single Source of Truth).
- Organize:
  - Data layer **by type**: `data/repositories/`, `data/services/`, `data/model/`.
  - UI layer **by feature**: `ui/<feature>/view_models/`, `ui/<feature>/widgets/`.
  - Domain **by shared models**: `domain/models/`.
- Shared widgets → `ui/core/`, not `/widgets`.

## UI layer (Views + ViewModels)

- **One View ↔ one ViewModel**; each pair = one feature (usually a screen).
- View constructor accepts only `key` and its `viewModel`.
- Views MAY: render state, attach VM callbacks to gestures, use `ListenableBuilder`, hold simple if/layout/animation/routing logic.
- Views MUST NOT: hold business logic, call repositories/services, or mutate app state.
- ViewModels extend `ChangeNotifier` (default). Riverpod/BLoC/Signals are acceptable alternatives that must obey the same rules.
- ViewModels expose state as **immutable getters** (no setters). Wrap lists in `UnmodifiableListView`. Prefer `@freezed` for state classes.
- Repositories injected into a VM are **private fields** (`_repo`). Never public.
- Call `notifyListeners()` in `finally` blocks after async work so views update on both success and error.
- A VM may depend on **many repositories** — but never on another VM or on a View.
- Async user actions → **Command pattern**: commands are named VM members initialized in the constructor, exposing `running`/`completed`/`error`.

## Data layer (Repositories + Services)

- **Repository = single source of truth for one data type.** Only place that mutates that data.
- Repositories transform API models into **domain models** before exposing them. Return `Future`/`Stream` of domain models, wrapped in `Result<T>`.
- Repositories own caching, retries, polling, offline sync, and error handling.
- Repositories hold services as **private** fields so UI cannot bypass them.
- **Repositories never know about other repositories** — combine cross-repo data in the VM or a use-case.
- **Services are stateless**, side-effect-free, one per external data source (HTTP API, platform plugin, local file). Return **raw API models**.
- Services contain no business logic and are never called by VMs or Views directly.
- Both repositories and services return `Result<T>`; repositories wrap thrown exceptions in `Result.error(e)`.
- Prefer **abstract repository classes** so implementations can swap per environment (dev/staging/prod).
- Add a domain layer / use-cases only when logic spans multiple repositories, repeats across VMs, or is exceptionally complex.

## Dependency injection

- Use **`package:provider`** (Google-recommended).
- Compose at the top of the tree with `MultiProvider` in `main.dart`.
- Order: services → repositories (reading services via `context.read()`) → app-scoped `ChangeNotifierProvider`s.
- Screen-level VMs: create in the **`go_router` route builder**, reading repos via `context.read()`.
- **Constructor injection only.** Dependencies stored as `final` private fields. No globals, no singletons fetched inside classes.
- Scoping rule of thumb: View sees only its VM; VM sees repos; repo sees services; service sees nothing else in the app.
- Multiple entry points (`main_development.dart`, `main_staging.dart`, `main.dart`) for environment-specific wiring.

## Design patterns

- **MVVM** — default UI pattern. View renders, ViewModel holds UI logic + state, Model = repositories/services/domain.
- **Repository** — abstracts a data type; SSOT for that data.
- **Service** — thin stateless wrapper around one external API/data source.
- **Command** — wraps async VM methods, exposes `running`/`completed`/`error` without lifecycle bugs. Use for every user-triggered async action.
- **Result** — return `Result<T>` instead of throwing across layer boundaries; forces explicit error handling.
- **Optimistic state** — update UI immediately, reconcile with backend. Use for latency-sensitive mutations.
- **Offline-first** — combine local cache + remote in the repository so the UI is source-agnostic.
- **Key-value store** — small persistent prefs/config.
- **SQL / persistent storage** — relational on-device data, behind a repository.

## Recommendations (condensed)

**Strongly recommended:**
- Clear UI/Data split; Repository pattern in data layer; MVVM in UI layer.
- No logic in widgets; unidirectional data flow; immutable data models.
- Dependency injection; abstract repository classes.
- Unit-test every service/repo/VM. Widget-test every view.
- Use **fakes** (not mocks) for layer boundaries.

**Recommended:**
- `ChangeNotifier`/`Listenable` for widget updates.
- `Command` pattern for user events.
- `freezed` / `built_value` for immutable models.
- `go_router` for navigation.
- Naming: `HomeScreen`, `HomeViewModel`, `UserRepository`, `ClientApiService`.

**Conditional:**
- Add a domain/use-case layer only when VMs get crowded or logic repeats.
- Separate API vs domain models for large apps.

**Never:**
- Access the data layer from a widget.
- Let a repo know about another repo.
- Mutate data outside its owning repository.
- Expose a VM's repo as public.
- Mock the component under test.
- Put business logic in a service.
