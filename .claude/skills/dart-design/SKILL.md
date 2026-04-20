---
name: dart-design
description: Use when writing, reviewing, or refactoring Dart or Flutter code in this repo - condensed reference to the Effective Dart design rules covering names, libraries, classes, constructors, members, types, parameters, and equality
---

# Effective Dart: Design Rules

Condensed from https://dart.dev/effective-dart/design. Treat as the style baseline for all `.dart` files in this repo. When in doubt, fetch the canonical page for the full rationale and examples.

## Convention keywords

- **DO** — always follow
- **DON'T** — never do
- **PREFER** — follow unless you have a concrete reason
- **AVOID** — only do with a concrete reason
- **CONSIDER** — weigh it; judgment call

## Names

| | Rule |
|---|---|
| DO | Use terms consistently across the codebase. |
| AVOID | Abbreviations (except well-known ones like `id`, `num`, `ok`). |
| PREFER | Putting the most descriptive noun last: `pageCount`, not `numPages`. |
| CONSIDER | Making the call site read like a sentence. |
| PREFER | Noun phrase for non-boolean properties/variables. |
| PREFER | Non-imperative verb phrase for booleans: `isEmpty`, `canClose`. |
| CONSIDER | Omitting the verb for named boolean parameters: `Foo(hidden: true)`. |
| PREFER | The positive name: `isVisible` over `isHidden`. |
| PREFER | Imperative verb phrase for side-effectful functions: `print()`, `save()`. |
| PREFER | Noun/non-imperative phrase when the return value is the point: `list.length`, `text.toLowerCase()`. |
| CONSIDER | Imperative verb phrase when the work is the point: `table.sort()`. |
| AVOID | Starting a method name with `get`. Use a getter or drop the prefix. |
| PREFER | `toX()` when copying state into a new object: `list.toSet()`. |
| PREFER | `asX()` when the result is a view backed by the original: `list.asMap()`. |
| AVOID | Putting parameter descriptions in the function name: `addItem(x)`, not `addItemWithPriority(x, p)`. |
| DO | Follow mnemonic type-parameter conventions: `E` element, `K`/`V` key/value, `R` return, `T`/`S`/`U` generic. |

## Libraries

- **PREFER** making declarations private. Library-private (`_name`) is the default; export only what callers need.
- **CONSIDER** declaring multiple related classes in the same library so they can share private members.

## Classes and mixins

- **AVOID** a one-member abstract class when a function/typedef suffices.
- **AVOID** a class that contains only static members — use top-level functions/constants.
- **AVOID** extending a class not designed for it. **DO** use class modifiers (`final`, `base`, `sealed`, `interface`) to make intent explicit.
- **AVOID** implementing a class not designed as an interface. Use modifiers to control this too.
- **PREFER** a pure `mixin` or pure `class` over `mixin class` unless you specifically need both capabilities.

## Constructors

- **CONSIDER** making your constructor `const` when all fields are `final` and all initializers are constant — enables compile-time constant instances (important for widgets).

## Members

- **PREFER** `final` fields and top-level variables.
- **DO** expose conceptual properties as getters/setters, not methods.
- **DON'T** define a setter without a matching getter.
- **AVOID** runtime type tests (`is`) to simulate overloading — use distinct names or sealed types.
- **AVOID** public `late final` without an initializer (it leaks mutability to callers).
- **AVOID** returning nullable `Future`, `Stream`, or collection types — return the empty value instead.
- **AVOID** returning `this` just to chain calls. Dart has cascades (`..`) for that.

## Types

Type annotations — default to annotating boundaries, let inference handle locals.

| | Rule |
|---|---|
| DO | Annotate variables without initializers. |
| DO | Annotate fields and top-level variables when the type isn't obvious from the initializer. |
| DON'T | Redundantly annotate initialized locals: `var count = 0;` not `int count = 0;`. |
| DO | Annotate return types on function declarations. |
| DO | Annotate parameter types on function declarations. |
| DON'T | Annotate inferred parameters on function expressions/lambdas. |
| DON'T | Annotate initializing formals: `MyClass(this.x)`, not `MyClass(int this.x)`. |
| DO | Write type arguments on generic invocations that can't be inferred. |
| DON'T | Write type arguments when they are inferred. |
| AVOID | Incomplete generic types like raw `List` — use `List<Object?>` or `List<dynamic>` deliberately. |
| DO | Use `dynamic` explicitly rather than letting inference silently fail. |
| PREFER | Signatures in function type annotations: `void Function(int)` over bare `Function`. |
| DON'T | Specify a return type for a setter. |
| DON'T | Use the legacy `typedef Foo(int x);` syntax. Use `typedef Foo = void Function(int);`. |
| PREFER | Inline function types over one-off typedefs. |
| PREFER | Function-type syntax for parameters: `void onTap(String Function() label)`. |
| AVOID | `dynamic` unless you truly need to disable static checking. |
| DO | Return `Future<void>` from async members that produce no value. |
| AVOID | `FutureOr<T>` as a return type — it's fine as a parameter type, confusing as a result. |

## Parameters

- **AVOID** positional boolean parameters. Use named: `Dialog(barrierDismissible: true)` beats `Dialog(true)`.
- **AVOID** optional positional parameters when callers may want to skip earlier ones — use named.
- **AVOID** mandatory parameters that accept a sentinel "no argument" value — make them optional.
- **DO** use inclusive-start, exclusive-end for ranges: `list.sublist(0, 3)`.

## Equality

- **DO** override `hashCode` whenever you override `==`.
- **DO** obey the math: reflexive, symmetric, transitive, consistent, `x == null` is false.
- **AVOID** custom equality on mutable classes — breaks hash-based collections when state changes.
- **DON'T** make the parameter to `==` nullable: `bool operator ==(Object other)`.

## Common pitfalls in this repo

Watch for these when editing `lib/**/*.dart`:

- Widgets without `const` constructors on classes whose fields are all `final`.
- Setters lacking getters on model classes.
- `List<Item>?` returns where `const []` / `<Item>[]` would do.
- `get` prefixes on methods that aren't pure accessors.
- Positional `bool` flags at call sites — convert to named.

## Red flags — stop and rethink

- You're writing `class FooUtils` with only static methods → use top-level functions.
- You're adding `getFoo()` → make it a getter or rename without `get`.
- You're returning `Future<List<Foo>?>` → return `Future<List<Foo>>` with `const []` as empty.
- You're annotating `int count = 0;` → drop the `int`.
- You overrode `==` but not `hashCode` → add `hashCode` now.

## When this skill doesn't apply

- Generated files (`*.g.dart`, `*.freezed.dart`) — do not hand-edit.
- Third-party code under `build/` or `.dart_tool/`.
- Test files may relax the "annotate return types" rule for one-off helpers if local convention does.
