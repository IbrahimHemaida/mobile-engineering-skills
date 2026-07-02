---
name: mobile-security-guard
description: Review Kotlin/Android and Flutter code for security vulnerabilities before merge — insecure storage, exposed secrets, missing certificate pinning, weak network configs, and unsafe IPC. Use when reviewing feature implementations that touch authentication, local storage, networking, or deep links, when preparing for a security audit, or after a coding agent generated code that handles sensitive data. Apply this for API key handling, certificate pinning, encrypted storage, WebView configuration, and Network Security Config validation. Use for "review this for security issues", "is this storage safe?", "check certificate pinning", "audit this for a security review", or after implementing auth/networking features.
---

# mobile-security-guard

You are reviewing mobile code for security vulnerabilities before it ships. Apply the rules below as a security audit after the feature is implemented, or while designing auth/storage/networking code. This skill validates common mobile-specific vulnerability classes in Android/Kotlin and Flutter — not general web security (OWASP Web Top 10 doesn't map 1:1 to mobile).

## Compatibility

This skill works with:
- **Kotlin/Android**: Network Security Config, EncryptedSharedPreferences/Jetpack Security, OkHttp CertificatePinner, Keystore
- **Flutter**: flutter_secure_storage, dio/http interceptors for pinning, platform channel boundary checks
- **Shared**: KMM (Kotlin Multiplatform Mobile) — expect/actual security boundaries between platforms

This skill complements mobile-architecture-guard and clean-code-guard. Use architecture-guard for layer boundaries, clean-code-guard for general code quality, and this skill specifically for exploitable vulnerabilities — the difference between "messy" and "dangerous."

## Reference files

This SKILL.md covers the core rules and checklists. For deeper treatment, load these as needed:
- `references/certificate-pinning.md` — Network Security Config XML patterns, OkHttp CertificatePinner setup, pin rotation strategy, and Flutter pinning via dio/http_certificate_pinning.
- `references/secure-storage.md` — EncryptedSharedPreferences vs Keystore vs flutter_secure_storage tradeoffs, biometric-gated storage, and what never belongs on-device at all.
- `references/webview-and-ipc.md` — WebView JavaScript bridge risks, deep link/intent validation, exported component checks, and clipboard/screenshot leakage.

Read the relevant reference file when a violation needs more context than the summary here provides, or when the user asks for a deeper explanation of a specific mechanism.

## How to use this skill

**Guard-pass mode** (recommended): After implementing a feature touching auth, storage, networking, or external input (deep links, WebViews, IPC), check the code against the imperatives below before merging.

**Live mode** (explicit): When designing a new auth flow, storage layer, or network client, apply these imperatives while building, then run the *Self-check before delivery* checklist.

**Review mode**: Walk the code and provide a structured findings report, severity-ranked (Critical / High / Medium / Low), with the exploit scenario for each finding — not just "this is insecure" but "an attacker with X access could do Y."

## Why this skill exists

Mobile security failures are systematic and repeat across teams:
- **Secrets in the client**: API keys, signing secrets, or backend credentials hardcoded or bundled in the APK/IPA, extractable by anyone with `apktool` or a jailbroken device.
- **Silent trust of the network**: No certificate pinning, so a MITM proxy (rogue Wi-Fi, compromised CA) can read or alter traffic invisibly.
- **Plaintext-adjacent local storage**: Tokens, PII, or health data sitting in unencrypted SharedPreferences, plist files, or SQLite — recoverable from any backup or rooted device.
- **Over-exposed components**: Activities, deep links, or content providers that accept untrusted input without validation, or are exported when they don't need to be.
- **Debug leftovers shipping to production**: Logging tokens/PII, debug-only bypass flags, or `usesCleartextTraffic` left `true`.

These are the vulnerability classes that actually get exploited in mobile apps, as opposed to web-style vulnerabilities (SQLi, XSS) that mostly don't apply to native mobile clients.

## Always-applied imperatives

### Secrets & Credentials

1. **No secret ever lives in source, even "temporarily."**
   API keys, client secrets, signing passwords, and backend tokens do not belong in Kotlin/Dart source, `local.properties` committed to git, or string resources. Use `BuildConfig` fields injected from CI secrets, or fetch short-lived tokens from a backend at runtime.
   **Violation smell**: `const val API_KEY = "sk-..."` anywhere in a tracked file. A single `git log -p | grep -i key` finding is a shipped incident, not a style nit.

2. **Client-side secrets are not secrets.**
   Anything bundled into the APK/IPA is extractable — treat every embedded string as public. If an API truly needs a secret, the secret belongs on your backend, with the client authenticating as a *user*, not as itself.
   **Test**: "If this string were posted on GitHub tomorrow, would anything bad happen?" If yes, it doesn't belong client-side.

3. **Never log sensitive data, not even at DEBUG level.**
   Tokens, passwords, full PII, and health/financial data must never hit `Log.d`, `print()`, or crash-reporting breadcrumbs (Crashlytics, Sentry) — debug logs ship in release builds far more often than teams expect, and crash tools upload automatically.
   **Violation smell**: `Log.d("Auth", "token=$token")`. Redact or omit; log presence/absence, not values.

### Certificate Pinning & Transport Security

4. **Pin certificates for any endpoint handling auth or sensitive data.**
   Android: Network Security Config `<pin-set>` or OkHttp `CertificatePinner`, pinning the SPKI hash of the leaf or intermediate cert, with a backup pin for rotation. Flutter: dio/http interceptor validating the cert chain against pinned hashes.
   **Rationale**: Without pinning, any CA compromise or rogue-but-technically-valid cert (corporate MITM proxy, malicious Wi-Fi) can decrypt traffic silently — TLS alone only guarantees "someone signed this," not "the app's real backend signed this."

5. **Always include a backup pin; never pin to a single leaf certificate with no rotation path.**
   Pin at minimum two SPKI hashes (current + next/backup), or pin the intermediate CA if leaf rotation is frequent. A single-pin setup that expires without an app update is an outage, not a security win.

6. **`usesCleartextTraffic` is `false` by default; cleartext exceptions are explicit and scoped.**
   Android Network Security Config should default-deny cleartext, with narrow `<domain-config>` exceptions only for specific dev/staging hosts — never a blanket allow in a release build.
   **Violation smell**: `android:usesCleartextTraffic="true"` in the merged release manifest, or a Network Security Config with no `<base-config cleartextTrafficPermitted="false">`.

7. **Validate the full chain, not just the hostname.**
   Disabling hostname verification or accepting all certificates (`TrustManager` that no-ops `checkServerTrusted`) to "fix" a dev SSL error is a critical finding if it ships — this pattern is a top cause of real-world mobile MITM breaches. Fix the actual cert/CA issue instead.

### Local Storage

8. **Tokens, credentials, and PII are encrypted at rest, never in plain SharedPreferences/UserDefaults/plist.**
   Android: `EncryptedSharedPreferences` (Jetpack Security) or Keystore-backed storage. Flutter: `flutter_secure_storage` (uses Keystore/Keychain under the hood), not `shared_preferences`.
   **Violation smell**: `sharedPreferences.putString("auth_token", token)` with no encryption layer. Anyone with `adb backup` or root access reads it directly.

9. **Session tokens are short-lived; refresh tokens are the only thing stored long-term, and only encrypted.**
   Don't persist a long-lived access token as if it were a refresh token. Use the shortest-lived access token the backend supports, refreshed via a securely stored refresh token.

10. **Sensitive data has a lifecycle — clear it on logout, and don't cache it beyond necessity.**
    On logout: clear secure storage, in-memory caches, and any disk cache (image cache showing a profile photo, cached API responses with PII). A "logout" that leaves the previous user's data readable to the next app session is a shared-device data leak.

11. **Database-level encryption for local databases holding sensitive data.**
    Room/SQLite or Flutter's sqflite storing health, financial, or PII data uses SQLCipher (or platform-equivalent) rather than an unencrypted `.db` file sitting in app-private storage — app-private is not device-private on a rooted or backed-up device.

### Exposed Components & External Input

12. **Activities, services, receivers, and providers are `exported="false"` unless there's a specific reason for another app to reach them.**
    Every exported component is a public API surface with no compile-time contract. If a component doesn't need to be launched by other apps or the system, it isn't exported.
    **Violation smell**: `android:exported="true"` on an Activity that just internally displays account data, with no corresponding intent-filter reason.

13. **Deep links and intent extras are validated as untrusted input, not internal state.**
    Any data arriving via `Intent` extras, deep link query params, or a Flutter `onGenerateRoute` from an external URI can be crafted by any app or a malicious webpage. Validate type, range, and origin before acting on it — never directly use it for navigation to sensitive screens, SQL-like queries, or file paths without validation.

14. **WebViews loading untrusted or mixed-origin content have JavaScript bridges disabled or tightly scoped.**
    `addJavascriptInterface`/`JavascriptChannel` exposed to a WebView that can load arbitrary or user-supplied URLs is a direct code-execution bridge into the app. If a JS bridge is required, restrict it to a known first-party origin via `shouldOverrideUrlLoading`/`onNavigationRequest`, and never expose it to `file://` or arbitrary `https://` content.

15. **Copy-paste and screenshots are considered for genuinely sensitive screens.**
    Password/OTP fields disable clipboard suggestions where the platform allows; screens showing full card numbers, health records, or auth secrets set `FLAG_SECURE` (Android) / equivalent to block screenshots and the app-switcher preview thumbnail.

### Authentication & Session Handling

16. **Biometric auth gates access to data, not just to a UI screen.**
    A "biometric lock" that only guards navigation (user can still read cached data via a different path, a backup, or a debugger) is theater. Gate the actual decryption key behind biometric/Keystore auth so the data is unreadable without it, not just unreachable through the normal UI.

17. **Root/jailbreak and debugger detection is a defense-in-depth signal, not a security boundary — treat it accordingly.**
    It's reasonable to detect and respond to (warn, restrict high-risk features) a rooted device for apps handling payments or health data, but never rely on it as the *only* protection for sensitive data — it's bypassable and should sit alongside encryption and pinning, not replace them.

18. **Rate-limit and lock out client-side auth attempts, but treat client-side limits as UX only.**
    Client-side attempt counters improve UX (reduce needless requests) but the real limit enforcement is server-side. Don't let a security review conclude "brute force is prevented" based solely on a client-side counter that a modified APK trivially bypasses.

### Build & Release Hygiene

19. **Debug flags, mock backends, and bypass logic never reach a release build.**
    `if (BuildConfig.DEBUG)` gates around auth bypasses, verbose logging, or test endpoints must be verified absent from the release variant — via ProGuard/R8 stripping or explicit build-variant separation, not just a runtime `if` that could regress.

20. **Minification and obfuscation are enabled for release builds handling sensitive logic.**
    R8/ProGuard (Android) or equivalent should be on for release, with rules that don't accidentally `-keep` the classes doing crypto/auth (defeating the point) nor break them (crashing in production). Obfuscation isn't a substitute for the items above — it raises the cost of static analysis, nothing more.

## Self-check before delivery

Before marking a security review complete, confirm:

- [ ] No API keys, secrets, or credentials in tracked source files
- [ ] No sensitive values in logs, crash reports, or analytics events
- [ ] Certificate pinning present on auth/sensitive endpoints, with a backup pin
- [ ] Cleartext traffic is default-denied; exceptions are explicit and scoped
- [ ] No custom `TrustManager`/hostname verifier that skips validation
- [ ] Tokens/PII stored via encrypted storage, not plain SharedPreferences/UserDefaults
- [ ] Logout clears secure storage, in-memory state, and relevant disk caches
- [ ] Exported components are intentional, not default-on
- [ ] Deep link / intent extra inputs are validated before use
- [ ] WebView JS bridges are scoped to trusted origins only
- [ ] Sensitive screens block screenshots / app-switcher preview where warranted
- [ ] Biometric gates decrypt data, not just guard a screen
- [ ] Debug bypasses and verbose logging are stripped from release builds

## Findings report format (Review mode)

When reviewing existing code, report findings as:

```
[SEVERITY] Short title
File: path/to/File.kt:line
Issue: What's wrong, in one sentence.
Exploit: Concrete scenario — who could exploit this and how.
Fix: Specific remediation (imperative # from above where relevant).
```

Severity guide: **Critical** = remote exploit or data breach with no special access needed (hardcoded secret, disabled cert validation). **High** = exploit needs local/rooted access or user interaction (unencrypted local storage, exported component). **Medium** = defense-in-depth gap, not directly exploitable alone (missing backup pin, no root detection). **Low** = hygiene issue (debug log of non-sensitive data, missing `FLAG_SECURE` on a low-sensitivity screen).
