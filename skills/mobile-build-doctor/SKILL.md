---
name: mobile-build-doctor
description: Diagnose and fix Android, iOS, and Flutter build/environment/checkout failures autonomously — verify premises, identify the root cause from evidence, apply the proven fix, and confirm the cure. Use when a build fails (Gradle, Xcode, CocoaPods, pod install, linker errors, duplicate symbols), when CI fails but local passes (or the reverse), when code "works on my machine" but breaks on a teammate's, when assets are missing at runtime on a clean checkout, or when a plugin/native-SDK version mismatch appears. Trigger on "fix this build error", "why does it build here but not there", "diagnose this iOS/Android error", "pod install failed", "duplicate symbols", "asset not found", or any pasted build log.
---

# Mobile Build Doctor 🩺

**Incident-response skill.** The other guards review code *before* merge; this one runs *when the build is already on fire*. It encodes a diagnostic method plus a catalog of high-frequency mobile build failures with proven fixes — so the AI stops guessing, stops stacking speculative fixes, and starts diagnosing like a senior engineer who has seen this exact failure before.

**Core principle: the error message is a symptom. The root cause is usually in a file, a lock, a cache, or a checkout — and it is findable with evidence, not vibes.**

---

## Part 1 — Diagnostic Method (Imperatives 1–8)

Run these **before** proposing any fix. Skipping them is how one broken build becomes three.

**1. Read the FULL error output — and treat absence as evidence.**
What is *missing* from a log proves as much as what is present. Example: if a project has Swift Package Manager disabled, the line `Adding Swift Package Manager integration...` must be absent — its presence proves the fix isn't active on that machine. Build a mental checklist of "lines I expect to see / not see" for the fix you believe is in place.

**2. Verify premises before fixing anything.**
The reported environment is a claim, not a fact. Confirm:
- `git status` — is this even a git repository? (A folder named `repo-main.zip`-style, e.g. `project-main_v1`, is usually a GitHub zip extract: it contains *only tracked files at download time* and can never `git pull`.)
- `git log -1` vs the expected HEAD — is the fix you shipped actually *in* this checkout?
- Clean tree or dirty? Which branch? Which machine/OS?
A "bug report" from a stale or wrong-tree checkout is not a code bug. Fix the checkout, not the code.

