# Permission Mapping — API Usage to Required Permission

| Code pattern detected | Android permission (`AndroidManifest.xml`) | iOS `Info.plist` key |
|---|---|---|
| `CameraX`, `Camera`, `image_picker` (camera source) | `android.permission.CAMERA` | `NSCameraUsageDescription` |
| `ImagePicker` gallery-only, `photo_manager` | `READ_MEDIA_IMAGES` (API 33+) / `READ_EXTERNAL_STORAGE` (below) | `NSPhotoLibraryUsageDescription` |
| `FusedLocationProviderClient`, `Geolocator`, `location` package | `ACCESS_FINE_LOCATION` and/or `ACCESS_COARSE_LOCATION` | `NSLocationWhenInUseUsageDescription` (+ `NSLocationAlwaysAndWhenInUseUsageDescription` if background) |
| `BluetoothAdapter`, `flutter_blue_plus` | `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` (API 31+) | `NSBluetoothAlwaysUsageDescription` |
| `ContactsContract`, `contacts_service`, `flutter_contacts` | `READ_CONTACTS` (+ `WRITE_CONTACTS` if editing) | `NSContactsUsageDescription` |
| `MediaRecorder`, `record` package (audio) | `RECORD_AUDIO` | `NSMicrophoneUsageDescription` |
| `NotificationManager`, `firebase_messaging` | `POST_NOTIFICATIONS` (API 33+) | (no Info.plist key — handled via `UNUserNotificationCenter` request) |
| Calendar read/write, `device_calendar` | `READ_CALENDAR` / `WRITE_CALENDAR` | `NSCalendarsUsageDescription` |
| Biometric auth, `local_auth` | `USE_BIOMETRIC` / `USE_FINGERPRINT` | `NSFaceIDUsageDescription` |
| Any IDFA/ad-attribution SDK, cross-app tracking | — | `NSUserTrackingUsageDescription` (+ ATT prompt before use) |

## Runtime request reminder (Android 6.0+ / API 23+)

A manifest declaration is necessary but not sufficient for dangerous permissions. Confirm the code actually requests at runtime:

```kotlin
val launcher = rememberLauncherForActivityResult(
    ActivityResultContracts.RequestPermission()
) { granted -> /* handle result */ }

launcher.launch(Manifest.permission.CAMERA)
```

```dart
final status = await Permission.camera.request();
if (status.isGranted) { /* proceed */ }
```

## Writing a passing usage-description string (iOS)

Rejected pattern: generic, doesn't explain purpose.
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location.</string>
```

Passing pattern: specific to what the feature actually does.
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to show nearby store locations and estimated delivery times.</string>
```
