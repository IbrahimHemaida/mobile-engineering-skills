---
name: integrate-flutter-feature
description: Wire a scaffolded Flutter feature into the app using the project's existing router and DI (GetX pages and bindings, GoRouter plus Injectable/GetIt, or Riverpod), reconcile pubspec.yaml, and verify with analyze plus the affected tests. Use after scaffold-flutter-feature, or whenever the user says "wire this up", "connect this feature to the app", "add this to the router", or "make this feature actually runnable".
argument-hint: [FeatureName] [optional: entry point / where it should be reachable from]
---

# Integrate Flutter Feature

`scaffold-flutter-feature` produces an isolated, reviewable feature module. This skill makes it **actually runnable inside the app** — an integration pass into existing project files, not a second scaffolding pass.

## Step 1 — Inspect the existing project before touching anything

Detect what this project actually uses — never introduce a second competing router or DI framework alongside an existing one:

```
grep -nE "^  (get|flutter_bloc|riverpod|flutter_riverpod|get_it|injectable|go_router):" pubspec.yaml
grep -rl "GetMaterialApp\|GetPage\|Bindings" lib/          # GetX routing + bindings?
grep -rl "GoRouter\|go_router" lib/                       # GoRouter?
grep -rl "Navigator.push\|MaterialPageRoute" lib/        # plain Navigator?
grep -rl "@InjectableInit\|getIt.init" lib/               # Injectable/GetIt?
```

The stack you find decides every step below. If the project has **no** router or DI yet (brand-new app), ask the user which stack they want before adding one; do not default to a framework.

## Step 2 — Wire the router

Add the feature's route to the **existing** router config (don't create a parallel one):

- **GetX**: add `GetPage(name: Routes.{name}, page: () => const {Name}Page(), binding: {Name}Binding())` to the existing pages list and the route constant to the existing routes file; navigate with `Get.toNamed`.
- **GoRouter**: add the `GoRoute` and wrap the page in the project's provider (BlocProvider or Riverpod scope) the way neighbouring routes do.
- **Plain Navigator**: add the named route to the existing `routes`/`onGenerateRoute` map.

See `references/flutter-integration-templates.md` for the exact snippets when it exists in this installation; if it is missing, follow a neighbouring route in the codebase instead.

## Step 3 — Wire the DI graph

- **GetX**: the Binding on the GetPage is the DI module. Confirm every `Get.find<X>()` the controller and page use is registered in that Binding (or in an app-level initial binding); no `build_runner` needed.
- **Injectable/GetIt**: `@injectable`/`@LazySingleton` annotations are discovered by `build_runner`, which you must run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Confirm the generated `injection.config.dart` includes the new registrations.

- **Riverpod**: confirm providers are reachable from the app's `ProviderScope` and overridden in tests.

## Step 4 — Reconcile pubspec.yaml dependencies

Add **only what's missing for the detected stack**; never add a second state-management, DI or mocking package, and never downgrade a pinned version:

- GetX project: nothing beyond `get`; BLoC project: `flutter_bloc`, `equatable`, `get_it`, `injectable`; Riverpod project: `flutter_riverpod`.
- HTTP client, `Either`/`Failure` library and mocking library: whichever the project already uses.

## Step 5 — Verify it actually builds

Non-negotiable per `mobile-architecture-guard`'s build-verification imperative:

```bash
flutter analyze
flutter test <the feature's test folder and the router/DI tests> --concurrency=4
```

Run the full suite only when the project's gate rule calls for it (shared code touched, or the final gate before push), using the exact CI command. Send output to a log file and read the tail. If anything fails, fix the wiring; don't hand the user a broken build with a note to "check it later."

## Step 6 — Present the result

Summarize: what was wired (route added, DI registrations confirmed via `build_runner`, pubspec deps added/skipped-because-present), the verification result, and how to actually reach the new screen (e.g. "tap Profile in the bottom nav" or "navigate to `/profile/:id`").
