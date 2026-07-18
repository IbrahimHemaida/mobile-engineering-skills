---
name: scaffold-flutter-feature
description: Scaffold a complete Flutter feature module (Domain, Data, Presentation layers, GetIt/Injectable DI, and full Unit + Widget tests) following Clean Architecture, BLoC, and the same 24 imperatives enforced by mobile-architecture-guard. Use when the user asks to "create a new Flutter feature", "scaffold a screen", "generate a feature module", or names a feature to build from scratch (e.g. "build a Profile feature", "add a Login screen").
argument-hint: [FeatureName] [optional: brief description of what it does]
---

# Scaffold Flutter Feature

Generates a production-ready, testable Clean Architecture feature module for Flutter — not a toy example. The generated code must pass `mobile-architecture-guard`, `mobile-security-guard`, `mobile-accessibility-guard`, and `mobile-tdd-guard` review with zero findings.

## Step 1 — Parse the argument

`$ARGUMENTS` gives the feature name (and optionally a short description). Convert it to PascalCase for classes and snake_case for file/folder names, e.g. `user profile` → `UserProfile` / `user_profile`.

If the description implies specific fields or actions, shape the domain entity and use cases around them. If no detail is given, generate a minimal Get + Update feature and say so explicitly — don't invent unrelated fields silently.

## Step 2 — Generate the full layer structure

Full code templates are in `references/dart-templates.md` — read it before generating. Folder layout:

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

Apply these rules while generating, matching `mobile-architecture-guard`'s imperatives:
- Domain layer has **zero** Flutter/http/sqflite imports — pure Dart only.
- Repository abstract class lives in `domain/`; implementation lives in `data/`.
- BLoC depends on use cases, never directly on the repository or data sources.
- One BLoC per feature/page — no wrapping a BLoC inside another BLoC for cross-cutting concerns; inject those as separate service dependencies via the constructor instead.
- State classes are immutable (`Equatable` or `freezed`); the widget dispatches events, never mutates state directly.

## Step 3 — Generate tests alongside the code, not after

- `domain/usecases/*_usecase_test.dart` — `mocktail`, fake/mock repository.
- `data/repositories/*_repository_impl_test.dart` — mock remote/local data sources.
- `presentation/bloc/*_bloc_test.dart` — `bloc_test` package, asserts the exact state sequence emitted per event.
- `presentation/pages/*_page_test.dart` — `flutter_test` widget test, asserts each state renders correctly and semantics labels exist for accessibility (`Semantics`/`tooltip`).

Full test templates are in `references/dart-templates.md`.

## Step 4 — Security & accessibility, generated in, not bolted on

- If the feature touches tokens, PII, or credentials: use `flutter_secure_storage`, never plain `SharedPreferences`.
- Every interactive widget needs a `Semantics` label or accessible `tooltip`, and a minimum 48x48 logical-pixel tap target — non-negotiable per `mobile-accessibility-guard`.
- Respect existing RTL/Arabic layout conventions already established in this codebase (clean separation of Arabic/English text, correct `Directionality` handling) when generating any user-facing strings or layouts.

## Step 5 — Self-check before presenting the result

Before showing the generated files, verify against `mobile-architecture-guard`'s imperatives yourself and fix any violation silently. Then present:
1. A short summary of what was generated (files + what each layer does).
2. Any assumption you made in Step 1.
3. A one-line note suggesting the user still run `/mobile-engineering-skills:mobile-architecture-guard` before merging.
