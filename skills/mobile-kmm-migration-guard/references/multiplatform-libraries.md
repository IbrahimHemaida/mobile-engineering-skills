# Multiplatform Libraries — Extended Reference

Each section below shows the JVM-only trap, why it fails for Kotlin/Native (iOS), and the multiplatform-safe replacement.

## Date & time: `kotlinx-datetime`, not `java.time`

`java.time` is part of the JVM standard library — it does not exist for the Kotlin/Native target, so any `commonMain` code using it either fails to compile for iOS or was never actually attempted against the iOS target.

```kotlin
// Wrong in commonMain — java.time doesn't exist for Kotlin/Native
import java.time.LocalDate
val today = LocalDate.now()

// Right — kotlinx-datetime works across all Kotlin targets
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime

val now = Clock.System.now()
val today = now.toLocalDateTime(TimeZone.currentSystemDefault()).date
```

Gradle setup (`commonMain` dependencies):

```kotlin
sourceSets {
    commonMain.dependencies {
        implementation("org.jetbrains.kotlinx:kotlinx-datetime:0.6.0")
    }
}
```

## Networking: Ktor client, not OkHttp/Retrofit directly

OkHttp and Retrofit are JVM libraries. A shared `commonMain` networking layer needs a client with a real Kotlin/Native engine.

```kotlin
// commonMain: define the client with platform engines supplied per-target
val httpClient = HttpClient {
    install(ContentNegotiation) {
        json(Json { ignoreUnknownKeys = true })
    }
}

// androidMain dependency
implementation("io.ktor:ktor-client-okhttp:2.3.12") // Ktor's own OkHttp *engine*, fine here — it's the engine, not a direct OkHttp API call in commonMain

// iosMain dependency
implementation("io.ktor:ktor-client-darwin:2.3.12")
```

Note the distinction: using OkHttp as Ktor's *engine* on the Android side (`ktor-client-okhttp`) is fine — it's platform-specific plumbing behind a common interface. The violation is calling OkHttp APIs *directly* from `commonMain` code, bypassing the multiplatform abstraction entirely.

## Serialization: `kotlinx.serialization`, not `Serializable`/Gson/Moshi

`java.io.Serializable` is a JVM mechanism; Gson and Moshi are JVM-only reflection-based libraries. None of these work in `commonMain`.

```kotlin
// Wrong in commonMain
data class User(val id: String, val name: String) : java.io.Serializable

// Right — kotlinx.serialization works across all targets via compiler plugin
@Serializable
data class User(val id: String, val name: String)

val json = Json.encodeToString(user)
val decoded = Json.decodeFromString<User>(json)
```

Gradle setup requires the Kotlin serialization plugin in addition to the runtime dependency:

```kotlin
plugins {
    kotlin("plugin.serialization") version "2.0.20"
}

sourceSets {
    commonMain.dependencies {
        implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.1")
    }
}
```

## Local persistence: SQLDelight, not Room directly

Room is an Android/JVM library (built on top of SQLite via Android's SQLite bindings) and isn't available in `commonMain`. SQLDelight generates typed Kotlin APIs from `.sq` SQL files and provides drivers for both Android and Kotlin/Native.

```sql
-- commonMain: shared.sq
CREATE TABLE User (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL
);

selectAll:
SELECT * FROM User;

insertUser:
INSERT INTO User(id, name) VALUES (?, ?);
```

```kotlin
// commonMain: business logic uses the generated typed API, platform-agnostic
class UserRepository(private val database: AppDatabase) {
    fun getAllUsers(): List<User> = database.userQueries.selectAll().executeAsList()
}

// androidMain: platform driver
val driver = AndroidSqliteDriver(AppDatabase.Schema, context, "app.db")

// iosMain: platform driver
val driver = NativeSqliteDriver(AppDatabase.Schema, "app.db")
```

If a full SQLDelight migration isn't feasible yet, an explicit `expect`/`actual` storage interface (e.g. a simple key-value `expect class SecureStorage`) is an acceptable interim abstraction — the rule is "no Room import in `commonMain`," not "SQLDelight is mandatory on day one."

## Quick reference: what to replace

| JVM-only (don't use in `commonMain`) | Multiplatform-safe replacement |
|---|---|
| `java.time.*` | `kotlinx-datetime` |
| `OkHttp`/`Retrofit` direct calls | Ktor client (`HttpClient`) |
| `java.io.Serializable`, Gson, Moshi | `kotlinx.serialization` |
| Room | SQLDelight, or an `expect`/`actual` storage interface |
| `SharedPreferences`/`NSUserDefaults` direct calls | Multiplatform Settings (`com.russhwolf:multiplatform-settings`) for simple key-value storage |
| `java.util.UUID` | `kotlin.uuid.Uuid` (stable since Kotlin 2.0.20) or a small `expect`/`actual` wrapper on older Kotlin versions |
