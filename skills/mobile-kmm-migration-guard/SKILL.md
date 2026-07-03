---
name: mobile-kmm-migration-guard
description: Review Kotlin Multiplatform Mobile (KMM) code for platform leakage, unsafe expect/actual usage, JVM-only dependencies in shared code, and iOS interop hazards. Use when writing or reviewing code in commonMain, when migrating existing Android/iOS logic into a shared module, when adding a new expect/actual declaration, or when a coding agent generated multiplatform code. Apply this for shared business logic, cross-platform networking/persistence/serialization, Kotlin/Native concurrency, and Swift interop safety. Use for "review this KMM code", "is this safe to put in commonMain?", "migrate this to shared", "check expect/actual usage", or after implementing any commonMain feature.
---

# mobile-kmm-migration-guard

You are reviewing Kotlin Multiplatform Mobile code — either new shared-module code or a migration of existing Android/iOS logic into `commonMain`. Apply the rules below to catch platform leakage, unsafe multiplatform library choices, and Kotlin/Native interop hazards that compile fine but break or crash on one platform. This is a narrower, less mature domain than Android or Flutter alone — bad KMM patterns often pass code review because the reviewer only tested on one platform.

## Compatibility

This skill works with:
- **Kotlin Multiplatform Mobile**: `commonMain`/`androidMain`/`iosMain` source set structure, `expect`/`actual` declarations, Kotlin/Native
- **Cross-platform libraries**: kotlinx-datetime, kotlinx.serialization, Ktor client, SQLDelight — the multiplatform-safe equivalents of JVM-only libraries
- **iOS interop**: Kotlin/Native's Objective-C/Swift export, and the concurrency/exception/nullability differences at that boundary

This skill complements mobile-architecture-guard (layer boundaries apply the same way inside `commonMain`) and mobile-tdd-guard (testing strategy below extends its red-green-refactor rules to multiplatform test targets). Use this skill specifically for the multiplatform-specific failure modes those two don't cover.

## Reference files

This SKILL.md covers the core rules and checklists. For deeper treatment, load these as needed:
- `references/interop-and-concurrency.md` — Kotlin/Native memory model, `Dispatchers.Main` behavior on both platforms, and Swift interop hazards (exceptions, nullability, sealed class/enum export) with worked examples.
- `references/multiplatform-libraries.md` — kotlinx-datetime, Ktor client, kotlinx.serialization, and SQLDelight setup and usage patterns, plus what JVM-only equivalents they replace and why those don't compile for iOS targets.

Read the relevant reference file when a violation needs more context than the summary here provides, or when setting up a multiplatform library for the first time on a project.

## How to use this skill

**Guard-pass mode** (recommended): After writing or migrating code into `commonMain`, check it against the imperatives below before merging.

**Migration-planning mode**: When deciding what to migrate next from platform-specific code into shared code, use the *Migration Strategy* imperatives to sequence the work and the *Migration readiness report* format to assess a candidate module.

**Review mode**: Walk `commonMain` (and the `expect`/`actual` pairs it depends on) and flag platform leakage or unsafe library usage with the specific line and the platform it will fail on.

## Why this skill exists

KMM code that compiles is not the same as KMM code that works on both platforms — the failure modes are specific to this architecture:
- **Silent platform leakage**: an `android.content.Context` parameter or `androidx.lifecycle` import creeps into `commonMain` because it compiled fine (Android is usually the platform being actively developed against), and iOS discovers it only at iOS-target compile time or, worse, doesn't discover it because the file was never actually exercised on iOS.
- **JVM-only libraries in shared code**: `java.time`, `java.io.Serializable`, `OkHttp`, or `Gson` used directly in `commonMain` compile against the JVM target but fail or don't exist for the Kotlin/Native (iOS) target.
- **Concurrency assumptions that don't hold on iOS**: blocking the main thread is an ANR dialog on Android but a watchdog-triggered force-quit on iOS; code "tested" only on Android can pass there and crash on iOS.
- **Exceptions crossing the interop boundary uncaught**: Kotlin's exception model doesn't map cleanly to Swift's `try`/`catch` — an uncaught Kotlin exception thrown from shared code into Swift crashes the iOS app in a way that's hard to diagnose from the Kotlin side.
- **Big-bang migration attempts**: teams try to migrate an entire feature (including networking and persistence) to shared code at once, hit every failure mode above simultaneously, and conclude "KMM doesn't work" rather than that the migration was sequenced wrong.

