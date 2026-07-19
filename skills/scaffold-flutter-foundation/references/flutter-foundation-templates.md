# Flutter Foundation Templates

## lib/core/theme/app_colors.dart

```dart
class AppColors {
  static const seed = Color(0xFF0A84FF); // replace with the brand color passed in $ARGUMENTS, if any

  static ColorScheme light = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );

  static ColorScheme dark = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );
}
```

## lib/core/theme/app_dimens.dart

```dart
class AppDimens {
  static const spacingXSmall = 4.0;
  static const spacingSmall = 8.0;
  static const spacingMedium = 16.0;
  static const spacingLarge = 24.0;
  static const spacingXLarge = 32.0;
  static const minTapTarget = 48.0;   // matches mobile-accessibility-guard's minimum
  static const cornerRadiusMedium = 12.0;
}
```

## lib/core/theme/app_theme.dart

```dart
class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: AppColors.light,
    textTheme: _textTheme,
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: AppColors.dark,
    textTheme: _textTheme,
  );

  static const _textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );
}

// main.dart wiring
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ThemeMode.system,
  // ...
)
```

## lib/core/widgets/glass_nav_bar.dart

```dart
// Built with Flutter SDK primitives only — no third-party glass package assumed.
class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.6),
            border: Border(top: BorderSide(color: scheme.outline.withOpacity(0.2))),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            items: items,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: scheme.primary,
            unselectedItemColor: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
```

## lib/core/l10n/l10n.yaml

```yaml
arb-dir: lib/core/l10n
template-arb-file: intl_en.arb
output-localization-file: app_localizations.dart
```

**lib/core/l10n/intl_en.arb**
```json
{
  "@@locale": "en",
  "appTitle": "My App",
  "@appTitle": { "description": "The application title" }
}
```

**lib/core/l10n/intl_ar.arb**
```json
{
  "@@locale": "ar",
  "appTitle": "تطبيقي"
}
```

**main.dart wiring**
```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ...
)
```

## lib/core/widgets/app_shimmer.dart

```dart
class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppDimens.cornerRadiusMedium)),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceVariant.withOpacity(0.6),
      highlightColor: scheme.surfaceVariant.withOpacity(0.2),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: Colors.white, borderRadius: borderRadius),
      ),
    );
  }
}

// Usage — shape matches what it's standing in for:
// AppShimmer(width: 48, height: 48, borderRadius: BorderRadius.circular(24))  // avatar placeholder
// AppShimmer(width: double.infinity, height: 80)                              // card placeholder
```

## lib/core/network/dio_client.dart

```dart
@lazySingleton
class DioClient {
  final Dio dio;

  DioClient() : dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: Duration(seconds: AppConstants.networkTimeoutSeconds),
  )) {
    dio.interceptors.add(AuthInterceptor());
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(responseBody: true));
    }
  }
}
```

## lib/core/data/failure.dart

```dart
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
```

## lib/core/constants/app_constants.dart

```dart
class AppConstants {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-staging.example.com',
  );
  static const networkTimeoutSeconds = 30;
  static const paginationPageSize = 20;
  static const featureFlagNewOnboarding = false;
}
```

**Build command using the environment override:**
```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

## lib/core/responsive/breakpoints.dart

```dart
class Breakpoints {
  static const mobile = 600.0;
  static const tablet = 1024.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobile && w < tablet;
  }
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;
}
```

## .gitignore additions to verify/add

```gitignore
.env
.env.*
**/key.properties
**/*.jks
**/google-services.json
**/GoogleService-Info.plist
.dart_tool/
**/ios/Flutter/flutter_export_environment.sh
```
