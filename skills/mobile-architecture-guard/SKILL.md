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

## Reference files

This SKILL.md covers the core rules and checklists. For deeper treatment, load these as needed:
- `references/clean-architecture.md` — extended layer-separation patterns, real-world layer leakage examples, and migration strategies for legacy modules.
- `references/dependency-injection.md` — DI container comparisons (Hilt, Koin, GetIt, Riverpod), constructor vs field injection tradeoffs, and testing with fakes vs mocks.
- `references/solid-kotlin.md` — SOLID principles worked through with larger Kotlin/Flutter examples than the summaries below.
- `references/state-management.md` — full worked Kotlin (StateFlow + Compose) and Flutter (BLoC) UDF examples.

Read the relevant reference file when a violation needs more context than the summary here provides, or when the user asks for a deeper explanation of a specific principle.

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

4. **No `@Serializable` (DTO) or `@Entity` (database) model ever reaches the UI layer directly.** The Presentation layer consumes a dedicated `UIState`/`ViewState` type, produced by its own mapper from the Domain Entity — never the network or database model passed straight through because writing the mapper felt unnecessary for "just one extra field."
   
   **Violation smell**: a Composable/Widget parameter typed as `UserDto` or `UserEntity` instead of `UserUiState`; a screen that breaks because a backend field was renamed, when only the DTO↔Entity mapper should have needed to change.

### Dependency Injection (DIP — Dependency Inversion Principle)

5. **Inject everything that changes; hardcode what doesn't.**
   - Repository instance: **inject** (swappable for testing).
   - Logger instance: **inject** (swappable).
   - Shared preferences: **inject** (swappable).
   - Android Context needed for Resources: **OK to pass in constructor** if unavoidable; prefer passing string resources instead.
   - Framework services: inject or mock.
   
   **Anti-pattern**: Creating `UserRepository()` directly in a ViewModel. Violates testability and causes tight coupling.

6. **Use constructor injection for required dependencies; never require optional deps. CRITICAL: Ban ViewModel Decorator/Wrapper pattern.**
   - If a class has optional dependencies (nullable, with defaults), split into two classes **OR** pass decoupled service interfaces.
   - Positional arguments in constructor ≤ 4; beyond that, use a builder or dependency injection container (Hilt, GetIt, etc.).
   - **CRITICAL ANTI-PATTERN TO BAN**: Do NOT wrap a base ViewModel inside a decorator ViewModel (e.g. `AnalyticsWrappedLoginViewModel`) to bolt on a cross-cutting concern. This breaks the OS's ViewModel.Factory lifecycle scope and navigation backstack. Instead, pass the extra concern (analytics, logging) as a decoupled service interface via constructor DI, alongside the other dependencies.
   
   See `references/dependency-injection.md` for the full before/after code example and rationale.

7. **Abstractions (interfaces/contracts) live with the client, not the impl.**
   - Domain layer defines `UserRepository` interface.
   - Data layer implements `UserRepository`.
   - Presentation layer uses `UserRepository` from domain, never imports the data impl.
   
   **Kotlin/Flutter**: Same principle. `:domain` defines the interface. `:data` implements it. `:presentation` only knows domain.

8. **The DI module is updated in the same diff as the class it registers, not left for a follow-up.** Creating a new `Repository`, `UseCase`, or `ViewModel` and deferring its Hilt/Koin/GetIt registration to "after the code compiles" produces code that compiles but crashes at runtime with an unresolved dependency — a failure mode unit tests on the class itself won't catch. Register the binding as part of writing the class, not after.
   
   **Violation smell**: a diff that adds `class OrderRepository(...)` with no corresponding change to `NetworkModule`/`RepositoryModule`/the DI graph in the same output.

### Package & Module Structure

9. **Feature-based modules, not layer-based modules.**
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

10. **No cross-feature direct imports without explicit contracts.**
   - FeatureA can import FeatureB only through a public interface (:feature:common provides shared contracts).
   - Deep imports (`feature.b.data.something`) from FeatureA = architecture smell.
   - Use navigation abstractions, callbacks, or shared domain models instead.

11. **Circular dependencies are failures, not tolerated.**
   - If FeatureA → FeatureB and FeatureB → FeatureA, refactor:
     - Extract shared domain model/interface to `:feature:common`.
     - Use event bus or navigation abstraction instead of direct imports.
     - Split into smaller features with clearer boundaries.

12. **Before modifying or removing a public class, function, or interface, search the whole project for its usages — not just the file being edited.** A fix applied to one file that silently breaks three call sites elsewhere is the single most common way an AI coding session ships a regression that compiles cleanly. Run a project-wide search (grep, IDE "Find Usages", or equivalent) for the symbol being changed before finalizing the diff, and confirm every call site still compiles against the new signature/contract — not just the one that motivated the change.
   **Violation smell**: a diff that changes a `Repository` interface method signature with no corresponding changes shown for its implementations and callers, or a confident "this should be fine" with no actual search performed.

13. **Before presenting a final diff, run the project's actual local build command and confirm it succeeds — don't rely on read-through review alone to catch compile errors.** Use the real build tool for the target platform: `./gradlew assembleDebug`/`compileDebugKotlin` for Android, `xcodebuild` (or `swift build`) for iOS/KMM native targets, `flutter analyze`/`flutter build` for Flutter. A diff that "looks correct" but wasn't actually compiled is not verified — presenting one as ready to merge without running the build is a bare assertion, not a fact.
   **Exception**: if no build environment is available in the current session, say so explicitly in the output rather than silently skipping this step and presenting the diff as verified.

### ViewModel & State Management

