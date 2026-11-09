---
name: scaffold-flutter-feature
description: Scaffold a complete Flutter feature module (domain, data, presentation, DI and tests) in the project's existing stack, detected from pubspec: GetX, BLoC or Riverpod. Follows Clean Architecture and the same 24 imperatives enforced by mobile-architecture-guard. Use when the user asks to "create a new Flutter feature", "scaffold a screen", "generate a feature module", or names a feature to build from scratch (e.g. "build a Profile feature", "add a Login screen").
argument-hint: [FeatureName] [optional: brief description of what it does]
---

# Scaffold Flutter Feature

Generates a production-ready, testable Clean Architecture feature module for Flutter — not a toy example. The generated code must pass `mobile-architecture-guard`, `mobile-security-guard`, `mobile-accessibility-guard`, and `mobile-tdd-guard` review with zero findings.

## Step 0 — Detect the project's stack before generating anything

Never introduce a second state-management or DI framework. Read `pubspec.yaml` and the existing feature folders:

```
grep -nE "^  (get|flutter_bloc|bloc|riverpod|flutter_riverpod|get_it|injectable|go_router):" pubspec.yaml
ls lib/features lib/app lib/modules 2>/dev/null
```

- `get:` present → **GetX variant**: controller + binding + GetPage, DI through `Bindings` (`Get.lazyPut`), reactive state with `Rx`/`Obx`.
- `flutter_bloc:` present → **BLoC variant**: bloc/event/state, DI through Injectable/GetIt or the project's existing container.
- `riverpod:` present → **Riverpod variant**: Notifier + providers, no separate DI container.
- Nothing present (brand-new app) → ask the user which stack they want; do not pick one silently.

Copy the folder layout the project already uses (feature folder name, file naming, where tests live). The tree below is the default only when the project has no features yet.

## Step 1 — Parse the argument

`$ARGUMENTS` gives the feature name (and optionally a short description). Convert it to PascalCase for classes and snake_case for file/folder names, e.g. `user profile` → `UserProfile` / `user_profile`.

If the description implies specific fields or actions, shape the domain entity and use cases around them. If no detail is given, generate a minimal Get + Update feature and say so explicitly — don't invent unrelated fields silently.

## Step 2 — Generate the full layer structure

Full code templates are in `references/dart-templates.md`; read it before generating if it exists in this installation (if it is missing, do not stop or report it: generate from the rules below). Default folder layout, BLoC variant:

```
lib/features/{name}/
├── domain/
│   ├── entities/{name}.dart
│   ├── repositories/{name}_repository.dart   (abstract class)
│   └── usecases/get_{name}_usecase.dart, update_{name}_usecase.dart
├── data/
│   ├── datasources/{name}_remote_datasource.dart, {name}_local_datasource.dart
│   ├── models/{name}_model.dart              (extends domain entity, adds fromJson/toJson)
│   └── repositories/{name}_repository_impl.dart
└── presentation/
    ├── bloc/{name}_bloc.dart, {name}_event.dart, {name}_state.dart
    └── pages/{name}_page.dart                (Widget, reads state only)

lib/core/di/
└── {name}_injection.dart                     (@module class registered with Injectable/GetIt)
```

GetX variant replaces the presentation and DI parts with:

```
    ├── controllers/{name}_controller.dart   (GetxController; holds Rx state; depends on use cases only)
    ├── bindings/{name}_binding.dart         (Bindings; Get.lazyPut for data sources, repository, use cases, controller)
    └── pages/{name}_page.dart               (GetView<{Name}Controller>; Obx/GetBuilder; no business logic)
```

and registers `GetPage(name: Routes.{name}, page: ..., binding: {Name}Binding())` in the existing pages list. Riverpod variant: `providers/{name}_providers.dart` + `notifiers/{name}_notifier.dart`.

Apply these rules while generating, matching `mobile-architecture-guard`'s imperatives:

- Domain layer has **zero** Flutter/http/sqflite imports — pure Dart only.
- Repository abstract class lives in `domain/`; implementation lives in `data/`.
- The state holder (BLoC, GetX controller or Notifier) depends on use cases, never directly on the repository or data sources.
- One state holder per feature/page; no wrapping one inside another for cross-cutting concerns; inject those as separate service dependencies via the constructor instead.
- State is immutable or reactive-but-owned: BLoC/Riverpod use `Equatable`/`freezed` states; GetX controllers expose `Rx` fields or `update()` and the widget never mutates them directly.
- GetX specifics: `Get.find` for repositories or data sources is allowed only inside the Binding, never inside a widget's `build`; controllers close streams and workers in `onClose`; no `Get.put` of data classes from widgets.

## Step 3 — Generate tests alongside the code, not after

- `domain/usecases/*_usecase_test.dart` — `mocktail`, fake/mock repository.
- `data/repositories/*_repository_impl_test.dart` — mock remote/local data sources.
- BLoC variant: `presentation/bloc/*_bloc_test.dart` with `bloc_test`, asserting the exact state sequence per event. GetX variant: `presentation/controllers/*_controller_test.dart` as plain Dart with `Get.testMode = true` and mocked use cases, asserting the Rx state after each action (no `bloc_test`). Riverpod variant: `ProviderContainer` tests on the Notifier.
- `presentation/pages/*_page_test.dart` — `flutter_test` widget test, asserts each state renders correctly and semantics labels exist for accessibility (`Semantics`/`tooltip`).

Full test templates are in `references/dart-templates.md` when present; otherwise follow mobile-tdd-guard. Tests must use the same mocking library the project already has (`mocktail` or `mockito`); do not add a second one.

## Step 4 — Security & accessibility, generated in, not bolted on

- If the feature touches tokens, PII, or credentials: use `flutter_secure_storage`, never plain `SharedPreferences`.
- Every interactive widget needs a `Semantics` label or accessible `tooltip`, and a minimum 48x48 logical-pixel tap target — non-negotiable per `mobile-accessibility-guard`.
- Respect existing RTL/Arabic layout conventions already established in this codebase (clean separation of Arabic/English text, correct `Directionality` handling) when generating any user-facing strings or layouts.

## Step 5 — Self-check before presenting the result

Before showing the generated files, verify against `mobile-architecture-guard`'s imperatives yourself and fix any violation silently. Then present:

1. A short summary of what was generated (files + what each layer does).
2. Any assumption you made in Step 1.
3. A one-line note suggesting the user still run `/mobile-engineering-skills:mobile-architecture-guard` before merging.
