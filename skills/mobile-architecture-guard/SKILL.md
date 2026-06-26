---
name: mobile-architecture-guard
description: Review Kotlin/Android and Flutter code for SOLID principles, Clean Architecture, modular design, and architectural patterns before merge. Use when reviewing feature implementations, refactoring modules, designing data/domain/presentation layers, or after a coding agent generated mobile code. Apply this for architecture decisions, layer separation, dependency injection, state management, and package structure validation. Works with MVVM, Clean Architecture, feature-based modularization. Use for "review this architecture", "is this layer separation correct?", "check the dependency graph", "validate module boundaries", or after implementing major features.
---

# mobile-architecture-guard

You are reviewing mobile code architecture before it ships. Apply the rules below as an architecture audit after the feature is implemented. This skill validates SOLID principles and Clean Architecture patterns specific to Android/Kotlin and Flutter development.

## Compatibility

This skill works with:
- **Kotlin/Android**: MVVM, Clean Architecture, Jetpack Compose, traditional XML layouts
- **Flutter**: BLoC, Provider, GetX, Clean Architecture patterns
- **Shared**: KMM (Kotlin Multiplatform Mobile), domain-driven design patterns

This skill complements clean-code-guard and test-guard. Use clean-code-guard for function-level code quality, test-guard for test coverage, and this skill for architectural decisions and module boundaries.

## How to use this skill

**Guard-pass mode** (recommended): After implementing a feature or refactoring a module, check the code structure against the architecture imperatives below. Validate layer separation, dependency injection, and package boundaries before merging.

**Live mode** (explicit): When designing a new feature or module, apply these imperatives while architecting, then run the *Self-check before delivery* checklist.

**Review mode**: Walk the code and provide a structured findings report on architectural violations, layer leakage, circular dependencies, and state management issues.

## Why this skill exists

Mobile architecture failures are systematic:
- **Layer leakage**: Presentation logic in domain layer, repository calls in UI
- **God objects**: ViewModels with 500+ lines, models with too many responsibilities
- **Circular dependencies**: Feature A imports Feature B, Feature B imports Feature A
- **State management chaos**: Multiple sources of truth, prop drilling in Flutter, LiveData chains
- **Untestable code**: Hard dependencies on Android Framework, context passed everywhere
- **Modular failures**: Modules too coarse-grained or too fine-grained

These are prevented by enforcing Clean Architecture layering and SOLID principles in mobile contexts.

## Always-applied imperatives

### Layer Separation (Clean Architecture)

1. **Three clear layers, not mixed.** 
   - **Presentation**: UI components (Activities, Fragments, Composables, Widgets), ViewModels, state holders. Nothing here directly calls repositories or domain logic.
   - **Domain**: Business rules, entities, use cases, repository interfaces. Zero Android/Flutter imports. Zero database imports. Pure Kotlin/Dart.
   - **Data**: Repositories, data sources (local/remote), mappers, API clients. Implements domain repository interfaces.
   
   **Violation smell**: A ViewModel calling a database query directly, or a use case importing `android.content.Context`, or a widget calling an API.

2. **No layer can depend on a layer "above" it.** 
   - Domain never knows about Presentation or Data implementation.
   - Data can know about Domain (implements its interfaces).
   - Presentation knows about both, but uses Domain use cases, never raw data.
   
   **Test**: Can I run domain logic without initializing Android/Flutter framework? Yes = correct. No = layer violation.

3. **Data layer is plumbing, not business.** 
   - Repositories orchestrate data sources (local cache, remote API, preferences).
   - Mappers transform DTOs ↔ Entities (one-way only: network DTO → domain Entity).
   - Business logic about *when* to cache, *when* to refresh lives in use cases, not repositories.
   
   **Anti-pattern**: Repository with if/else chains deciding business rules. That's a use case.

### Dependency Injection (DIP — Dependency Inversion Principle)

