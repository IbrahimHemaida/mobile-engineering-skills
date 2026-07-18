# Android Integration Templates

## Compose Navigation — adding a route to an existing NavHost

**Before (existing `AppNavHost.kt`, do not replace — extend it):**
```kotlin
NavHost(navController = navController, startDestination = Routes.HOME) {
    composable(Routes.HOME) { HomeScreen(navController) }
    composable(Routes.SETTINGS) { SettingsScreen(navController) }
}
```

**After (added {Name} route + navigation call site):**
```kotlin
NavHost(navController = navController, startDestination = Routes.HOME) {
    composable(Routes.HOME) { HomeScreen(navController) }
    composable(Routes.SETTINGS) { SettingsScreen(navController) }
    composable(
        route = "${Routes.{NAME_UPPER}}/{id}",
        arguments = listOf(navArgument("id") { type = NavType.StringType })
    ) { backStackEntry ->
        {Name}Screen(id = backStackEntry.arguments?.getString("id").orEmpty())
    }
}

// Routes.kt — add alongside existing route constants
object Routes {
    const val HOME = "home"
    const val SETTINGS = "settings"
    const val {NAME_UPPER} = "{name}"
}

// Call site — wherever the user should navigate TO this feature from
navController.navigate("${Routes.{NAME_UPPER}}/$userId")
```

## Multi-module Gradle wiring

**settings.gradle.kts** — add the feature module:
```kotlin
include(":feature:{name}")
```

**app/build.gradle.kts** — add the feature as a dependency of :app:
```kotlin
dependencies {
    implementation(project(":feature:{name}"))
}
```

**feature/{name}/build.gradle.kts** — the feature module's own dependencies (adjust to match the project's existing version catalog references, don't hardcode versions if `libs.versions.toml` exists):
```kotlin
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("com.google.dagger.hilt.android")
    id("com.google.devtools.ksp")
}

dependencies {
    implementation(project(":core:domain"))       // adjust to actual core module names
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)
    implementation(libs.retrofit)
    implementation(libs.room.runtime)
    ksp(libs.room.compiler)
    implementation(libs.androidx.compose.ui)

    testImplementation(libs.mockk)
    testImplementation(libs.turbine)
    testImplementation(libs.kotlinx.coroutines.test)
    androidTestImplementation(libs.compose.ui.test.junit4)
}
```

## Build verification command

Single-module project:
```bash
./gradlew compileDebugKotlin
```

Multi-module project (verify just the new feature module first, faster feedback):
```bash
./gradlew :feature:{name}:compileDebugKotlin
./gradlew :app:assembleDebug   # full integration check
```

If either fails, read the actual compiler error — don't guess. Common causes at this integration step specifically: missing module dependency edge (Step 3), a route argument type mismatch, or a Hilt component the feature module can't see because the dependency direction is backwards (feature module depending on :app instead of the reverse).
