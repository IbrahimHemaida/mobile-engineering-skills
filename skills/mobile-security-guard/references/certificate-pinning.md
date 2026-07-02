# Certificate Pinning — Extended Reference

## Why pinning, beyond "TLS is already encrypted"

Standard TLS verification only proves the server presented a certificate signed by *some* CA the OS trusts. It does not prove the certificate belongs to your actual backend. Any of the following can produce a technically-valid cert an unpinned app will accept without complaint:

- A compromised or coerced CA (has happened at nation-state and commercial scale).
- A corporate/airport/hotel Wi-Fi MITM proxy with its own trusted root pushed to the device.
- A malicious profile or root cert installed on a compromised or "security research" device.

Pinning narrows trust from "any CA in the OS trust store" to "specifically this key/cert," closing that gap for the app's own traffic.

## Android: Network Security Config (preferred, declarative)

`res/xml/network_security_config.xml`:

```xml
<network-security-config>
    <domain-config>
        <domain includeSubdomains="true">api.yourbackend.com</domain>
        <pin-set expiration="2027-01-01">
            <pin digest="SHA-256">base64-spki-hash-of-current-leaf-or-intermediate=</pin>
            <pin digest="SHA-256">base64-spki-hash-of-backup-cert=</pin>
        </pin-set>
    </domain-config>
    <base-config cleartextTrafficPermitted="false" />
</network-security-config>
```

Referenced from `AndroidManifest.xml`:

```xml
<application android:networkSecurityConfig="@xml/network_security_config" ... >
```

**Getting the SPKI hash** for a cert you control:

```bash
openssl x509 -in cert.pem -pubkey -noout | \
  openssl pkey -pubin -outform der | \
  openssl dgst -sha256 -binary | \
  base64
```

**Set an `expiration` date** on the pin-set so an app that misses an update fails safe (falls back to normal TLS validation) rather than being permanently bricked by a rotated cert it can no longer talk to.

## Android: OkHttp CertificatePinner (programmatic, more control)

```kotlin
val certificatePinner = CertificatePinner.Builder()
    .add("api.yourbackend.com", "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
    .add("api.yourbackend.com", "sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=") // backup
    .build()

val client = OkHttpClient.Builder()
    .certificatePinner(certificatePinner)
    .build()
```

Use this when the app already configures OkHttp manually (Retrofit setups) — it keeps pinning logic in code review rather than a separate XML resource, at the cost of needing an app update to rotate pins (same tradeoff as the XML approach; there's no free lunch here without a remote-config-driven pin list, which introduces its own trust problem).

## Flutter: pinning via dio

```dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';

final dio = Dio();
(dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  final client = HttpClient();
  client.badCertificateCallback = (cert, host, port) {
    final expectedFingerprints = [
      'AA:BB:CC:...', // current
      'DD:EE:FF:...', // backup
    ];
    final actual = sha256Fingerprint(cert); // compute SHA-256 of cert.der
    return expectedFingerprints.contains(actual);
  };
  return client;
};
```

Prefer a maintained package (e.g. `http_certificate_pinning` or `dio_certificate_pinning`) over hand-rolled `badCertificateCallback` logic where possible — hand-rolled implementations are a common source of subtly-wrong comparisons (e.g. comparing the wrong part of the chain, or a fingerprint mismatch that silently falls back to "trust anyway").

## Backup pins and rotation strategy

Never ship with a single pin. A minimal safe rotation plan:

1. Pin the current leaf (or intermediate) certificate's SPKI hash.
2. Also pin the SPKI hash of the certificate you intend to rotate to next (obtainable in advance if you control the CSR/key ahead of the actual rotation).
3. Set a pin-set expiration a few months out, sized to your app update cadence, so an app that somehow never updates fails open into normal TLS validation rather than becoming permanently unable to reach the backend.
4. When rotation happens, ship an app update adding the *next-next* pin before removing the now-retired one — treat pin lists like a rolling window, not a single swap.

## Pinning at the intermediate vs. leaf level

- **Leaf pinning**: tightest security, but breaks on every cert renewal unless the backup-pin process above is followed rigorously.
- **Intermediate CA pinning**: survives leaf renewals (common when using a managed cert provider that auto-rotates leaves under the same intermediate), at the cost of trusting anything else that same intermediate signs. Reasonable tradeoff for teams that can't guarantee tight app-update cadence.

## Common mistakes

- Pinning to a certificate you don't control the rotation of (e.g. a third-party CDN's default cert) — you'll break on their schedule, not yours.
- Testing pinning only against production and never verifying the "wrong pin" path actually rejects a MITM proxy (e.g. Charles/Burp) in a staging build.
- Leaving a "disable pinning for debug builds" flag that isn't actually stripped from release (see mobile-security-guard imperative #19).
- Pinning the wrapper/CDN cert but not realizing traffic sometimes falls back to a different CDN edge with a different cert chain — verify across the actual production edge network, not just one test request.
