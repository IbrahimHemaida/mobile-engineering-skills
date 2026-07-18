---
name: integrate-android-feature
description: Wire a scaffolded Android/Kotlin feature into the rest of the app — navigation graph, app-level Hilt DI graph, Gradle module dependencies, and a build/compile verification pass. Use after scaffold-android-feature, or whenever the user says "wire this up", "connect this feature to the app", "add this to navigation", or "make this feature actually runnable".
argument-hint: [FeatureName] [optional: entry point / where it should be reachable from]
---

# Integrate Android Feature

`scaffold-android-feature` produces an isolated, reviewable feature module. This skill is what makes it **actually runnable inside the app** — not a second scaffolding pass, an integration pass into existing project files.

## Step 1 — Inspect the existing project before touching anything

Do not assume a navigation or DI pattern — detect what this project actually uses:

```
grep -rl "NavHost\|composable(" --include="*.kt" .    # Compose Navigation?
grep -rl "nav_graph.xml" .                              # Legacy Navigation Component?
find . -name "settings.gradle*"                         # multi-module or single-module?
grep -rl "@HiltAndroidApp" --include="*.kt" .            # confirms Hilt app graph entry point
```

If the project has **no** navigation or DI set up yet (a brand-new app), set it up minimally first — Compose Navigation + Hilt is the default unless the user's existing code shows otherwise. Never introduce a second competing DI framework or navigation library alongside an existing one.

## Step 2 — Wire navigation

Add the feature's route to the **existing** `NavHost` (don't create a parallel one). See `references/android-integration-templates.md` for the exact composable-destination and multi-module Gradle patterns.

If the project is multi-module, also add the feature module to `settings.gradle.kts` (`include(":feature:{name}")`) and as a dependency of the `:app` module.

## Step 3 — Wire the Hilt DI graph

The feature's `{Name}Module.kt` (from `scaffold-android-feature`) is `@InstallIn(SingletonComponent::class)`, which Hilt auto-discovers — no manual registration needed **if** the app module already depends on the feature module (multi-module) or the file is already in the compiled source set (single-module). Confirm this dependency edge exists; add it if missing.

## Step 4 — Reconcile Gradle dependencies

Check the feature's generated code against `build.gradle.kts` (or the version catalog `libs.versions.toml`) and add **only what's missing** — don't duplicate or downgrade existing pinned versions:
- Hilt, Hilt Navigation Compose
- Retrofit + a converter (Moshi/kotlinx.serialization)
- Room + Room KTX
- Compose Navigation
- Test-only: MockK, Turbine, `kotlinx-coroutines-test`, Compose UI test

## Step 5 — Verify it actually builds

This is non-negotiable per `mobile-architecture-guard`'s build-verification imperative: run the project's build/compile check (e.g. `./gradlew :app:compileDebugKotlin` or the module-specific equivalent) before presenting the result. If it fails, fix the wiring — don't hand the user a broken build with a note to "check compilation."

## Step 6 — Present the result

Summarize: what was wired (route added, module dependency added, Gradle deps added/skipped-because-present), the build verification result, and how to actually reach the new screen in the running app (e.g. "tap Profile in the bottom nav" or "navigate to `Routes.PROFILE`").
