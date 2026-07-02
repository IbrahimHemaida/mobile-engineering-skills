# Secure Local Storage — Extended Reference

## The core question before choosing a storage mechanism

Not "how do I encrypt this?" but **"does this need to be on the device at all?"** The cheapest way to prevent local-storage leaks is not storing sensitive data locally in the first place — fetch it on demand, cache only what's needed for the current session, and clear it aggressively. Encryption is the second line of defense, not the first.

## Android options, ranked by sensitivity

| Data | Recommended storage | Notes |
|---|---|---|
| Auth/refresh tokens | `EncryptedSharedPreferences` (Jetpack Security) or Keystore-backed | Never plain `SharedPreferences` |
| User PII (name, email, address) | `EncryptedSharedPreferences` or encrypted Room (SQLCipher) | Depends on volume — small fields vs. structured records |
| Health/financial records | Encrypted Room (SQLCipher) + Keystore-wrapped key | Regulatory-grade data gets the strongest layer available |
| Non-sensitive prefs (theme, locale) | Plain `SharedPreferences` | Encrypting this is wasted complexity |
| Cached images/API responses with PII | Encrypted cache dir, or don't cache to disk at all | Glide/Coil disk caches are plaintext by default |

### EncryptedSharedPreferences setup

```kotlin
val masterKey = MasterKey.Builder(context)
    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
    .build()

val encryptedPrefs = EncryptedSharedPreferences.create(
    context,
    "secure_prefs",
    masterKey,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
)
```

The master key itself lives in the Android Keystore (hardware-backed on most modern devices), not in the app's storage — that's the actual root of trust, not the encryption algorithm choice.

### Room + SQLCipher for structured sensitive data

```kotlin
val passphrase: ByteArray = SQLiteDatabase.getBytes(keystoreDerivedPassphrase.toCharArray())
val factory = SupportFactory(passphrase)

Room.databaseBuilder(context, AppDatabase::class.java, "secure.db")
    .openHelperFactory(factory)
    .build()
```

Derive `keystoreDerivedPassphrase` from the Keystore, not from a hardcoded string — otherwise you've just moved the hardcoded secret from SharedPreferences into your database config.

## Flutter: flutter_secure_storage

```dart
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

await storage.write(key: 'refresh_token', value: token);
final token = await storage.read(key: 'refresh_token');
```

This wraps Android Keystore / iOS Keychain under the hood — it is not just an encrypted file, it's backed by the platform's hardware security module where available. Do not use plain `shared_preferences` (the Flutter package) for anything sensitive; it is unencrypted plist/XML under the hood, equivalent to Android's plain `SharedPreferences`.

**iOS Keychain accessibility levels matter**: `first_unlock` (readable after first unlock post-boot, works for background refresh) vs `whenUnlockedThisDeviceOnly` (tightest, but breaks background token refresh) — pick based on whether the app needs background access to the token, not by default/copy-paste.

## Biometric-gated storage

Gating *decryption*, not just UI navigation, is the distinction that matters:

```kotlin
val cipher = getKeystoreBackedCipher() // Cipher tied to a BiometricPrompt.CryptoObject
val promptInfo = BiometricPrompt.PromptInfo.Builder()
    .setTitle("Unlock")
    .build()

biometricPrompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(cipher))
// Only on successful auth does the CryptoObject's Cipher actually decrypt the stored value
```

If biometric success just flips a boolean that unlocks a screen — while the underlying encrypted (or worse, plaintext) data was readable via a different code path all along — the biometric gate provides no real protection.

## Session lifecycle and clearing data

On logout, clear in this order:
1. Secure storage (tokens, credentials) — `storage.deleteAll()` / `EncryptedSharedPreferences.edit().clear()`.
2. In-memory app state (user object in memory, cached auth headers on the HTTP client).
3. Disk caches that may contain PII — image loader disk cache (Glide/Coil `clearDiskCache()`), any manually-written cache files.
4. Database rows scoped to the user, if the app supports multiple accounts on one device and doesn't need offline history preserved across accounts.

**Shared-device consideration**: if the app is plausibly used on a shared or family device (common for some healthcare, banking, or kiosk-style apps), a logout that leaves cached screens reachable via the OS "recent apps" thumbnail or leaves a previous user's data in an unlocked cache is a real-world leak vector, not a theoretical one — combine with `FLAG_SECURE` on sensitive screens.

## What should never be on-device at all, encrypted or not

- Full card numbers (PAN) — use tokenization from a PCI-compliant payment processor; store only a token/last-4.
- Long-term audit logs of sensitive actions — belongs server-side.
- Other users' data in a multi-tenant app, even transiently cached for a "recently viewed" feature, unless the current session is authorized to view it.
- Government ID numbers, full health records beyond what's needed for the current session's UI — fetch on demand, don't persist "just in case it's needed again."
