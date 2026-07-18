# Changelog

All notable changes to mobile-engineering-skills will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **.claude-plugin/plugin.json**: packaged the repo as an installable Claude Code plugin (`/mobile-engineering-skills:<skill-name>`), reusing the existing `skills/` directory as-is.
- **references/state-management.md**: new reference file with full worked Kotlin (StateFlow + Compose) and Flutter (BLoC) UDF examples, extracted from `mobile-architecture-guard/SKILL.md`.

### Changed
- **mobile-architecture-guard/SKILL.md**: trimmed from 435 to 332 lines by moving the ViewModel Wrapper anti-pattern example to `references/dependency-injection.md` and the full UDF code examples to the new `references/state-management.md`. No imperatives were added, removed, or renumbered — only long code blocks moved to reference files, replaced with a short summary and pointer.
- **references/dependency-injection.md**: added the ViewModel Wrapper anti-pattern section (moved from SKILL.md).

## [1.3.0] - 2026-07-03

### Added
- **install.sh**: one-liner installer (`curl -fsSL .../install.sh | bash`), with a `--project` flag for project-scoped installs. Tested locally end-to-end.
- **.cursor/rules/**: one `.mdc` rule file per skill (6 total), each a thin pointer to its `skills/*/SKILL.md` rather than a duplicated copy, so Cursor and Claude Code always read the same ruleset. `ai-context-budget-guard.mdc` uses `alwaysApply: true`; the other five activate via `description`/`globs` matching.
- CI: new check verifying every skill has a corresponding `.cursor/rules/*.mdc` pointer.
- README: new "The Problem" / "The Solution" / "How to Use" framing near the top; Cursor section rewritten to describe the actual `.cursor/rules/` pointer files instead of a manual copy-paste snippet.

### Changed

#### Skills
- **mobile-architecture-guard**: expanded from 22 to 24 imperatives
  - Added: before modifying/removing a public symbol, search the whole project for its usages — not just the file being edited (prevents fixing one file while silently breaking three others)
  - Added: run the project's actual local build command (`./gradlew assembleDebug`, `xcodebuild`, `flutter analyze`, etc.) and confirm it passes before presenting a final diff — or explicitly note if no build environment was available
  - Self-check checklist extended with corresponding checks

## [1.2.0] - 2026-07-03

### Changed

#### Skills
- **mobile-architecture-guard**: expanded from 20 to 22 imperatives
  - Added: explicit ban on `@Serializable`/`@Entity` models reaching the UI layer directly — Presentation must consume a dedicated `UIState` produced by its own mapper
  - Added: DI module registration required in the same diff as the `Repository`/`UseCase`/`ViewModel` it registers, not deferred to a follow-up
  - Self-check checklist extended with corresponding checks
- **mobile-kmm-migration-guard**: expanded from 20 to 21 imperatives
  - Added: `Flow`/`StateFlow` exposed to Swift must be verified actually consumable there (SKIE or a manual wrapper), not assumed to work because it compiles
  - Added: Multiplatform Settings (`com.russhwolf:multiplatform-settings`) named as the multiplatform-safe replacement for `SharedPreferences`/`NSUserDefaults` direct calls
- **mobile-security-guard**: expanded from 20 to 21 imperatives
  - Added: `@Keep` (or equivalent) required on serialization/crypto models to survive R8/ProGuard obfuscation in release builds, verified against an actual release build rather than debug only

## [1.1.0] - 2026-07-03

### Fixed
- Added a Table of Contents to every reference file over 300 lines (clean-architecture.md, dependency-injection.md, solid-kotlin.md, flutter-testing.md, kotlin-testing.md), per skill-authoring best practice for large reference files
- Added a "Findings report format (Review mode)" section to mobile-architecture-guard and mobile-tdd-guard, matching the format already used by mobile-security-guard/mobile-accessibility-guard/mobile-kmm-migration-guard
- README now notes that `clean-code-guard` and `test-guard`, referenced by several skills as complementary, are optional companion skills not included in this repository
- CI's "Check for broken reference links" step now performs a real check (previously a no-op placeholder) — verifies every `references/*.md` path mentioned in a SKILL.md actually exists

### Changed

#### Skills
- **ai-context-budget-guard**: expanded from 13 to 16 imperatives
  - Added: enforced bootstrap directive (rule 16) — a `CLAUDE.md`/`.cursorrules` snippet forcing the AI to read `INDEX.md` before scanning any code, closing the gap where an index exists but nothing tells the AI to check it first
  - Added: conditional `Scope/DI` and `Module impact` digest fields (rule 3) for sessions touching dependency injection or module boundaries, so the next session doesn't reach for a dependency that was already deliberately avoided
  - Added: exclusion of generated build artifacts from digest scope (rule 4) — `Hilt_*.kt`, `*Binding.kt`, `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, and `build/`/`.gradle/`/`DerivedData/` in general
  - Added: `::save-context`/`::end-session` Quick Trigger, plus a ready-to-use Claude Code `/save-context` custom slash command
  - `references/templates.md` updated with copy-paste bootstrap directive and slash command templates

### Added

#### Skills
- **mobile-kmm-migration-guard**: Review Kotlin Multiplatform Mobile code for platform leakage, unsafe expect/actual usage, JVM-only dependencies in shared code, and iOS interop hazards
  - 20 imperatives covering shared code boundaries, concurrency/memory model, cross-platform library choices (kotlinx-datetime, Ktor, kotlinx.serialization, SQLDelight), iOS interop safety, testing, migration sequencing, and build tooling
  - Migration readiness report format for assessing whether a module is ready to move to shared code
  - Reference guides: interop-and-concurrency.md, multiplatform-libraries.md
- **mobile-accessibility-guard**: Review Kotlin/Android and Flutter code for WCAG 2.1 AA accessibility violations before merge
  - 20 imperatives covering content descriptions/semantics, touch target sizing, color contrast, screen reader reading order, form labeling, live-region announcements, and custom widget semantic roles
  - Severity-ranked findings report format referencing specific WCAG success criteria
  - Reference guides: screen-reader-patterns.md, touch-and-visual.md
- **mobile-security-guard**: Review Kotlin/Android and Flutter code for security vulnerabilities before merge
  - 20 imperatives covering secrets handling, certificate pinning, transport security, encrypted local storage, exported component hygiene, deep link/WebView/IPC validation, and release build hygiene
  - Severity-ranked (Critical/High/Medium/Low) findings report format for security reviews
  - Reference guides: certificate-pinning.md, secure-storage.md, webview-and-ipc.md
- **ai-context-budget-guard**: Manage AI context budget across long-running mobile engineering sessions
  - 13 imperatives covering digest discipline, index discipline, compression/archiving, and native tool integration (Claude Code CLAUDE.md / auto-memory)
  - Templates for Session Digest, Index, and Archive files

### Fixed
- README installation instructions corrected to match Claude Code's actual skill discovery mechanism (`.claude/skills/<name>/SKILL.md`, auto-discovered — no `~/.clauderc` config file, no `@`-mention invocation for Claude Code specifically)
- Claude.ai/Claude Desktop setup instructions corrected to the actual Skills upload flow (Customize → Skills)
- Removed an unverified specific token-reduction figure; replaced with a description of the mechanism (diffs-only output, imperative references, session digests)

## [1.0.0] - 2026-06-25

### Added

#### Skills
- **mobile-architecture-guard**: Review Kotlin/Android and Flutter code for SOLID principles, Clean Architecture, modular design
  - 20 imperatives covering layer separation, dependency injection, module structure, state management, repository patterns
  - Complete integration guide with examples

- **mobile-tdd-guard**: Test-driven development workflow for mobile development (red-green-refactor cycle)
  - 20 imperatives covering test structure, mocking, boundary testing, framework-specific patterns
  - Kotlin/Android and Flutter specific guidance

#### Reference Documentation
- **SOLID Principles in Kotlin**: Detailed examples of Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **Clean Architecture**: Three-layer architecture (Domain, Data, Presentation) with Kotlin examples
- **Dependency Injection**: Constructor injection, DI containers (Hilt, GetIt), testing patterns
- **Kotlin Testing Patterns**: JUnit, MockK, StateFlow, LiveData, coroutine testing
- **Flutter Testing Patterns**: Widget tests, BLoC testing, mockito patterns, pump vs pumpAndSettle

#### Examples
- Kotlin Clean Architecture project structure
- Flutter BLoC architecture example
- TDD workflow examples for both platforms

#### Infrastructure
- GitHub Actions workflow for validation
- npm/npx installation support
- MIT License
- Contributing guidelines

### Features

#### mobile-architecture-guard
- Enforce SRP (one ViewModel per screen, one repository per domain concept)
- Validate layer dependencies (Presentation → Domain ← Data)
- Detect circular imports between features
- Check dependency injection patterns
- Validate state management centralization
- Ensure domain layer framework-independence
- Module boundary validation
- Testing boundary checks

#### mobile-tdd-guard
- Guide red-green-refactor cycle
- Mock external dependencies properly
- Test behavior, not implementation
- Validate boundary/edge case testing
- Prevent test duplication
- Flutter-specific patterns (pump, pumpAndSettle, bloc_test)
- Kotlin-specific patterns (runTest, StateFlow, coEvery)
- Exception handling best practices

### Documentation
- Comprehensive README with quick start
- Detailed SKILL.md files for each skill
- Reference guides for architecture and testing
- Real-world examples for both Kotlin and Flutter
- Troubleshooting guides

---

## Future Roadmap

### Shipped ahead of the original plan
- [x] mobile-security-guard
- [x] mobile-accessibility-guard
- [x] mobile-kmm-migration-guard (originally planned for v1.2 — shipped in 1.1.0 instead)

### Planned
- [ ] Performance profiling skill (static anti-pattern detection: leaked listeners, unbounded coroutine scopes, excessive recomposition — not runtime profiling)
- [ ] Domain modeling skill (sharpen project vocabulary and terms)
- [ ] Integration test patterns
- [ ] CI/CD best practices for mobile
- [ ] Healthcare domain-specific patterns (Patient, Appointment, Prescription entities)
- [ ] More examples (e-commerce, social apps, fintech)

### Community Contributions Welcome
- Additional language examples (Swift, Dart-specific patterns)
- Domain-specific examples (healthcare, e-commerce, fintech)
- Refactoring patterns
- Anti-patterns and how to fix them

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Reporting issues
- Suggesting improvements
- Submitting pull requests
- Coding standards

---

## Notes

These skills are based on:
- Clean Architecture (Robert C. Martin, 2012)
- Test-Driven Development (Kent Beck, 2002)
- SOLID Principles (Robert C. Martin)
- Domain-Driven Design (Eric Evans, 2003)
- Growing Object-Oriented Software, Guided by Tests (Freeman & Pryce, 2009)
- The Pragmatic Programmer (Hunt & Thomas, 2019)

Over 13+ years of mobile engineering experience across Android, iOS, Flutter, and Kotlin Multiplatform.
