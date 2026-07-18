# Flutter Integration Templates

## GoRouter — adding a route to an existing router config

**Before (existing `app_router.dart`, do not replace — extend it):**
```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
  ],
);
```

**After (added {Name} route with BlocProvider wiring):**
```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
    GoRoute(
      path: '/{name}/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BlocProvider(
          create: (_) => getIt<{Name}Bloc>()..add(Load{Name}Requested(id)),
          child: const {Name}Page(),
        );
      },
    ),
  ],
);

// Call site — wherever the user should navigate TO this feature from
context.go('/{name}/$userId');
```

## Injectable/GetIt — confirming registration

**lib/core/di/injection.dart** (existing, generated file — do not hand-edit):
```dart
@InjectableInit()
void configureDependencies() => getIt.init();
```

After running `build_runner`, `injection.config.dart` should now contain entries for the new feature's `@injectable`/`@LazySingleton` classes automatically — verify with:
```bash
grep -c "{Name}Bloc\|{Name}RepositoryImpl" lib/core/di/injection.config.dart
```
A result of `0` means the feature files aren't in the compiled `lib/` tree yet, or the annotations are missing/malformed — fix that before re-running `build_runner`, don't just re-run it repeatedly hoping it picks them up.

## pubspec.yaml — dependencies to reconcile

```yaml
dependencies:
  flutter_bloc: ^8.1.0
  equatable: ^2.0.5
  get_it: ^7.6.0
  injectable: ^2.3.0
  dio: ^5.4.0
  dartz: ^0.10.1        # or fpdart, match whichever this project already uses

dev_dependencies:
  injectable_generator: ^2.4.0
  build_runner: ^2.4.0
  mocktail: ^1.0.0
  bloc_test: ^9.1.0
```

## Build verification commands

```bash
flutter analyze
flutter test
flutter pub run build_runner build --delete-conflicting-outputs   # if DI wiring changed
```

If `flutter analyze` fails at this integration step specifically, the most common causes are: the route path colliding with an existing one, a missing import for the new feature's Bloc/Page in the router file, or `injection.config.dart` being stale because `build_runner` wasn't re-run after adding the feature's `@injectable` classes.
