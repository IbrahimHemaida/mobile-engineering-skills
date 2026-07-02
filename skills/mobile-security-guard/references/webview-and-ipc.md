# WebViews, Deep Links & IPC — Extended Reference

Any surface where the app accepts input it didn't generate itself — a WebView loading a page, a deep link tapped from outside the app, an intent sent by another installed app — is untrusted input, no different in principle from a network request hitting a backend API. Treat it that way.

## WebView JavaScript bridges

`addJavascriptInterface` (Android) / `JavascriptChannel` (Flutter `webview_flutter`) expose native methods to whatever JavaScript is running in the WebView. If that WebView can ever load a URL you don't fully control — including via a redirect, an ad, or user-supplied content — the bridge is reachable by that content too.

**Safe pattern:**

```kotlin
webView.settings.javaScriptEnabled = true // only if actually needed
webView.addJavascriptInterface(SafeBridge(), "NativeBridge")

webView.webViewClient = object : WebViewClient() {
    override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
        val host = request.url.host
        return if (host != "trusted-first-party-domain.com") {
            // block navigation away from the trusted origin, or open externally instead
            true
        } else false
    }
}
```

The bridge class itself should expose the minimum surface — not a generic "eval this" method, and every exposed method validates its arguments as if they came from an attacker, because in a hostile-content scenario, they did.

**Additional hardening:**
- `setAllowFileAccess(false)` and `setAllowContentAccess(false)` unless the app specifically needs to load local files into the WebView.
- Never load `file://` URLs alongside an active JS bridge — this is a well-known path to reading arbitrary app-private files via crafted JS.
- If the WebView only ever needs to render first-party content (e.g. a ToS page, a help center you control), consider whether a WebView is even necessary versus a native screen or a stripped-down rendering with JS disabled entirely.

## Deep links and App Links

A deep link handler receives attacker-controllable input by definition — any app, or a webpage with a crafted link, can invoke it.

```kotlin
// Untrusted input:
val userId = intent.data?.getQueryParameter("userId")

// Wrong: use directly
loadUserProfile(userId) // could be any string, including another user's ID or injection payload

// Right: validate before use
val validUserId = userId?.takeIf { it.matches(Regex("^[a-zA-Z0-9-]{1,64}$")) }
    ?: return showInvalidLinkError()
// AND verify server-side that the current authenticated session is actually allowed to view that ID
```

The validation isn't just format-checking — the backend call that follows must independently authorize the request against the current session. A deep link parameter should never be trusted to imply authorization on its own (classic IDOR-style mistake ported to mobile).

**Android App Links vs. custom scheme deep links**: prefer verified App Links (`https://yourapp.com/...` with `assetlinks.json` verification) over custom URI schemes (`yourapp://...`) where possible — custom schemes can be claimed by any other installed app, letting a malicious app register the same scheme and potentially intercept or spoof links intended for your app.

## Exported components

```xml
<!-- Default-safe: not reachable by other apps -->
<activity android:name=".internal.SettingsActivity" android:exported="false" />

<!-- Intentionally exported: has an actual reason (deep link entry point) -->
<activity android:name=".DeepLinkHandlerActivity" android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" android:host="yourapp.com" />
    </intent-filter>
</activity>
```

Since Android 12, `exported` must be explicitly declared for any component with an intent-filter, which helps catch accidental exposure at build time — but components *without* an intent-filter can still be marked `exported="true"` by mistake and remain silently reachable. Audit all four component types (Activity, Service, BroadcastReceiver, ContentProvider), not just Activities.

**ContentProviders deserve extra scrutiny**: an exported provider with broad `<path-permission>` or no permission at all can leak an entire local database to any app that queries it. If a provider only needs to serve data to your own app's components, don't export it — use `FileProvider` scoped grants for the specific cross-app sharing case (e.g. sharing a file with another app via `Intent.ACTION_SEND`) instead of a broadly exported provider.

## Clipboard and screenshot leakage

```kotlin
// Sensitive screen (OTP entry, full card number, health record detail):
window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
```

`FLAG_SECURE` blocks both screenshots and the thumbnail shown in the OS app-switcher — without it, a screen showing sensitive data is captured into the recent-apps preview automatically, readable by anyone who picks up an unlocked device and swipes to recents.

**Clipboard**: as of Android 13, the OS shows a "pasted from X" toast automatically, and apps can mark clipboard content as sensitive (`ClipDescription.EXTRA_IS_SENSITIVE`) so the system clipboard preview doesn't render it. For OTP/password fields, consider disabling copy entirely via the input field's configuration rather than relying on OS-level clipboard sensitivity flags alone, since clipboard history tools on some devices/launchers can still retain content.

## Flutter-specific notes

- `webview_flutter`'s `JavascriptChannel` follows the same bridge-exposure logic as Android's `addJavascriptInterface` — scope it, validate arguments, and restrict navigation with `NavigationDelegate.onNavigationRequest`.
- Deep link handling via `go_router`/`onGenerateRoute` should validate route parameters the same way as the Android example above — Flutter's routing doesn't add any implicit trust boundary.
- Screenshot blocking on Flutter typically requires a platform channel calling into `FLAG_SECURE` (Android) / the iOS equivalent (there's no pure-Dart cross-platform primitive for this) — packages like `flutter_windowmanager` wrap this, or write a small platform channel directly if you want to avoid an extra dependency.