## Always-applied imperatives

### Shared Code Boundaries

1. **`commonMain` never imports `android.*`, `androidx.*`, or any Android SDK type.** If Android-specific behavior is genuinely needed, it belongs behind an `expect`/`actual` boundary, not inline in shared code.
   **Violation smell**: a `Context` parameter threaded into a `commonMain` function "just to get a string resource" — pass the resolved string instead, resolved on each platform's side of the `actual`.

2. **`commonMain` never imports Foundation, UIKit, or other Apple-platform-only frameworks.** Same rule as #1, mirrored for iOS — shared code that only compiles against one Kotlin/Native/JVM target isn't shared code, it's misplaced platform code.

3. **`expect`/`actual` exists for genuine platform divergence, not to defer a decision.** Before adding an `expect`/`actual` pair, confirm the platforms actually need different implementations (e.g. secure storage APIs genuinely differ) rather than reaching for it because solving something once in common code takes more thought.
   **Violation smell**: an `expect fun formatCurrency()` where the formatting logic is identical on both platforms and could be pure Kotlin in `commonMain` with no platform dependency at all.

4. **`actual` implementations are thin platform plumbing, not a place business logic quietly duplicates.** If an `actual` implementation on Android and iOS both end up containing similar business rules (not just platform API calls), that logic should move into `commonMain` and be called from both `actual`s — duplicated business logic in two `actual` blocks is a bug waiting to happen when only one side gets updated.

### Concurrency & Memory

5. **No blocking calls on the main thread — this is more punishing on iOS than Android.** A blocking call that causes an Android ANR dialog causes an iOS watchdog termination with a less informative crash report. Treat "works fine on Android" as insufficient evidence when reviewing anything touching `Dispatchers.Main`.

6. **Mutable state shared across threads is protected by proper synchronization, not assumptions carried over from single-platform code.** Kotlin/Native's newer memory model removed the old "frozen state" requirement, but that doesn't make unsynchronized mutable shared state safe — it makes the old, obvious failure mode (a frozen-state exception) silent instead, replaced by a harder-to-diagnose race condition.

7. **`Dispatchers.Main` is verified to map to the real platform main thread on both targets**, especially in test code or custom dispatcher setups — a test dispatcher or coroutine scope that quietly no-ops on one platform gives false confidence that main-thread-affinity code is correct.

### Cross-Platform Library Choices

8. **Date/time handling uses `kotlinx-datetime`, not `java.time`, anywhere in `commonMain`.** `java.time` is JVM-only and doesn't exist for Kotlin/Native — code using it compiles for Android and fails to compile (or isn't even attempted) for iOS.

9. **Networking in shared code uses a true multiplatform HTTP client (Ktor client or equivalent), not OkHttp/Retrofit directly.** OkHttp is a JVM library; shared networking logic needs a client with real Kotlin/Native engine support.

10. **Serialization in shared code uses `kotlinx.serialization`, not `java.io.Serializable` or JVM-only Gson/Moshi.** Same JVM-only trap as #8 and #9 — these compile against Android and don't exist for the iOS target.

11. **Local persistence in shared code uses SQLDelight (or an explicit `expect`/`actual` storage abstraction), not Room directly.** Room is an Android/JVM library; if persistence logic is meant to be shared, it needs a genuinely multiplatform storage layer or a clean platform boundary around it.

### iOS Interop Safety

12. **Exceptions that can cross from `commonMain`/shared code into Swift are caught and converted, not left to propagate uncaught.** Kotlin's exception model doesn't map to Swift's error handling automatically — wrap boundary-crossing calls to convert exceptions into a `Result`-style return or an `NSError`, so a Swift caller gets a normal error instead of an uncatchable crash.

13. **Sealed classes and enums exposed across the Swift boundary are verified to actually produce a usable generated Swift API**, not just assumed to work because they compile in Kotlin. Generate and inspect the Obj-C/Swift header for anything exported and consumed from Swift — generic sealed class hierarchies in particular can generate awkward or unusable Swift interfaces.