4. **Inject everything that changes; hardcode what doesn't.**
   - Repository instance: **inject** (swappable for testing).
   - Logger instance: **inject** (swappable).
   - Shared preferences: **inject** (swappable).
   - Android Context needed for Resources: **OK to pass in constructor** if unavoidable; prefer passing string resources instead.
   - Framework services: inject or mock.
   
   **Anti-pattern**: Creating `UserRepository()` directly in a ViewModel. Violates testability and causes tight coupling.

5. **Use constructor injection for required dependencies; never require optional deps. CRITICAL: Ban ViewModel Decorator/Wrapper pattern.**
   - If a class has optional dependencies (nullable, with defaults), split into two classes **OR** pass decoupled service interfaces.
   - Positional arguments in constructor ≤ 4; beyond that, use a builder or dependency injection container (Hilt, GetIt, etc.).
   - **CRITICAL ANTI-PATTERN TO BAN**: Do NOT wrap a base ViewModel inside a decorator ViewModel. This breaks OS lifecycle scopes and navigation backstacks.
   
   **❌ CRITICAL ANTI-PATTERN — ViewModel Wrapper (DO NOT DO THIS)**:
   ```kotlin
   // BREAKS LIFECYCLE & NAVIGATION
   class LoginViewModel(val authUseCase: AuthUseCase)
   
   class AnalyticsWrappedLoginViewModel(  // ❌ ANTI-PATTERN
     val baseViewModel: LoginViewModel,
     val analyticsService: AnalyticsService
   ) : ViewModel()
   
   // Problem: Navigation uses AnalyticsWrappedLoginViewModel, but lifecycle is broken
   // OS doesn't know about baseViewModel's scope — memory leaks & lifecycle violations
   ```
   
   **✅ CORRECT: Pass decoupled service interfaces via Constructor DI**:
   ```kotlin
   class LoginViewModel(
     val authUseCase: AuthUseCase,
     val analyticsService: AnalyticsService  // ✓ Clean interface dependency
   ) : ViewModel() {
     fun login(email: String, password: String) {
       viewModelScope.launch {
         val result = authUseCase.login(email, password)
         analyticsService.trackLoginAttempt(email)  // ✓ Called explicitly
       }
     }
   }
   ```
   
   **Why**: Wrapping ViewModels breaks the OS's ViewModel.Factory lifecycle binding. Each feature screen should have ONE ViewModel with all its dependencies cleanly injected. If you need optional analytics, pass the service interface (which can be a no-op impl for testing).

6. **Abstractions (interfaces/contracts) live with the client, not the impl.**
   - Domain layer defines `UserRepository` interface.
   - Data layer implements `UserRepository`.
   - Presentation layer uses `UserRepository` from domain, never imports the data impl.
   
   **Kotlin/Flutter**: Same principle. `:domain` defines the interface. `:data` implements it. `:presentation` only knows domain.

### Package & Module Structure

7. **Feature-based modules, not layer-based modules.**
   - ✅ Good: `:feature:auth`, `:feature:profile`, `:feature:payments`
   - ❌ Bad: `:layer:presentation`, `:layer:domain`, `:layer:data` (these share feature boundaries; leads to god modules)
   
   Within each feature module:
   ```
   feature/auth/
   ├── domain/
   │   ├── AuthRepository (interface)
   │   └── LoginUseCase
   ├── data/
   │   ├── AuthRepositoryImpl
   │   └── RemoteAuthDataSource
   └── presentation/
       ├── LoginViewModel
       └── LoginScreen
   ```

8. **No cross-feature direct imports without explicit contracts.**
   - FeatureA can import FeatureB only through a public interface (:feature:common provides shared contracts).
   - Deep imports (`feature.b.data.something`) from FeatureA = architecture smell.
   - Use navigation abstractions, callbacks, or shared domain models instead.

