# Interop & Concurrency — Extended Reference

## Kotlin/Native memory model

Modern Kotlin/Native uses the new memory model (default since Kotlin 1.7.20, mandatory since 1.9), which removed the older "frozen state" requirement where objects shared across threads had to be explicitly frozen and became immutable. This is a real improvement, but it changes the failure mode rather than eliminating it:

- **Old model**: sharing mutable state across threads without freezing threw an `InvalidMutabilityException` — loud and immediate.
- **New model**: the same unsynchronized sharing compiles and runs, and may work most of the time, until it doesn't — a race condition instead of a crash, which is strictly harder to catch in review or QA.

**Practical rule**: treat shared mutable state across threads the same way you would in any concurrent Kotlin/JVM code — `Mutex`, `StateFlow`/`MutableStateFlow` (single-writer, many-reader is safe), or confining mutation to a single coroutine/dispatcher. Don't rely on "it's KMM, the new memory model handles it."

```kotlin
// Unsafe: a plain var mutated from multiple coroutine contexts
class Counter {
    var count = 0 // no synchronization
    fun increment() { count++ }
}

// Safe: confine mutation through a single-writer StateFlow
class Counter {
    private val _count = MutableStateFlow(0)
    val count: StateFlow<Int> = _count.asStateFlow()
    fun increment() { _count.update { it + 1 } }
}
```

## `Dispatchers.Main` on both platforms

`Dispatchers.Main` maps to the real UI thread on both Android and iOS when using `kotlinx-coroutines-core` with the correct platform artifacts — but two things commonly go wrong:

1. **Test code substituting a dispatcher that no-ops** instead of actually verifying main-thread affinity, which hides bugs that only appear against the real main thread.
2. **iOS main-thread blocking is punished harder than Android's.** An Android ANR gives the user a "wait/close" dialog after ~5 seconds. iOS's watchdog can terminate the app for blocking the main thread for a much shorter window during app launch or in response to certain system events — "it felt fine when I tested on Android" is not evidence it's safe on iOS.

```kotlin
// Wrong: any accidental blocking call here degrades far worse on iOS
suspend fun loadUserProfile() = withContext(Dispatchers.Main) {
    val json = File(path).readText() // blocking I/O on the main thread
    parseProfile(json)
}

// Right: keep Main for the minimum needed (UI state update), do work elsewhere
suspend fun loadUserProfile(): Profile = withContext(Dispatchers.Default) {
    val json = readFileText(path) // off Main
    parseProfile(json)
}
```

## Exceptions crossing the Kotlin → Swift boundary

Kotlin exceptions thrown from shared code and left uncaught when called from Swift do not become a normal Swift `throws` error automatically — depending on how the call is set up, this can crash the app in a way that's difficult to trace back to the originating Kotlin call.

**Pattern: convert to a Result-style return at the boundary**

```kotlin
// Shared code: wrap the risky operation, don't let it throw across the boundary
sealed class ApiResult<out T> {
    data class Success<T>(val value: T) : ApiResult<T>()
    data class Failure(val message: String, val cause: Throwable? = null) : ApiResult<Nothing>()
}

suspend fun fetchUser(id: String): ApiResult<User> {
    return try {
        ApiResult.Success(api.getUser(id))
    } catch (e: Exception) {
        ApiResult.Failure(e.message ?: "Unknown error", e)
    }
}
```

This gives the Swift side a normal value to switch/pattern-match on instead of an uncatchable crash. If a lower-level library call genuinely must be allowed to throw into Swift, verify explicitly (with a real on-device test, not just a Kotlin unit test) that it surfaces as a catchable `NSError` rather than terminating the app.

## Sealed classes and enums at the Swift boundary

Kotlin sealed classes and enums do export to Swift, but the generated API can be awkward or lossy for anything beyond simple, non-generic hierarchies:

- A sealed class with generic type parameters may generate a Swift API that's technically usable but verbose enough that Swift consumers work around it rather than with it.
- Kotlin enums with associated data (via a sealed class instead of a true `enum class`) sometimes generate less idiomatic Swift than a straightforward flat enum would.

**Practical check**: before finalizing a sealed class/enum meant to be consumed from Swift, generate the framework and inspect the actual header (`build/xcode-frameworks/.../Shared.h` or equivalent, depending on your build setup) rather than assuming the Kotlin definition is a good API purely from reading the Kotlin source.

## Nullability across the boundary

Kotlin nullable types (`String?`) map to Swift `Optional` (`String?`) for simple cases, but verify this explicitly for:
- **Generic types**: `List<String?>` vs `List<String>?` — the nullability position matters and isn't always intuitive after export.
- **Function types / lambdas** crossing the boundary — optional closures have their own Swift interop quirks.
- **Platform collection types** — verify a `Map<K, V>` behaves as expected on the Swift side rather than assuming Kotlin and Swift collection semantics are identical.

Write a small Swift-side test or sample call for any non-trivial generic or collection type that crosses the boundary, rather than trusting the Kotlin type signature alone.