**3. Trust the authoritative source, never memory or the directory listing.**
- File *case* truth lives in the **git index** (`git ls-files`), not in `ls`/Explorer — Windows and macOS default filesystems are case-insensitive and will lie to you.
- Config-key truth lives in the **installed SDK source** for the pinned toolchain version (keys move between versions — verify against the SDK's own manifest/validator before writing a key you remember).
- Dependency-version truth lives in the **lockfiles and podspecs**, not in what the pubspec/build.gradle "should" resolve to.

**4. One fix per attempt. A *different* error afterward is usually progress.**
If error A disappears and error B appears, the first fix likely worked and you've advanced to the next layer. Re-diagnose B fresh — do not revert A reflexively, and do not stack fix B on an unverified fix A.

**5. When a premise is disproven, STOP and report — never force the original plan.**
If the audit says "these files were never missing" or "the version was never wrong", the honest output is a corrected diagnosis, not a fabricated no-op commit that makes the plan look right.

**6. Reproduce the reporter's environment questions before touching your own tree.**
For cross-machine reports, have the reporter run three cheap commands and send output: `pwd`, `git log -1 --oneline`, and the specific check for the failing artifact (`ls` the file, `git ls-files | grep -i <name>`). Thirty seconds of their terminal beats an hour of your speculation.

**7. Fixes must land in the repository, not in machine config.**
A fix that lives in someone's global tool config (`flutter config`, a local env var, a hand-edited cache) evaporates on the next machine. Prefer tracked, project-level equivalents (pubspec flags, Podfile edits, gradle conditionals) so every clone and CI runner behaves identically.

**8. Name the verification signal before running the fix.**
Every fix in the catalogs below has a "you know it worked when…" line. State it first, then run, then confirm it. A fix without a named signal is a hope.

---

## Part 2 — iOS Failure Catalog (Imperatives 9–13)

**9. "N duplicate symbols" + "project uses both CocoaPods and Swift Package Manager".**
- **Root cause:** both package managers are providing the same native library (classically `SDWebImage`, pulled in by an image plugin's pod chain), so the linker sees every symbol twice.
- **Fix:** disable SwiftPM *at the project level* (tracked, machine-independent):
  ```yaml
  # pubspec.yaml
  flutter:
    config:
      enable-swift-package-manager: false
  ```
  Verify the exact key against the pinned Flutter version's own manifest validator — the older key name (`disable-swift-package-manager`) is rejected by newer SDKs. Then: `flutter clean && rm -rf ios/Pods ios/.symlinks && flutter pub get && cd ios && pod install`.
- **Verify signal:** `Adding Swift Package Manager integration...` is **absent** from the next build log.
- **Note:** this opt-out is interim — Flutter will eventually remove it. Track "full SwiftPM migration once all plugins support it" as backlog, and list the unsupported plugins from the build warning.

**10. Semantic error inside a *plugin's* native source referencing a missing SDK API** (e.g. `Property 'linkDomain' not found on object of type 'FIRActionCodeSettings *'` in `firebase_auth`'s `PigeonParser.m`).
- **Root cause:** the Flutter plugin is newer than the resolved native SDK pods. The plugin's generated code calls an API the pinned native SDK doesn't have yet.
- **Diagnose the pin, in order of likelihood:**
  1. **A global override in `ios/Podfile`** — e.g. `$FirebaseSDKVersion = 'X.Y.Z'`. **Log signature:** `<plugin>: Using user specified Firebase SDK version 'X.Y.Z'` during `Analyzing dependencies`. This override clamps the *entire* SDK family regardless of what plugins request — which is why deleting `Podfile.lock` and `pod install --repo-update` keep re-resolving to the same old version. Confirm mechanically: the plugin's podspec typically reads `if defined?($GlobalVersionVar)` and lets the override win over the plugin family's own tested default.
  2. A stale `Podfile.lock` (when no override exists).
  3. A genuinely incoherent plugin family in pubspec (core package vs feature packages from different generations).
- **Fix:** remove the override (leave a loud *do-not-re-add* comment explaining why) and delete `ios/Podfile.lock` so the next `pod install` resolves to the plugin family's own tested SDK version. Do **not** hand-pin an in-between version — the core plugin (e.g. `firebase_core`) pins one *coherent, tested* SDK release; partial pins invite mismatches in sibling pods (Firestore/Messaging/etc.).
- **Verify signal:** the `Using user specified ... version` line is **gone** from `pod install` output, and the resolved pod version in the fresh lock is ≥ the version that introduced the missing API.
- **Fix ladder when no repo-side pin exists** (pure cache/staleness): `cd ios && pod repo update && pod update <RelevantPods>`; escalate to `rm -rf Pods Podfile.lock && pod install --repo-update`; escalate to `pod cache clean --all` and repeat.

**11. `Podfile.lock` discipline.**
The lock is (usually) **tracked**. Any fix that regenerates it produces a repo change that must be committed *once, deliberately, by the coordinating machine* — never silently pushed by whoever's Mac happened to run `pod install` last. If the lock must be deleted from Windows/CI (where CocoaPods can't run), say so explicitly in the commit body ("intentionally absent; regenerated by the next `pod install` on macOS") and collect the regenerated lock from the first successful Mac build.

**12. Spaces in the checkout path break Xcode script phases.**
Symptoms look unrelated: `Project at /Volumes/xyz/Runner.xcodeproj does not exist` (the path was split at the space), Crashlytics upload-symbols failures, random phase errors. **Fix:** move/re-clone to a space-free path. Treat any path like `/Volumes/my projects/app` as known-bad on sight.