9. **Circular dependencies are failures, not tolerated.**
   - If FeatureA → FeatureB and FeatureB → FeatureA, refactor:
     - Extract shared domain model/interface to `:feature:common`.
     - Use event bus or navigation abstraction instead of direct imports.
     - Split into smaller features with clearer boundaries.

### ViewModel & State Management

10. **Strict Unidirectional Data Flow (UDF): State flows DOWN immutable; Events flow UP via explicit actions.**
    - **State flows DOWN to UI**: ViewModel/BLoC emits immutable state as `StateFlow<State>`, `LiveData<State>`, or streams.
    - **UI reads state ONLY**: Fragment/Activity/Widget observes state, NEVER mutates it.
    - **Events flow UP**: UI sends user actions to ViewModel via explicit methods (`login()`, `updateProfile()`), never direct state mutations.
    - **Single source of truth per screen/feature**: One ViewModel per screen, not scattered across fragments or widgets.
    - **Android**: LiveData, StateFlow, or MutableState held by ViewModel. Fragment/Activity observes, never mutates.
    - **Flutter**: State held in BLoC, Provider, or state manager. Widget reads, dispatches events/methods.
    
    **Kotlin UDF example — CORRECT**:
    ```kotlin
    // ViewModel owns state, emits DOWN
    class LoginViewModel(val authUseCase: AuthUseCase) : ViewModel() {
      private val _state = MutableStateFlow<LoginState>(LoginState.Idle)
      val state: StateFlow<LoginState> = _state.asStateFlow()
      
      // Events flow UP via explicit actions
      fun login(email: String, password: String) {
        viewModelScope.launch {
          _state.value = LoginState.Loading
          val result = authUseCase.login(email, password)
          _state.value = result.fold(
            { LoginState.Success(it) },
            { LoginState.Error(it) }
          )
        }
      }
    }
    
    // UI reads state ONLY, never mutates
    @Composable
    fun LoginScreen(viewModel: LoginViewModel) {
      val state by viewModel.state.collectAsState()
      
      when (state) {
        is LoginState.Idle -> LoginForm(onLoginClick = { email, password ->
          viewModel.login(email, password)  // ✓ Call ViewModel action
        })
        is LoginState.Loading -> LoadingIndicator()
        is LoginState.Success -> SuccessScreen()
        is LoginState.Error -> ErrorDialog()
      }
    }
    ```
    
    **Flutter UDF example — CORRECT**:
    ```dart
    // BLoC emits state DOWN
    class LoginBloc extends Bloc<LoginEvent, LoginState> {
      LoginBloc(this._authUseCase) : super(LoginInitial()) {
        on<LoginPressed>(_onLoginPressed);
      }
      
      FutureOr<void> _onLoginPressed(
        LoginPressed event,
        Emitter<LoginState> emit,
      ) async {
        emit(LoginLoading());
        final result = await _authUseCase.login(event.email, event.password);
        emit(result.fold(
          (user) => LoginSuccess(user),
          (error) => LoginFailure(error),
        ));
      }
    }
    
    // Widget reads state ONLY
    @override
    Widget build(BuildContext context) {
      return BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          if (state is LoginLoading) return LoadingIndicator();
          if (state is LoginSuccess) return SuccessScreen();
          if (state is LoginFailure) return ErrorDialog();
          
          return LoginForm(
            onLoginClick: (email, password) {
              // ✓ Dispatch event UP
              context.read<LoginBloc>().add(LoginPressed(email, password));
            },
          );
        },
      );
    }
    ```

11. **No state duplication; no multi-step prop drilling.**
    - If state must travel through 3+ widget/composable layers, lift it to a shared state holder higher in the tree or use a state manager.
    - ✅ ViewModel → Composable → Composable (one level deep, OK).
    - ❌ ViewModel → Composable → Widget → Widget → Widget (4 hops, bad; use StateFlow or BLoC).

