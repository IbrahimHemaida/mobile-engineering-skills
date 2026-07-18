---
name: integrate-flutter-feature
description: Wire a scaffolded Flutter feature into the rest of the app — router (GoRouter/Navigator), app-level Injectable/GetIt DI graph, pubspec.yaml dependencies, and a build/analyze verification pass. Use after scaffold-flutter-feature, or whenever the user says "wire this up", "connect this feature to the app", "add this to the router", or "make this feature actually runnable".
argument-hint: [FeatureName] [optional: entry point / where it should be reachable from]
---

# Integrate Flutter Feature

`scaffold-flutter-feature` produces an isolated, reviewable feature module. This skill makes it **actually runnable inside the app** — an integration pass into existing project files, not a second scaffolding pass.

## Step 1 — Inspect the existing project before touching anything

Detect what this project actually uses — never introduce a second competing router or DI framework alongside an existing one:

```
grep -rl "GoRouter\|go_router" lib/ pubspec.yaml       # GoRouter?
grep -rl "Navigator.push\|MaterialPageRoute" lib/        # plain Navigator 2.0/1.0?
grep -rl "@InjectableInit\|getIt.init" lib/               # confirms Injectable/GetIt setup
grep -n "^  bloc:\|^  flutter_bloc:" pubspec.yaml         # confirms BLoC is the state approach
```

If the project has **no** router or DI set up yet (brand-new app), set up GoRouter + Injectable minimally as the default, matching this codebase's established conventions (Riverpod/GetIt/Injectable, per prior project history) unless the user's existing code shows a different pattern already in place.

## Step 2 — Wire the router

Add the feature's route to the **existing** router config (don't create a parallel one). See `references/flutter-integration-templates.md` for the exact GoRouter route and BlocProvider wiring.

## Step 3 — Wire the DI graph

`@injectable`/`@LazySingleton` annotations from `scaffold-flutter-feature` are auto-discovered by `build_runner` — but you must actually run it, and it only picks up files that are part of the compiled `lib/` tree already:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Confirm the generated `injection.config.dart` now includes the new feature's registrations before moving on.

## Step 4 — Reconcile pubspec.yaml dependencies

Add **only what's missing** — don't duplicate or downgrade existing pinned versions:
- `flutter_bloc`, `equatable`
- `get_it`, `injectable`
- `dio` (or the project's existing HTTP client)
- `dartz` or `fpdart` (for `Either`/`Failure` — match whichever the project already uses)
- Test-only: `mocktail`, `bloc_test`

## Step 5 — Verify it actually builds

Non-negotiable per `mobile-architecture-guard`'s build-verification imperative:
```bash
flutter analyze
flutter test
```
If either fails, fix the wiring — don't hand the user a broken build with a note to "check it later."

## Step 6 — Present the result

Summarize: what was wired (route added, DI registrations confirmed via `build_runner`, pubspec deps added/skipped-because-present), the verification result, and how to actually reach the new screen (e.g. "tap Profile in the bottom nav" or "navigate to `/profile/:id`").
