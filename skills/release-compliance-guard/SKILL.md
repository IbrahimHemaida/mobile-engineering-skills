---
name: release-compliance-guard
description: Pre-submission review for Android/Flutter apps: permissions vs real feature use, App Store and Play rejection patterns, and release readiness (production config, force-update, staged rollout, crash symbols, attestation). Use before any production build upload or when asked to prepare for release.
argument-hint: [optional: target store — "ios", "android", or both]
---

# Release Compliance Guard

A pre-submission review, not a scaffolder — this skill finds and reports gaps between what the app actually does and what the store manifests/permissions declare, then fixes them. Read `references/permission-mapping.md` and `references/store-requirements.md` before reviewing. If either file is missing in this installation, do not stop or report it; the steps below are sufficient on their own.

This is a read-only review unless the user asks for fixes: report first, change second.

## Step 1 — Build the actual feature-to-permission map

Scan the codebase for API usage that requires a permission or usage-description string — don't rely on what's already declared, since that's exactly what might be wrong (missing OR stale):

```
grep -rl "CameraX\|camera\|ImagePicker" --include="*.kt" --include="*.dart" .
grep -rl "LocationServices\|Geolocator\|FusedLocationProvider" .
grep -rl "BluetoothAdapter\|flutter_blue" .
grep -rl "ContactsContract\|contacts_service" .
grep -rl "NotificationManager\|firebase_messaging" .
grep -rl "MediaRecorder\|record\b" .
```

Cross-reference the result against `references/permission-mapping.md`, which maps each API pattern to its required Android permission and iOS `Info.plist` key.

## Step 2 — Android: `AndroidManifest.xml`

- Every permission actually used by the code (Step 1) must be declared — add any that are missing.
- Every permission declared but **not** used by any code path must be flagged for removal — Google Play review treats unused sensitive permissions (location, contacts, SMS) as a rejection risk and a Data Safety form mismatch.
- Dangerous permissions (camera, location, contacts, microphone) need runtime request code (`ActivityResultContracts.RequestPermission` or Accompanist Permissions) — a manifest declaration alone doesn't satisfy Android 6.0+ requirements.
- Confirm `targetSdkVersion` meets Google Play's current minimum requirement for new/updated app submissions (this changes yearly — verify the current requirement rather than trusting a cached number, since a stale target SDK is an instant rejection).

## Step 3 — iOS: `Info.plist`

- Every permission-requiring API from Step 1 needs its matching `NSXxxUsageDescription` key with an actual, specific, human-readable string explaining _why_ — "This app needs your location" is a common rejection reason for being too generic; "Used to show nearby stores" passes.
- If the app uses `IDFA`/advertising attribution or any cross-app/cross-site tracking: `NSUserTrackingUsageDescription` is required, and the app must call the App Tracking Transparency (ATT) prompt before any tracking — check `references/store-requirements.md` for what counts as "tracking" under Apple's definition, since it's broader than just ads.
- `PrivacyInfo.xcprivacy` (Privacy Manifest): required if the app or any SDK it bundles uses APIs Apple classifies as requiring a declared reason (e.g. `UserDefaults`, file timestamp APIs, disk space APIs) — check third-party SDKs in use (analytics, crash reporting) for whether they ship their own manifest or require the app to declare on their behalf.

## Step 4 — Google Play Console requirements

- Data Safety form: cross-reference against Step 1's actual data collection (location, contacts, etc.) — mismatches between declared and actual behavior are a policy violation, not just a review comment.
- App signing: confirm Play App Signing is enabled (not just a local keystore) for new apps.
- Target API level: re-verify against Step 2's check — this is the single most common automatic-rejection reason for updates to existing apps.

## Step 5 — Apple App Store Review Guidelines — common rejection patterns

Beyond permissions (Step 3), scan for the patterns that trigger the most first-submission rejections: placeholder/lorem-ipsum content, broken links (support URL, privacy policy URL), sign-in-required apps without a demo account provided in review notes, and crashes on launch on the primary supported device size. Flag any found; don't assume they're fine because the code compiles.

## Step 6 — Release readiness (what rejects nothing but breaks production)

Store policy is half the risk. Check each item and report it with the same ✅/⚠️/❌ scale:

1. **Production configuration, not test.** Open the bundled backend/Firebase config (`google-services.json`, `GoogleService-Info.plist`, `.env`, flavor files): project id, bundle id/application id and API hosts must be the production ones. A tracked test config that the release script does not replace is a ❌.
2. **Version and build number** bumped on both platforms, consistent with each other, and no debug flags, test endpoints or verbose logging in the release variant.
3. **Force-update path exists in the version that is already live.** You can only force users off a version that ships the minimum-version check. Record whether this release can later be forced, and recommend: optional update during the staged rollout, forced once crash-free sessions hold above the team's threshold.
4. **Staged rollout plan**: Play staged percentage and App Store phased release, a halt criterion (for example crash-free sessions below 99.5%), and who receives the alerts.
5. **Crash reporting is usable**: alerts configured; if code obfuscation/minification is on, the mapping or dSYM upload step exists in the release pipeline, otherwise crash reports arrive unreadable.
6. **App attestation (Firebase App Check, Play Integrity, App Attest/DeviceCheck)**: the provider is registered before SDK initialization; enforcement stays in monitoring mode until most of the install base runs a version that ships the provider. Enforcing in the same release that introduces it is a ❌.
7. **Deep links**: `assetlinks.json` and `apple-app-site-association` are reachable and list the release signing SHA-256 and team id, not only the debug ones.
8. **Analytics and attribution events** were verified once on a release build: purchase fires once per order with value and currency. Hand the detail to mobile-analytics-guard when it is installed.
9. **Post-upload checks scheduled**: read the Play pre-launch report after the internal upload; install the TestFlight build on at least one real device per platform.
10. **Dependency end-of-life notices** with a date (an SDK dropping a package manager or a platform minimum) are listed so the next release plans for them.

## Step 7 — Present the compliance report

List, per platform: ✅ what's already compliant, ⚠️ what needs a fix (with the fix applied or a clear next step if it needs a human decision like a demo account), and ❌ anything that would cause automatic/likely rejection if submitted as-is right now. Don't soften a genuine rejection risk into "should be fine" — this report exists so nothing surprises the user during actual review.