14. **Nullability at the interop boundary is explicit and tested for the specific types crossing it**, especially generics and collections. Kotlin nullable types map to Swift `Optional`, but the mapping for generic and collection types has enough edge cases that it should be verified with an actual Swift-side call, not assumed from the Kotlin signature alone.

### Testing

15. **Shared logic in `commonMain` is tested once in `commonTest` and run against both platform targets**, not duplicated as separate Android and iOS test suites for the same logic. If a test only makes sense on one platform, it belongs in that platform's own test source set, not `commonTest`.

16. **Platform-specific `actual` implementations have their own platform-side tests.** `commonTest` can exercise the `expect` contract's behavior through fakes, but it can't verify a real `actual` implementation is correct on-device — that needs `androidTest`/`iosTest` coverage of its own.

### Migration Strategy

17. **Migration is incremental and module-by-module, not a big-bang rewrite of an entire feature at once.** Start with pure logic — validation, formatting, calculations, business rules with no I/O — before migrating networking or persistence, so early wins don't simultaneously hit every failure mode in this skill at once.

18. **A module is ready to migrate to shared code only once its remaining platform-specific dependencies have a clear `expect`/`actual` abstraction plan.** If a module can't currently be abstracted (e.g. it depends on a platform SDK feature with no multiplatform equivalent), it stays platform-specific rather than getting forced into `commonMain` with a leaky workaround.

### Build & Tooling

19. **Gradle dependencies are declared once in the appropriate source set, not duplicated per-platform when they could be shared.** A dependency needed by both `androidMain` and `iosMain` but not truly platform-specific probably belongs in `commonMain`'s dependency declarations instead of being duplicated in both platform source sets.

20. **Kotlin/Native build time is monitored, not ignored until it becomes a team-wide velocity problem.** Enable Gradle build caching and Kotlin/Native compilation caching where available — KMM build times can regress significantly as shared code grows, and catching this early is cheaper than a later build-performance migration project.

## Self-check before delivery

Before marking a KMM review complete, confirm:

- [ ] No `android.*`/`androidx.*` imports in `commonMain`
- [ ] No Foundation/UIKit/Apple-only imports in `commonMain`
- [ ] Every `expect`/`actual` pair represents genuine platform divergence, not deferred common-code work
- [ ] No business logic duplicated across `actual` implementations
- [ ] No blocking calls on `Dispatchers.Main`
- [ ] Shared mutable state has explicit synchronization, not assumed safety from the new memory model
- [ ] `kotlinx-datetime`, not `java.time`, anywhere in `commonMain`
- [ ] Ktor (or equivalent) for shared networking, not OkHttp/Retrofit directly
- [ ] `kotlinx.serialization`, not `Serializable`/Gson/Moshi, in `commonMain`
- [ ] SQLDelight or an explicit abstraction for shared persistence, not Room directly
- [ ] Exceptions crossing into Swift are caught and converted, not left uncaught
- [ ] Sealed classes/enums exposed to Swift have been checked against the generated header
- [ ] `commonTest` covers shared logic once; platform `actual`s have their own platform-side tests
- [ ] Migration was sequenced pure-logic-first, not attempted as a single big-bang move

## Migration readiness report format

When assessing whether a module is ready to migrate to shared code:

```
Module: <name>
Readiness: Ready / Needs abstraction work / Not yet
Pure logic (no I/O): <yes/no — this should usually migrate first>
Platform dependencies found: <list, e.g. "Android Context for string resources", "OkHttp client">
Abstraction plan: <expect/actual plan for each dependency above, or "none available yet" if truly blocked>
Suggested sequence: <e.g. "migrate validation logic now; defer networking until Ktor client is set up">
```

## Troubleshooting

- If a shared-code file compiles for Android but fails only at iOS-target compile time, check for a JVM-only import (`java.time`, `Serializable`, OkHttp types) before assuming it's an interop issue — this is the most common cause.
- If an iOS app crashes with no useful Kotlin-side stack trace on a call into shared code, check for an uncaught exception crossing the Swift boundary (imperative #12) before assuming it's a Swift-side bug.
- If a sealed class works fine in Kotlin tests but is awkward to use from Swift, inspect the generated Obj-C header directly — the issue is usually generic type parameters or a hierarchy shape that doesn't export cleanly, not a Swift-side mistake.
