---
name: mobile-analytics-guard
description: Review Flutter/Android analytics and attribution instrumentation before release: purchase and revenue events fire once with value and currency, user id reaches the MMP, iOS ATT and SKAdNetwork, deferred deep links, test traffic excluded, and tests that guard it. Use when touching tracking code, when marketing numbers look wrong, or before a release.
---

# mobile-analytics-guard

You are reviewing the code that turns user actions into analytics and attribution events: the analytics SDK (Firebase Analytics or similar), the MMP (Singular, AppsFlyer, Adjust, Branch) and any direct ad-platform SDKs (Meta, TikTok, Snap). One wrong line here does not crash the app; it silently corrupts a month of marketing numbers and the budget decisions made on them. Treat findings with that weight.

## How to use this skill

**Review mode** (default): walk the instrumentation and report findings with the format below. Read-only.

**Guard-pass mode**: after any change to purchase, checkout, login, install or deep-link code, run the self-check before merging.

**Live mode**: when adding an event, apply the imperatives while writing it and add the tests in imperative 9 in the same change.

## Step 1 — Map the instrumentation

```
grep -rn "logEvent\|logPurchase\|trackEvent\|revenue\|Singular\|AppsFlyer\|Adjust\|FacebookAppEvents\|TikTok" lib/ --include=*.dart
grep -n "firebase_analytics\|singular\|appsflyer\|adjust\|facebook_app_events\|tiktok" pubspec.yaml
```

Produce one table: event name, where it fires, which SDKs receive it, payload fields. Every finding below refers to a row of this table.

## Always-applied imperatives

1. **One revenue event per order, per SDK.** The purchase event fires from exactly one place (the confirmed-order callback), guarded by the order id so a retry, a rebuilt widget, a resumed app or a second navigation to the success screen cannot fire it again. A duplicate purchase inflates every downstream number by the duplicate rate.
2. **Value and currency on every revenue event**, in the currency the backend charges, as a number not a string. Downstream tools convert; the app never pre-converts.
3. **A stable customer id reaches the MMP** (`setCustomUserId` or equivalent) at login and is cleared at logout, so new-vs-returning and cross-device joins are possible. Never send email or phone as the id; send the backend's customer id.
4. **One event dictionary.** Names and parameters are identical across SDKs and documented in one file in the repo; the same action never has two names. Standard names (`purchase`, `add_to_cart`, `sign_up`) are used where the platform defines them.
5. **iOS consent and SKAdNetwork.** The ATT prompt is requested at a deliberate moment before any IDFA use; `NSUserTrackingUsageDescription` exists; SKAdNetwork ids for every ad network are in `Info.plist`; the conversion value schema is set once and documented. No tracking call runs before the consent result.
6. **Install attribution survives the install.** Deferred deep links and UTM parameters are read on first launch and forwarded to the backend with the first order, so the backend can later be joined to the MMP.
7. **Test traffic is excluded.** Debug builds, the test backend project and internal testers never reach production analytics (separate project, debug flag, or tester exclusion). Mock orders in a release build are a Critical finding.
8. **No PII in event parameters** (names, phones, addresses, full order lines). Ids and amounts only.
9. **Tests exist for the money path.** A unit test that the purchase event is emitted exactly once with order id, value and currency; a widget test that rebuilding or re-entering the success screen does not emit a second event; a test that logout clears the user id.
10. **Reconcile monthly.** Backend orders, MMP attributed orders and each platform's claimed orders are compared in one table. The backend is the accounting number; the MMP is for allocation; platform dashboards are for optimization only. Platform totals above the MMP's by more than view-through and window differences explain is a signal to re-check imperatives 1 to 7.

## Findings report format

```
[SEVERITY] Short title
File: path/to/file.dart:line
Issue: one sentence.
Effect on numbers: which metric is wrong, in which direction, roughly by how much.
Fix: specific remediation (imperative #).
```

**Critical** = revenue counted twice or not at all, test orders in production data, tracking before consent. **High** = missing currency/value, missing user id, event name mismatch across SDKs. **Medium** = SKAdNetwork schema undocumented, UTM lost on install. **Low** = naming or dictionary hygiene.

## Self-check before delivery

- [ ] Purchase fires once per order id, from one place, with value and currency
- [ ] Customer id set at login, cleared at logout
- [ ] Event names identical across SDKs and listed in the dictionary file
- [ ] ATT requested before IDFA use; SKAdNetwork ids present
- [ ] Deferred deep link / UTM forwarded with the first order
- [ ] Debug and test traffic excluded from production analytics
- [ ] No PII in parameters
- [ ] Tests from imperative 9 present and green

## What this skill does not do

- Configure ad-platform dashboards or attribution windows.
- Decide marketing budget; it only makes the numbers trustworthy enough to decide on.
- Replace mobile-security-guard for secret handling in SDK keys.