12. **Side effects are explicit, not hidden in init or recomposition.**
    - Kotlin: Use `LaunchedEffect`, `DisposableEffect`, initialization in `init {}` block, or explicit `.onStart()`.
    - Flutter: Use `initState()`, `didChangeDepencies()`, stream subscriptions managed in State.
    - **Anti-pattern**: Calling a use case directly in a Composable `body` or Flutter build method (causes repeated calls).

### Repository & Data Source Patterns

13. **Repository is a single-responsibility orchestrator, not a god object.**
    - Repo job: "I fetch user data. Where? Local cache first, then remote, then memory. How? That's for data sources."
    - Not repo job: Business logic, validation, formatting, retry policies (unless the policy is truly about data access).
    
    **Example — bad**:
    ```kotlin
    class UserRepository {
      suspend fun loginUser(email: String, password: String): Result<User> {
        // Validation (domain responsibility)
        if (email.isEmpty()) throw ValidationException()
        // Complex retry logic (policy responsibility)
        repeat(3) { 
          try {
            return remoteSource.login(email, password)
          } catch (e: Exception) { }
        }
        // Should be in a UseCase or dedicated service
      }
    }
    ```
    
    **Better**: LoginUseCase calls AuthRepository (which just fetches). UseCase handles validation and retry.

14. **Data source interfaces, not concrete implementations, injected into Repository.**
    - Good: `LocalUserDataSource` interface, `LocalUserDataSourceImpl` concrete, repo depends on interface.
    - Bad: Repo depends on `SharedPreferences` directly.
    - Allows testing: mock `LocalUserDataSource` without touching SharedPreferences.

### Testing Boundaries

15. **Domain layer is testable without any framework.**
    - A use case taking `Repository` (interface) + simple objects (String, Int, model classes) = testable with unit tests only.
    - If a use case needs `Context`, lifecycle, or scheduler, it's business logic bleeding into Presentation.
    
    **Kotlin test example**:
    ```kotlin
    @Test
    fun loginUseCaseReturnsUserOnValidCreds() {
      val mockRepo = mockk<UserRepository>()
      val useCase = LoginUseCase(mockRepo)
      // Run with pure Kotlin. No Android imports needed.
      val result = useCase.login("test@example.com", "password")
      assertEquals(expected, result)
    }
    ```

### SOLID Principles in Mobile Context

16. **Single Responsibility Principle (SRP)**: 
    - One ViewModel per screen/feature, not one per layer.
    - One repository per domain concept (UserRepository, PaymentRepository), not one per data source type.
    - A mapper's job: DTO ↔ Entity transformation, nothing else.

17. **Open/Closed Principle (OCP)**:
    - Adding a new auth method (social login, biometric)? Extend via new use case + new strategy, not branches in LoginUseCase.
    - New data source (Firestore instead of REST)? New impl of repository interface, not if/else in existing repo.

18. **Liskov Substitution Principle (LSP)**:
    - A mock repository must be droppable in for the real one without breaking contracts.
    - If test repository returns null when prod returns empty list, LSP is violated.

19. **Interface Segregation Principle (ISP)**:
    - Don't make a `DataRepository` interface that every data class implements. Make `UserRepository`, `PaymentRepository`, etc.
    - A screen needing a user shouldn't depend on an interface that also defines payment methods.

20. **Dependency Inversion Principle (DIP)**:
    - Presentation depends on Domain abstractions (interfaces), not Data implementations.
    - Good: `class LoginViewModel(val useCase: LoginUseCase)`
    - Bad: `class LoginViewModel(val api: RetrofitService)` (violates DIP; couples to framework)

### Token Optimization Imperatives (For AI-Assisted Development)