**13. Canonical iOS rebuild sequence** (use whole, not piecemeal):
```bash
flutter clean
rm -rf ios/Pods ios/.symlinks
flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

## Part 3 — Android & Cross-Platform Catalog (Imperatives 14–18)

**14. CI/Linux/macOS fails with `uri_does_not_exist` / `undefined_method` while Windows `analyze` is green.**
- **Root cause:** case-sensitivity. Windows (`core.ignorecase=true`, NTFS) resolves a lowercase import against an uppercase-tracked file; Linux won't. The failure cascades: broken import → every symbol from that file "undefined".
- **Diagnose:** `git ls-files | grep -E "[A-Z]"` for tracked uppercase source paths, plus an exact-case *import-vs-index* audit (every import/export/part path checked verbatim against `git ls-files`). **Skip commented-out lines** — naive regex audits over-report on them.
- **Fix:** two-step rename (a direct case-only `git mv` can silently no-op on case-insensitive filesystems):
  ```bash
  git mv File.dart file_tmpcase.dart && git mv file_tmpcase.dart file.dart
  ```
  Then fix any *barrel exports* still referencing the old case — consumers' imports are often already lowercase (that's why local analyze was green), but barrels break on rename.
- **Verify signal:** the uppercase grep returns nothing; the exact-case audit is clean; CI's next run passes static analysis.

**15. Runtime "Unable to load asset: X" on another machine or clean checkout, while it works locally.**
Three possible worlds — measure, don't guess:
- **(a) Never committed:** the file exists only on the original dev's disk. Diff disk vs index (`find` vs `git ls-files`). Fix: commit the gap **with a security gate** — list what's about to be added, confirm no credentials ride along, and check whether a `.gitignore` rule *deliberately* excluded it before force-adding.
- **(b) Case mismatch:** asset lookup is an exact string match against the bundled manifest on *every* platform. Run the reference-vs-index audit on all `assets/...` string literals. Fix per Imperative 14.
- **(c) Stale build:** assets added after the last full build aren't picked up by hot reload/restart. Fix: `flutter clean` + full rebuild.
Also verify the *reporter's* checkout first (Imperatives 2, 6) — a "missing" asset tracked since the first commit means their copy is stale or carries local edits referencing files that don't exist in the repo at all.

**16. `flutter clean` does NOT clean `android/app/build`.**
For anything where artifact content must be trusted — kernel-content verification, switching Firebase config files (test vs production), signing changes — manually remove `android/app/build` too, or the APK/AAB can carry the previous build's baked-in config. Verify the built artifact's contents directly (grep the artifact for the expected project id) rather than trusting the build to have picked up the switch.

**17. Emulator `[cloud_functions/unavailable]` / DNS-resolver failures mid-session.**
Usually a transient emulator network drop, not a backend outage. Retry / cold-start before escalating. The *real* bug to look for: does the UI **silently swallow** this failure (empty list, no message)? If so, the fix is an error state + retry surface — the network blip merely exposed it.

**18. Release builds silently debug-signed.**
A `buildTypes.release { signingConfig signingConfigs.debug }` left over from local testing produces store-rejected uploads. **Fix pattern:** conditional signing — read `key.properties` if present → real release config; if absent → fall back to debug **with a loud build-time warning** (`key.properties not found — release build is DEBUG-SIGNED, do not upload`). Honor the path the project's *original* config used so existing release machines keep working with zero setup. Keep `key.properties` and `*.jks`/`*.keystore` gitignored — verify, don't assume.

---

## Part 4 — Coordination Rules (Imperatives 19–22)

**19. One writer to the branch at a time — across sessions AND machines.**
Two agents (or an agent and a human, or two machines) committing concurrently to one branch is how histories tangle. Read-only diagnosis may run in parallel; anything that writes waits its turn.

**20. Agents never run network git.** No push, no pull, no fetch from an agent session. The owner moves commits between machines manually. Tracked-file changes produced on a secondary machine (e.g. a regenerated `Podfile.lock` on the release Mac) travel back to the owner for a coordinated commit.

**21. Cross-machine fix protocol:** ship the fix as a commit → owner pushes → remote machine does a *fresh clone or clean pull* (never patches a zip extract) → remote machine reports the named verify-signal from the relevant imperative → any regenerated lockfiles travel back for commit. Close the loop or the fix only exists on one machine.

**22. Write the incident down.** Every diagnosed failure becomes one line in the project's session digest/index: symptom → root cause → fix commit → verify signal. The second occurrence should take five minutes, not an afternoon — that's the entire point of this skill.

---

## Quick Reference

| Symptom | First suspect | Imperative |
|---|---|---|
| duplicate symbols + "CocoaPods and Swift Package Manager" | dual package managers | 9 |
| plugin `.m`/`.swift` references missing native API | Podfile global version override → stale lock | 10 |
| `pod install` keeps resolving the same old version | Podfile override (log: "Using user specified …") | 10 |
| weird Xcode phase/path errors | spaces in checkout path | 12 |
| CI red / Windows green (`uri_does_not_exist`) | filename case vs git index | 14 |
| "Unable to load asset" on clean checkout | untracked file / case / stale build | 15 |
| artifact carries old config after switching | `android/app/build` not cleaned | 16 |
| emulator `unavailable` mid-session | transient DNS — then check for silent-swallow UI | 17 |
| store rejects upload / debug-signed release | leftover debug signingConfig | 18 |
| "works on my machine" | premises: zip extract, stale HEAD, wrong branch | 2, 6 |
