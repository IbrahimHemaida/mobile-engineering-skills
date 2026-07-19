# Android Foundation Templates

## core/designsystem/Color.kt

```kotlin
private val SeedColor = Color(0xFF0A84FF) // replace with the brand color passed in $ARGUMENTS, if any

val LightColorScheme = lightColorScheme(
    primary = SeedColor,
    onPrimary = Color.White,
    surface = Color(0xFFFDFDFD),
    onSurface = Color(0xFF1A1A1A),
    error = Color(0xFFBA1A1A),
)

val DarkColorScheme = darkColorScheme(
    primary = SeedColor,
    onPrimary = Color.Black,
    surface = Color(0xFF1A1A1A),
    onSurface = Color(0xFFE6E6E6),
    error = Color(0xFFFFB4AB),
)
```

## core/designsystem/Dimens.kt

```kotlin
object Dimens {
    val spacingXSmall = 4.dp
    val spacingSmall = 8.dp
    val spacingMedium = 16.dp
    val spacingLarge = 24.dp
    val spacingXLarge = 32.dp
    val minTouchTarget = 48.dp   // matches mobile-accessibility-guard's minimum
    val cornerRadiusMedium = 12.dp
}
```

## core/designsystem/Theme.kt

```kotlin
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false, // brand palette is the default look, not device wallpaper color
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            if (darkTheme) dynamicDarkColorScheme(LocalContext.current)
            else dynamicLightColorScheme(LocalContext.current)
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography,
        content = content
    )
}
```

## core/designsystem/GlassNavigationBar.kt

```kotlin
// Requires: implementation("dev.chrisbanes.haze:haze:<latest>") for the blur effect.
// Falls back to a solid MaterialTheme surface below API 31 or if Haze isn't added.
@Composable
fun GlassNavigationBar(
    items: List<NavItem>,
    selectedRoute: String,
    onItemClick: (NavItem) -> Unit,
    hazeState: HazeState
) {
    NavigationBar(
        modifier = Modifier
            .hazeChild(state = hazeState, style = HazeStyle(
                tint = MaterialTheme.colorScheme.surface.copy(alpha = 0.6f),
                blurRadius = 24.dp
            )),
        containerColor = Color.Transparent
    ) {
        items.forEach { item ->
            NavigationBarItem(
                selected = selectedRoute == item.route,
                onClick = { onItemClick(item) },
                icon = { Icon(item.icon, contentDescription = item.label) },
                label = { Text(item.label) },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = MaterialTheme.colorScheme.primary,
                    indicatorColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f)
                )
            )
        }
    }
}
```

## core/localization/LocaleManager.kt

```kotlin
object LocaleManager {
    fun setLocale(languageTag: String) {
        val localeList = LocaleListCompat.forLanguageTags(languageTag)
        AppCompatDelegate.setApplicationLocales(localeList)
    }

    fun currentLocale(): String =
        AppCompatDelegate.getApplicationLocales().toLanguageTags().ifEmpty { "en" }
}
```

## core/ui/components/ShimmerBox.kt

```kotlin
@Composable
fun ShimmerBox(
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(Dimens.cornerRadiusMedium)
) {
    val transition = rememberInfiniteTransition(label = "shimmer")
    val translateAnim by transition.animateFloat(
        initialValue = 0f, targetValue = 1000f,
        animationSpec = infiniteRepeatable(tween(1200, easing = LinearEasing)),
        label = "shimmerTranslate"
    )
    val brush = Brush.linearGradient(
        colors = listOf(
            MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
            MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.2f),
            MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
        ),
        start = Offset(translateAnim - 500f, 0f),
        end = Offset(translateAnim, 0f)
    )
    Box(modifier = modifier.clip(shape).background(brush))
}

// Usage example — shape matches what it's standing in for:
// ShimmerBox(modifier = Modifier.size(48.dp), shape = CircleShape)       // avatar placeholder
// ShimmerBox(modifier = Modifier.fillMaxWidth().height(80.dp))           // card placeholder
```

## core/network/NetworkResult.kt

```kotlin
sealed class NetworkResult<out T> {
    data object Loading : NetworkResult<Nothing>()
    data class Success<T>(val data: T) : NetworkResult<T>()
    data class Error(val message: String, val code: Int? = null) : NetworkResult<Nothing>()
}
```

## core/network/NetworkModule.kt

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(authInterceptor: AuthInterceptor): OkHttpClient =
        OkHttpClient.Builder()
            .addInterceptor(authInterceptor)
            .apply {
                if (BuildConfig.DEBUG) {
                    addInterceptor(HttpLoggingInterceptor().apply {
                        level = HttpLoggingInterceptor.Level.BODY
                    })
                }
            }
            .connectTimeout(AppConstants.NETWORK_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .build()

    @Provides
    @Singleton
    fun provideRetrofit(client: OkHttpClient): Retrofit =
        Retrofit.Builder()
            .baseUrl(AppConstants.API_BASE_URL)
            .client(client)
            .addConverterFactory(MoshiConverterFactory.create())
            .build()
}
```

## core/data/BaseRepository.kt

```kotlin
abstract class BaseRepository {
    protected suspend fun <T> safeApiCall(apiCall: suspend () -> T): NetworkResult<T> =
        try {
            NetworkResult.Success(apiCall())
        } catch (e: HttpException) {
            NetworkResult.Error(e.message(), e.code())
        } catch (e: IOException) {
            NetworkResult.Error("Network error — check your connection")
        }
}
```

## core/constants/AppConstants.kt

```kotlin
object AppConstants {
    const val API_BASE_URL = BuildConfig.API_BASE_URL   // set per build variant, never hardcoded here
    const val NETWORK_TIMEOUT_SECONDS = 30L
    const val PAGINATION_PAGE_SIZE = 20
    const val FEATURE_FLAG_NEW_ONBOARDING = false
}
```

**build.gradle.kts (app module) — per-variant `BuildConfig` field example:**
```kotlin
buildTypes {
    debug {
        buildConfigField("String", "API_BASE_URL", "\"https://api-staging.example.com\"")
    }
    release {
        buildConfigField("String", "API_BASE_URL", "\"https://api.example.com\"")
    }
}
```

## core/responsive/WindowSizeClass usage

```kotlin
@Composable
fun AdaptiveLayout(windowSizeClass: WindowSizeClass) {
    when (windowSizeClass.widthSizeClass) {
        WindowWidthSizeClass.Compact -> PhoneLayout()
        WindowWidthSizeClass.Medium -> FoldableOrSmallTabletLayout()
        WindowWidthSizeClass.Expanded -> TabletOrDesktopLayout()
    }
}
```

## .gitignore additions to verify/add

```gitignore
local.properties
*.jks
*.keystore
google-services.json
**/secrets.properties
.env
.env.*
**/release/
```
