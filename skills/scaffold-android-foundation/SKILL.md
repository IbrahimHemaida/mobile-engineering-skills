---
name: scaffold-android-foundation
description: Scaffold the app-wide foundation an Android/Kotlin app needs before any feature is built — design system (colors, typography, spacing, light/dark theme, glass-effect nav bar), localization, a shared reusable component library, a core network/data layer, a central constants file, responsive layout support, and a hardened .gitignore. Use once, early in a project, before scaffold-android-feature. Use when the user asks to "set up the app foundation", "add theming/dark mode", "set up localization", "add a shared component library", or "set up the core layer".
argument-hint: [optional: brand color hex, e.g. "#0A84FF"]
---

# Scaffold Android Foundation

Generates the shared infrastructure that every feature module depends on. Run this **once**, early — `scaffold-android-feature` assumes this foundation already exists (it imports from `core/`, uses `AppTheme`, `Dimens`, and the shared component library).

Full code templates are in `references/android-foundation-templates.md` — read it before generating.

## Step 1 — Design system (`core/designsystem/`)

- **Color.kt**: a `ColorScheme` (Material 3) for light and dark, generated from the brand seed color in `$ARGUMENTS` if given, else a sensible default. Support Android 12+ dynamic color as an opt-in, but the brand palette is the default so the app doesn't look generic.
- **Type.kt**: `Typography` object following Material 3 type scale (display/headline/title/body/label × large/medium/small) — don't hardcode font sizes inline anywhere else in the app after this exists.
- **Dimens.kt**: spacing scale following the 4dp grid Material Design specifies (4, 8, 12, 16, 24, 32, 48dp) and the 48dp minimum touch target — this is what `mobile-accessibility-guard` will check generated features against, so get it right here once.
- **Theme.kt**: wires `MaterialTheme` with the above, plus a `LocalAppDimens` composition local so `Dimens.spacingMedium` is available anywhere via `MaterialTheme` the same way colors are.
- **Glass nav bar**: a `NavigationBar` using a translucent/blurred surface (via the `Haze` library or `RenderEffect`-based blur on Android 12+, with a solid-surface fallback below) — colors still pulled from the same `ColorScheme`, so it reads as "this app's nav bar," not a generic glass effect pasted on top.

## Step 2 — Localization (`core/localization/`)

- `strings.xml` for the default locale plus at least an Arabic `values-ar/strings.xml` scaffold (matching this project's established RTL/Arabic conventions) — never hardcode user-facing strings in Composables after this exists.
- `LocaleManager.kt` wrapping `AppCompatDelegate.setApplicationLocales` for in-app language switching without a restart.
- Confirm RTL layout mirroring works by default (Compose mirrors automatically for `LayoutDirection.Rtl` — verify, don't assume).

## Step 3 — Shared component library (`core/ui/components/`)

- `ShimmerBox.kt`: a shimmer loading placeholder that takes a `shape: Shape` parameter so it matches whatever it's standing in for (a card, an avatar circle, a full-width row) — never a generic rectangle when the real content is a different shape.
- `AppButton.kt`, `AppCard.kt`, `LoadingIndicator.kt`, `ErrorState.kt`, `EmptyState.kt` — the handful of primitives every feature reaches for, built once here so `scaffold-android-feature` composes them instead of reinventing them per feature.

## Step 4 — Core network/data layer (`core/network/`, `core/data/`)

- `NetworkModule.kt`: single Retrofit + OkHttp client (auth interceptor, logging interceptor gated to debug builds only, timeout config from Step 5's constants) that every feature's `{Name}Api` reuses — don't let each feature build its own client.
- `NetworkResult.kt`: a sealed wrapper (`Success`/`Error`/`Loading`) so every repository maps to the same shape instead of each feature inventing its own.
- `BaseRepository.kt`: a `safeApiCall` helper wrapping the common try/catch → `NetworkResult` mapping, so `{Name}RepositoryImpl` classes stay thin.

## Step 5 — Central constants (`core/constants/AppConstants.kt`)

Every value that changes per environment or gets tuned over time lives here — API base URL, timeout durations, feature-flag booleans, pagination page size. Read from `BuildConfig` fields (populated per build variant in `build.gradle.kts`) rather than hardcoding, so debug/staging/prod builds can point at different backends without code changes.

## Step 6 — Responsive layout support (`core/responsive/`)

A `WindowSizeClass`-based helper (Material 3 adaptive) so features can branch layout for compact (phone) / medium (foldable, small tablet) / expanded (tablet, desktop) without each feature reimplementing breakpoint logic.

## Step 7 — Harden `.gitignore`

Verify (don't just assume) these are excluded: `local.properties`, `*.jks`, `*.keystore`, `google-services.json`, `**/release/`, `.env*`, `**/secrets.properties`. If any secret-bearing file is already tracked by git, flag it explicitly — a `.gitignore` entry added after a file is already tracked does not remove it from history.

## Step 8 — Present the result

Summarize what was generated per step, the brand color used (or default, if none given), and confirm `.gitignore` covers all secret-bearing files. Note that `scaffold-android-feature` now expects this foundation to exist.