14. **Strict Unidirectional Data Flow (UDF): State flows DOWN immutable; Events flow UP via explicit actions.**
    - **State flows DOWN to UI**: ViewModel/BLoC emits immutable state as `StateFlow<State>`, `LiveData<State>`, or streams.
    - **UI reads state ONLY**: Fragment/Activity/Widget observes state, NEVER mutates it.
    - **Events flow UP**: UI sends user actions to ViewModel via explicit methods (`login()`, `updateProfile()`), never direct state mutations.
    - **Single source of truth per screen/feature**: One ViewModel per screen, not scattered across fragments or widgets.
    - **Android**: LiveData, StateFlow, or MutableState held by ViewModel. Fragment/Activity observes, never mutates.
    - **Flutter**: State held in BLoC, Provider, or state manager. Widget reads, dispatches events/methods.
    
    **When reviewing state management**: Reject any pattern that passes mutable state objects down to the UI, or that allows the UI to directly mutate shared state. Flag violations with reference to this imperative (#14) in findings.
    
    See `references/state-management.md` for full worked Kotlin (StateFlow + Compose) and Flutter (BLoC) UDF examples.

15. **No state duplication; no multi-step prop drilling.**
    - If state must travel through 3+ widget/composable layers, lift it to a shared state holder higher in the tree or use a state manager.
    - ✅ ViewModel → Composable → Composable (one level deep, OK).
    - ❌ ViewModel → Composable → Widget → Widget → Widget (4 hops, bad; use StateFlow or BLoC).

16. **Side effects are explicit, not hidden in init or recomposition.**
    - Kotlin: Use `LaunchedEffect`, `DisposableEffect`, initialization in `init {}` block, or explicit `.onStart()`.
    - Flutter: Use `initState()`, `didChangeDepencies()`, stream subscriptions managed in State.
    - **Anti-pattern**: Calling a use case directly in a Composable `body` or Flutter build method (causes repeated calls).

### Repository & Data Source Patterns

17. **Repository is a single-responsibility orchestrator, not a god object.**
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

18. **Data source interfaces, not concrete implementations, injected into Repository.**
    - Good: `LocalUserDataSource` interface, `LocalUserDataSourceImpl` concrete, repo depends on interface.
    - Bad: Repo depends on `SharedPreferences` directly.
    - Allows testing: mock `LocalUserDataSource` without touching SharedPreferences.

### Testing Boundaries

19. **Domain layer is testable without any framework.**
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

20. **Single Responsibility Principle (SRP)**: 
    - One ViewModel per screen/feature, not one per layer.
    - One repository per domain concept (UserRepository, PaymentRepository), not one per data source type.
    - A mapper's job: DTO ↔ Entity transformation, nothing else.

21. **Open/Closed Principle (OCP)**:
    - Adding a new auth method (social login, biometric)? Extend via new use case + new strategy, not branches in LoginUseCase.
    - New data source (Firestore instead of REST)? New impl of repository interface, not if/else in existing repo.

22. **Liskov Substitution Principle (LSP)**:
    - A mock repository must be droppable in for the real one without breaking contracts.
    - If test repository returns null when prod returns empty list, LSP is violated.

23. **Interface Segregation Principle (ISP)**:
    - Don't make a `DataRepository` interface that every data class implements. Make `UserRepository`, `PaymentRepository`, etc.
    - A screen needing a user shouldn't depend on an interface that also defines payment methods.

24. **Dependency Inversion Principle (DIP)**:
    - Presentation depends on Domain abstractions (interfaces), not Data implementations.
    - Good: `class LoginViewModel(val useCase: LoginUseCase)`
    - Bad: `class LoginViewModel(val api: RetrofitService)` (violates DIP; couples to framework)

## Output format for AI assistants

When reviewing architecture or suggesting refactors using this skill:
- Output diffs only — not full files. Show only changed or new lines.
- No preamble like "Here's your complete updated LoginViewModel" or "I've restructured the entire module."
- Format: old line prefixed with `-`, new line prefixed with `+`.
- Never dump entire files.

**Why**: With Prompt Caching, diffs-only output saves 40–60% of tokens when reviewing multiple features.

**❌ BAD**:
```
Here's your complete AuthRepository with improved error handling:

class AuthRepository(
  private val remoteSource: RemoteAuthDataSource,
  private val localCache: LocalAuthDataSource
) {
  // ... 100 lines total
}
```

**✅ GOOD**:
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

## Findings report format (Review mode)

When reviewing existing code, report findings as:

```
[SEVERITY] Short title
File: path/to/File.kt:line
Issue: What's wrong, in one sentence.
Impact: What breaks or degrades — testability, layer boundary, dependency direction, state predictability.
Fix: Specific remediation (imperative # from above where relevant).
```

Severity guide: **Critical** = breaks the dependency rule or causes a circular dependency (domain layer imports a framework type, two modules depend on each other). **High** = layer leakage or a duplicated ViewModel/state-holder anti-pattern that will cause real bugs (lifecycle leaks, untestable business logic). **Medium** = architecturally wrong but currently harmless (a repository doing UI-adjacent work with no leakage yet). **Low** = style/consistency issue that doesn't affect testability or boundaries (inconsistent naming, a use case that could be simplified).

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
10. **UI model check**: Does any Composable/Widget receive a `@Serializable`/`@Entity` model directly, or does it go through a `UIState` + mapper?
11. **DI registration check**: Is every new `Repository`/`UseCase`/`ViewModel` registered in its DI module within the same diff, not deferred?
12. **Blast-radius check**: Did I search the whole project for usages of every changed public symbol, not just the file I edited?
13. **Build check**: Did I actually run the project's local build command and confirm it passed, or explicitly note that no build environment was available?

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
