---
name: scaffold-flutter-foundation
description: Scaffold the app-wide foundation a Flutter app needs before any feature is built — design system (colors, typography, spacing, light/dark theme, glass-effect nav bar), localization, a shared reusable widget library, a core network/data layer, a central constants/environment config, responsive layout support, and a hardened .gitignore. Use once, early in a project, before scaffold-flutter-feature. Use when the user asks to "set up the app foundation", "add theming/dark mode", "set up localization", "add a shared widget library", or "set up the core layer".
argument-hint: [optional: brand color hex, e.g. "#0A84FF"]
---

# Scaffold Flutter Foundation

Generates the shared infrastructure that every feature module depends on. Run this **once**, early — `scaffold-flutter-feature` assumes this foundation already exists (it imports from `lib/core/`, uses `AppTheme`, `AppDimens`, and the shared widget library).

Full code templates are in `references/flutter-foundation-templates.md` — read it before generating.

## Step 1 — Design system (`lib/core/theme/`)

- **app_colors.dart**: a `ColorScheme` for light and dark, generated via `ColorScheme.fromSeed` from the brand color in `$ARGUMENTS` if given, else a sensible default.
- **app_theme.dart**: `ThemeData` (light + dark) wiring the color scheme, text theme, and component themes — this is what `MaterialApp(theme:, darkTheme:, themeMode: ThemeMode.system)` points at.
- **app_dimens.dart**: spacing scale on the same 4px grid Material Design and Apple HIG both broadly agree on (4, 8, 12, 16, 24, 32) and the 48x48 logical-pixel minimum tap target — this is what `mobile-accessibility-guard` checks generated features against.
- **Glass nav bar**: a bottom nav using `BackdropFilter` + `ImageFilter.blur` over a semi-transparent `Container` colored from the same `ColorScheme` — built with Flutter SDK primitives only (no unverified third-party package assumed), so it reads as "this app's nav bar, made of glass," not a generic effect pasted on top.

## Step 2 — Localization (`lib/core/l10n/`)

- `intl_en.arb` plus at least `intl_ar.arb` (matching this project's established RTL/Arabic conventions — clean separation of Arabic/English text, correct `Directionality` handling).
- `l10n.yaml` config so `flutter gen-l10n` generates the `AppLocalizations` class.
- Confirm `MaterialApp` is wired with `localizationsDelegates`, `supportedLocales`, and that RTL mirrors correctly for Arabic (Flutter mirrors automatically per `Directionality` — verify, don't assume).

## Step 3 — Shared widget library (`lib/core/widgets/`)

- `app_shimmer.dart`: a shimmer loading placeholder that takes a `BorderRadius`/`shape` parameter so it matches whatever it's standing in for (a card, a circular avatar, a full-width row) — never a generic rectangle when the real content is a different shape.
- `app_button.dart`, `app_card.dart`, `loading_indicator.dart`, `error_state.dart`, `empty_state.dart` — the handful of primitives every feature reaches for, built once here so `scaffold-flutter-feature` composes them instead of reinventing them per feature.

## Step 4 — Core network/data layer (`lib/core/network/`, `lib/core/data/`)

- `dio_client.dart`: single `Dio` instance (auth interceptor, logging interceptor gated to debug builds via `kDebugMode`, timeout config from Step 5's constants) that every feature's `{name}_remote_datasource.dart` reuses — don't let each feature build its own client.
- `failure.dart`: a small sealed `Failure` hierarchy (`ServerFailure`, `CacheFailure`, `NetworkFailure`) so every repository maps errors to the same shape via `Either<Failure, T>`.

## Step 5 — Central constants (`lib/core/constants/app_constants.dart`)

Every value that changes per environment or gets tuned over time lives here — API base URL, timeout durations, feature-flag booleans, pagination page size. Read environment-specific values via `--dart-define` (or `flutter_dotenv` if the project already uses it) rather than hardcoding, so dev/staging/prod builds point at different backends without code changes.

## Step 6 — Responsive layout support (`lib/core/responsive/`)

A breakpoint helper (`LayoutBuilder`/`MediaQuery`-based) with named breakpoints (mobile / tablet / desktop) so features branch layout without each one reimplementing breakpoint logic.

## Step 7 — Harden `.gitignore`

Verify (don't just assume) these are excluded: `.env`, `.env.*`, `**/key.properties`, `**/*.jks`, `**/google-services.json`, `**/GoogleService-Info.plist`, `.dart_tool/`, `**/ios/Flutter/flutter_export_environment.sh`. If any secret-bearing file is already tracked by git, flag it explicitly — a `.gitignore` entry added after a file is already tracked does not remove it from history.

## Step 8 — Present the result

Summarize what was generated per step, the brand color used (or default, if none given), and confirm `.gitignore` covers all secret-bearing files. Note that `scaffold-flutter-feature` now expects this foundation to exist.
