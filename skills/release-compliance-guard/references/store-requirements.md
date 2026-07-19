# Store Requirements Reference

## Apple App Store

### Privacy Manifest (`PrivacyInfo.xcprivacy`)
Required when the app or a bundled third-party SDK uses any API Apple classifies as a "required reason" API — most commonly:
- `UserDefaults`
- File timestamp APIs (`creationDate`, `modificationDate`, etc.)
- Disk space APIs
- System boot time / active keyboard APIs

Check each third-party SDK's own documentation for whether it ships its own privacy manifest bundled (most major analytics/crash SDKs do by now) — if it doesn't, the app's own manifest must declare that reason on the SDK's behalf.

### App Tracking Transparency (ATT)
Required if the app engages in "tracking" per Apple's definition — linking user/device data collected from the app with data from other companies' apps/sites/offline sources for advertising or ad-measurement, or sharing with a data broker. This is broader than "shows ads" — it includes third-party analytics SDKs that correlate data across apps.

If tracking applies:
1. Add `NSUserTrackingUsageDescription` to `Info.plist`.
2. Call `ATTrackingManager.requestTrackingAuthorization` before any tracking-related SDK initialization or IDFA access.
3. Respect the user's choice — if denied, don't attempt to track anyway via a workaround (this is a guideline violation, not just a bad practice).

### Common first-submission rejection reasons (beyond permissions)
- Placeholder/lorem-ipsum content, or "Coming Soon" screens shipped as final.
- Broken support URL or privacy policy URL in App Store Connect metadata.
- Sign-in-required app with no demo account credentials provided in the review notes field.
- Crash or hang on launch on the primary supported device/OS version — test on the actual minimum supported OS version, not just the latest.
- Metadata (screenshots, description) not matching actual app functionality.

## Google Play

### Data Safety form
Must accurately reflect actual data collection/sharing behavior found in Step 1 of `SKILL.md` (location, contacts, camera, etc.). A mismatch between the form and actual app behavior is treated as a policy violation during review and can trigger removal even after initial approval, not just a submission-time rejection.

### Target API level
Google Play requires apps to target an API level within one year of the latest Android release for new apps and updates to existing apps — this requirement moves every year. Do not trust a previously-known number; verify the current requirement before final submission, since submitting below the current floor is an automatic rejection regardless of anything else in the app.

### Play App Signing
New apps should use Play App Signing (Google manages the app signing key; the developer keeps an upload key) rather than a purely local keystore — required for some distribution features (like Play Asset Delivery) and recommended as the default for new apps.

### Permissions
Unused dangerous permissions declared in the manifest (see `SKILL.md` Step 2) are flagged by Play's automated review and can delay approval even without a Data Safety mismatch — remove anything not backed by an actual, active code path.
