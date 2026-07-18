---
name: scaffold-android-feature
description: Scaffold a complete Android/Kotlin feature module (Domain, Data, Presentation layers, Hilt DI, and full Unit + Compose UI tests) following Clean Architecture, MVVM, and the same 24 imperatives enforced by mobile-architecture-guard. Use when the user asks to "create a new Android feature", "scaffold a screen", "generate a feature module", or names a feature to build from scratch (e.g. "build a Profile feature", "add a Login screen").
argument-hint: [FeatureName] [optional: brief description of what it does]
---

# Scaffold Android Feature

Generates a production-ready, testable Clean Architecture feature module for Android/Kotlin — not a toy example. The generated code must pass `mobile-architecture-guard`, `mobile-security-guard`, `mobile-accessibility-guard`, and `mobile-tdd-guard` review with zero findings.

## Step 1 — Parse the argument

`$ARGUMENTS` gives the feature name (and optionally a short description of its behavior). Convert it to PascalCase for class names and camelCase/kebab-case for packages/files, e.g. `user profile` → `UserProfile` / `userprofile`.

If the description implies specific data fields or actions (e.g. "Profile feature with name, email, avatar, and a save button"), use those to shape the domain model and use cases. If no detail is given, generate a sensible minimal CRUD-style feature (Get + Update) and say so explicitly in your summary — do not silently invent unrelated fields.

## Step 2 — Generate the full layer structure

Full code templates with placeholders are in `references/kotlin-templates.md` — read it before generating. Package layout:

```
feature{name}/
├── domain/
│   ├── model/{Name}.kt
│   ├── repository/{Name}Repository.kt      (interface only)
│   └── usecase/Get{Name}UseCase.kt, Update{Name}UseCase.kt
├── data/
│   ├── remote/{Name}Api.kt, {Name}Dto.kt
│   ├── local/{Name}Dao.kt, {Name}Entity.kt   (Room)
│   ├── mapper/{Name}Mapper.kt                (DTO/Entity <-> domain model)
│   └── repository/{Name}RepositoryImpl.kt
├── presentation/
│   ├── {Name}UiState.kt                      (sealed interface)
│   ├── {Name}ViewModel.kt                    (StateFlow, UDF pattern — see the state-management reference material inside mobile-architecture-guard's skill folder for the full worked example)
│   └── {Name}Screen.kt                       (Composable, reads state only)
└── di/
    └── {Name}Module.kt                       (Hilt @Module, @InstallIn(SingletonComponent::class))
```

Apply the same rules `mobile-architecture-guard` enforces while generating (don't wait for a later review pass to catch these):
- Domain layer has **zero** Android/Compose/Retrofit/Room imports.
- Repository interface lives in `domain/`; implementation lives in `data/`.
- ViewModel depends on use cases, never directly on repository or data sources.
- One ViewModel per screen — no wrapping a ViewModel inside another ViewModel for cross-cutting concerns (analytics, logging); pass those as constructor-injected service interfaces instead.
- UI State is a sealed interface/class (`Loading`, `Success`, `Error`), not a mutable data class the UI can write to.

## Step 3 — Generate tests alongside the code, not after

For every file in Step 2, generate its test in the same pass:
- `domain/usecase/*UseCaseTest.kt` — JUnit, fake repository, no mocking framework needed for simple cases.
- `data/repository/*RepositoryImplTest.kt` — MockK for remote/local data sources.
- `presentation/*ViewModelTest.kt` — Turbine for StateFlow assertions, fake use cases.
- `presentation/*ScreenTest.kt` — Compose UI test (`createComposeRule`), asserts each UI state renders correctly and semantics are present for accessibility.

Full test templates are in `references/kotlin-templates.md`.

## Step 4 — Security & accessibility, generated in, not bolted on

- If the feature touches tokens, PII, or credentials: use `EncryptedSharedPreferences` or Keystore-backed storage, never plain `SharedPreferences`. Flag this explicitly in your summary if the feature doesn't need it, so the user knows you considered it.
- Every interactive Composable needs a `contentDescription` or `semantics` block and a minimum 48dp touch target — this is non-negotiable per `mobile-accessibility-guard`.

## Step 5 — Self-check before presenting the result

Before showing the generated files, verify against `mobile-architecture-guard`'s imperatives yourself and fix any violation silently — don't ask the user to run the guard separately for something you can catch now. Then present:
1. A short summary of what was generated (files + what each layer does).
2. Any assumption you made in Step 1 (e.g. "no fields specified, generated minimal Get/Update use cases").
3. A one-line note suggesting the user still run `/mobile-engineering-skills:mobile-architecture-guard` before merging, as a second pair of eyes.