21. **Output diffs-only, not full files. Command surgical, targeted changes.**
    - When reviewing architecture or suggesting refactors, output only changed/new code sections as diffs.
    - Skip explanations like "Here's your complete updated LoginViewModel" or "I've restructured the entire module."
    - Format as: old code with ~~strikethrough~~, new code highlighted, side-by-side diff view.
    - Never dump entire files; let reviewers see what changed at a glance.
    - **Why**: With Prompt Caching, this saves 40-60% of tokens when reviewing multiple features and enables faster iteration.
    
    **❌ BAD (Full file + padding)**:
    ```
    Here's your complete AuthRepository with improved error handling and caching strategy:
    
    class AuthRepository(
      private val remoteSource: RemoteAuthDataSource,
      private val localCache: LocalAuthDataSource
    ) {
      // ... 100 lines total
    }
    ```
    
    **✅ GOOD (Diffs-only, precise)**:
    ```kotlin
    // AuthRepository: Add retry policy to login method
    
    suspend fun login(email: String, password: String): User {
      return retry(maxAttempts = 3) {
    -   remoteSource.login(email, password)
    +   remoteSource.login(email, password).also {
    +     localCache.save(it)
    +   }
      }
    }
    ```

22. **Enforce Unidirectional Data Flow in architectural feedback. Command immutability and explicit event handlers.**
    - When reviewing state management: insist on immutable state objects flowing DOWN (not mutable LiveData).
    - Insist on explicit event/action methods flowing UP (not direct state mutations from UI).
    - Reject patterns that blur responsibility (UI mutating shared mutable state, ViewModel reading UI events directly).
    - Reference UDF imperatives (10) in findings to keep feedback consistent and enforceable.
    - **Why**: UDF is the architectural standard that enables testability, scalability, and team consistency.

## Self-check before delivery

Before merging or requesting review:

1. **Layer check**: Can I trace each class to Presentation, Domain, or Data? Is there layer leakage (e.g., Domain importing `androidx.*`)?
2. **Dependency check**: Does each layer depend only on layers "below" it? Are all injected dependencies interfaces, not implementations?
3. **Module check**: Are modules organized by feature, not layer? Are cross-feature dependencies minimal and explicit?
4. **ViewModel check**: Does each screen have one ViewModel? Is state in ViewModel, not scattered across fragments/widgets?
5. **Repository check**: Is each repository a simple orchestrator? Is business logic in use cases, not repos?
6. **Data source check**: Are data sources injected as interfaces? Can I swap RemoteDataSource for a mock?
7. **Testing check**: Can I test domain logic without any Android/Flutter imports? Can I unit test the ViewModel with mocked repo?
8. **Circular dep check**: Do any two modules import each other? Use `:common` to break cycles.
9. **Single truth check**: Is state defined in one place (ViewModel, BLoC, state holder), not duplicated across multiple classes?

If you cannot answer **yes** to all checks, refactor before shipping.

## When the user pushes back on a rule

These rules come from battle-tested mobile architecture patterns (Clean Architecture by Uncle Bob, SOLID by Uncle Bob, reactive architectures in Android and Flutter). If a rule feels too strict:

- **Feature complexity requires a second ViewModel?** Split the screen or use a shared state holder.
- **Need to call the repo from a data source?** That's business logic — move to a use case.
- **Context needed in domain layer?** Pass a string or callback instead; never pass Framework objects into Domain.
- **Project uses layer-based modules and changing is hard?** Create a `:feature:common` module to bridge and refactor incrementally.

Document exceptions in code comments with the rule name and reason.

## Troubleshooting

- If the task is code-level (function refactoring), use clean-code-guard. This skill is architectural.
- If the issue is test coverage/structure, use test-guard.
- If you're unsure whether something violates SRP or DIP, ask: "Does this class have one reason to change?" (SRP) or "Is this dependent on an abstraction or a concrete class?" (DIP).

## What this skill does not do

- Enforce naming conventions (that's clean-code-guard).
- Run architecture analysis tools or generate dependency graphs (use tools like ArchUnit, Detekt).
- Replace code review — this is a guideline, human judgment applies.
- Mandate specific frameworks (Hilt vs GetIt, BLoC vs Provider). Pattern matters, implementation choice is yours.
