---
name: release-compliance-guard
description: Review an Android/Kotlin or Flutter app before store submission — verify every permission declared matches an actual feature in use (no more, no less), and check Apple App Store and Google Play requirements that commonly cause rejection (Privacy Manifest, App Tracking Transparency, Data Safety form, target SDK level, usage-description strings). Use when the user says "prepare for release", "check store compliance", "review permissions", "get this ready for App Store/Play submission", or before any production build upload.
argument-hint: [optional: target store — "ios", "android", or both]
---

# Release Compliance Guard

A pre-submission review, not a scaffolder — this skill finds and reports gaps between what the app actually does and what the store manifests/permissions declare, then fixes them. Read `references/permission-mapping.md` and `references/store-requirements.md` before reviewing.

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

- Every permission-requiring API from Step 1 needs its matching `NSXxxUsageDescription` key with an actual, specific, human-readable string explaining *why* — "This app needs your location" is a common rejection reason for being too generic; "Used to show nearby stores" passes.
- If the app uses `IDFA`/advertising attribution or any cross-app/cross-site tracking: `NSUserTrackingUsageDescription` is required, and the app must call the App Tracking Transparency (ATT) prompt before any tracking — check `references/store-requirements.md` for what counts as "tracking" under Apple's definition, since it's broader than just ads.
- `PrivacyInfo.xcprivacy` (Privacy Manifest): required if the app or any SDK it bundles uses APIs Apple classifies as requiring a declared reason (e.g. `UserDefaults`, file timestamp APIs, disk space APIs) — check third-party SDKs in use (analytics, crash reporting) for whether they ship their own manifest or require the app to declare on their behalf.

## Step 4 — Google Play Console requirements

- Data Safety form: cross-reference against Step 1's actual data collection (location, contacts, etc.) — mismatches between declared and actual behavior are a policy violation, not just a review comment.
- App signing: confirm Play App Signing is enabled (not just a local keystore) for new apps.
- Target API level: re-verify against Step 2's check — this is the single most common automatic-rejection reason for updates to existing apps.

## Step 5 — Apple App Store Review Guidelines — common rejection patterns

Beyond permissions (Step 3), scan for the patterns that trigger the most first-submission rejections: placeholder/lorem-ipsum content, broken links (support URL, privacy policy URL), sign-in-required apps without a demo account provided in review notes, and crashes on launch on the primary supported device size. Flag any found; don't assume they're fine because the code compiles.

## Step 6 — Present the compliance report

List, per platform: ✅ what's already compliant, ⚠️ what needs a fix (with the fix applied or a clear next step if it needs a human decision like a demo account), and ❌ anything that would cause automatic/likely rejection if submitted as-is right now. Don't soften a genuine rejection risk into "should be fine" — this report exists so nothing surprises the user during actual review.
