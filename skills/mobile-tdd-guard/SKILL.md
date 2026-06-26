---
name: mobile-tdd-guard
description: Test-driven development workflow for Kotlin/Android and Flutter mobile features. Use this for building features and fixing bugs via red-green-refactor: write failing test first, make it pass, refactor. Works with JUnit/Mockito (Android) and Flutter test/Mockito-equivalent patterns. Trigger this when implementing a new feature, fixing a bug with reproduction, or when the user says "TDD this", "write tests first", "red-green-refactor", or after a test fails. Use for unit tests on domain/data layers and widget tests on presentation layer.
---

# mobile-tdd-guard

You are building mobile features using test-driven development (red-green-refactor). This skill guides the cycle: write a failing test, implement to pass it, refactor for clarity. Apply this discipline to domain logic (business rules) and data layer (repositories, use cases) via unit tests, and presentation layer (ViewModels, widgets) via widget/integration tests.

## Compatibility

This skill works with:
- **Kotlin/Android**: JUnit 4/5, Mockito, MockK, Truth assertions
- **Flutter**: Flutter test package, Mockito-dart, bloc_test, integration_test
- **Testing scope**: Unit tests (domain/data), widget tests (UI logic), integration tests (features)

This skill complements clean-code-guard (for code quality) and mobile-architecture-guard (for architecture). Use clean-code-guard to audit the test itself. Use architecture-guard to ensure layer boundaries in the code being tested.

## How to use this skill

**Red-Green-Refactor cycle** (recommended):
1. **Red**: Write a failing test that specifies the desired behavior (test fails because code doesn't exist yet).
2. **Green**: Write the minimal code to pass the test (make it work, don't worry about beauty).
3. **Refactor**: Clean the implementation without changing behavior; clean the test for clarity. Re-run to confirm.
4. **Repeat**: Next test case.

**When to use**:
- Implementing a new feature from a spec or issue.
- Fixing a bug: first write a failing test that reproduces the bug, then fix the code.
- Iterating through multiple acceptance criteria.

**When not to use**: Don't retrofit tests after code exists (that's behavior-driven testing, not TDD). Don't use this for exploratory code or research spikes.

## Why this skill exists

Mobile TDD failures are systematic:
- **Test-less or test-later development**: Leads to untestable code, tight coupling, God objects.
- **Tests that don't fail on regression**: Tests pass even when real logic breaks (fixtures, mock over-specification).
- **Test duplication**: Same setup repeated 10 times; changes become a nightmare.
- **Over-mocking**: Mocking the implementation instead of the contract; tests break on refactor even when behavior is correct.
- **Flaky tests**: Race conditions, timing, non-deterministic data.
- **Testing implementation, not behavior**: Tests specify *how* code works, not *what* it does (brittle).

TDD prevents these by forcing design upfront: if it's hard to test, the design is probably coupled or does too much.

## Always-applied imperatives

### Test-First Discipline

1. **Write the failing test before the code.**
   - The test specifies behavior. The test is the spec.
   - A test that doesn't fail initially is worthless — you don't know if you're testing the right thing.
   - **In compiled languages (Kotlin/Java), create a stub class/function FIRST so the test compiles**, then make it fail properly.
   
   **Kotlin example (CORRECT FLOW)**:
   ```kotlin
   // Step 1: Create STUB so test compiles (will throw NotImplementedError or return dummy)
   class LoginUseCase(private val repo: AuthRepository) {
     suspend fun login(email: String, password: String): User {
       throw NotImplementedError("Not yet implemented")
     }
   }
   
   // Step 2: Write the test (now it COMPILES)
   @Test
   fun loginUseCaseReturnsUserOnValidCreds() = runTest {
     val mockRepo = mockk<AuthRepository>()
     coEvery { mockRepo.login("test@example.com", "password") } returns User("test@example.com")
     
     val useCase = LoginUseCase(mockRepo)
     val result = useCase.login("test@example.com", "password")
     
     assertEquals(User("test@example.com"), result)
     // ✗ Test fails: expected User("test@example.com"), got NotImplementedError. RED ✓
   }
   
   // Step 3: Implement minimal code to make test pass (GREEN)
   class LoginUseCase(private val repo: AuthRepository) {
     suspend fun login(email: String, password: String): User {
       return repo.login(email, password)  // ✓ Test passes. GREEN ✓
     }
   }
   
   // Step 4: Refactor (if needed), test still passes. REFACTOR ✓
   ```
   
   **Why the stub?** In Kotlin/Java, the test won't compile if the class doesn't exist. Create a stub that throws `NotImplementedError()` or returns dummy data, so the test compiles and properly fails (RED state).

2. **Test behavior, not implementation.**
   - **Good**: "Given invalid email, the use case returns an error." (tests the contract)
   - **Bad**: "MockRepository.login() is called exactly 3 times with specific args." (tests the internals; brittle)
   
   Ask: *Would this test still pass if I refactored the internals without changing behavior?* If no, the test is too implementation-specific.

3. **Test one thing per test, one assertion (usually).**
   - One test case per acceptance criterion or edge case.
   - If you find yourself writing multiple assertions, ask: *Are these testing the same behavior, or different behaviors?*
   - Multiple assertions on the *same object* in different states = OK. Multiple assertions on *unrelated things* = split into tests.
   
   **Bad**:
   ```kotlin
   @Test
   fun testLoginAndProfileAndPayment() {
     // Tests 3 features in one test; hard to know which failed
   }
   ```
   
   **Better**:
   ```kotlin
   @Test
   fun loginUseCaseReturnsUserOnValidCreds() { }
   
   @Test
   fun loginUseCaseThrowsExceptionOnInvalidCreds() { }
   
   @Test
   fun loginUseCaseCallsRepositoryOnce() { }
   ```

4. **Test names describe the scenario and outcome, not the method name.**
   - **Good**: `loginUseCaseReturnsUserOnValidCreds`, `loginUseCaseThrowsAuthExceptionOnBadPassword`, `networkTimeoutRetries3Times`
   - **Bad**: `testLogin`, `test1`, `testFail`
   
   A developer reading the test name should know: *Scenario?* *Expected outcome?*

### Mocking & Test Doubles

5. **Mock external dependencies (Repository, API, Database); test the class under test.**
   - Unit test of LoginUseCase: mock UserRepository, test the use case logic.
   - Integration test: real repository, real database, test the feature end-to-end.
   - Don't mix: unit tests should not hit the database or network.
   
   **Kotlin**:
   ```kotlin
   // Unit test: mock the repo
   @Test
   fun loginUseCaseHandlesRepositoryError() {
     val mockRepo = mockk<UserRepository>()
     coEvery { mockRepo.login(any(), any()) } throws NetworkException()
     val useCase = LoginUseCase(mockRepo)
     
     val result = assertThrows<NetworkException> { useCase.login("a", "b") }
   }
   
   // Integration test: real repo
   @Test
   fun loginFeatureHandlesNetworkError() {
     val realRepo = UserRepository(realDatabase, realNetwork)
     val viewModel = LoginViewModel(LoginUseCase(realRepo))
     // ... test the whole feature
   }
   ```

6. **Mock the interface contract, not the implementation.**
   - **Good**: `coEvery { repository.getUser(id) } returns User(id)`
   - **Bad**: `coEvery { database.query("SELECT * FROM users WHERE id = $id") } returns ...` (too specific; brittle)
   
   Mocking at the interface level lets you refactor internals without rewriting tests.

7. **No over-specification in mocks; no brittle .times() or .inOrder() without reason.**
   - **Over-spec example**:
     ```kotlin
     verify(mockRepo, times(2)) { repo.getUserCached(id) }  // Why exactly 2? Brittle.
     ```
   - **Good**:
     ```kotlin
     verify(mockRepo, atLeastOnce()) { repo.getUser(id) }  // Just care it was called
     ```
   
   If you need strict call ordering/count, document *why* in the test name and comment.

8. **No test fixtures with hardcoded success; test edge cases too.**
   - **Bad** (every test mocks success):
     ```kotlin
     val mockRepo = mockk<UserRepository> {
       coEvery { getUser(any()) } returns User("test")
     }
     ```
   
   **Better**: Create a test helper that returns success by default, then override in specific tests:
   ```kotlin
   fun mockUserRepository(user: User = User("test")): UserRepository {
     return mockk { coEvery { getUser(any()) } returns user }
   }
   
   @Test
   fun testSuccess() {
     val repo = mockUserRepository()
     // ...
   }
   
   @Test
   fun testNotFound() {
     val repo = mockUserRepository(throws UserNotFoundException())
     // ...
   }
   ```

### Test Coverage: What to Test

9. **Test happy path (success case) and at least two sad paths (errors).**
   - **Happy path**: "User provides valid email and password, login succeeds."
   - **Sad path 1**: "Repository returns error; use case propagates it."
   - **Sad path 2**: "Input is invalid; use case rejects it early."
   
   For each significant behavior (validation, API calls, caching), test success and at least one failure.

10. **Test boundary conditions: empty, null, zero, negative, max, special characters.**
    - **Boundary cases**:
      - Empty string: `""`
      - Null: `null`
      - Empty list/collection: `emptyList()`
      - Max value: `Int.MAX_VALUE`, `Long.MAX_VALUE`
      - Off-by-one: range [1..10], test 0, 1, 10, 11
      - Special chars: Unicode, emoji, control chars in text fields
    
    ```kotlin
    @Test
    fun loginUseCaseRejectsEmptyEmail() {
      val useCase = LoginUseCase(mockRepo)
      assertThrows<ValidationException> { useCase.login("", "password") }
    }
    
    @Test
    fun paginationReturnsEmptyWhenNoResults() {
      val useCase = GetUsersUseCase(mockRepo)
      coEvery { mockRepo.getUsers(1) } returns emptyList()
      
      val result = useCase.getUsers(page = 1)
      assertTrue(result.isEmpty())
    }
    ```

11. **Test that real code behavior matches the mock contract.**
    - After RED-GREEN, before you commit: does the real implementation actually match what the mock expects?
    - **Anti-pattern**: Test passes with mock, breaks when you use the real repository (suggests mock is lying).
    
    Run an integration test alongside unit tests to catch this.

### Refactoring in TDD

12. **Refactor only after the test passes; never refactor between RED and GREEN.**
    - RED: test fails.
    - GREEN: test passes (code is ugly, that's OK).
    - REFACTOR: clean up, both test and code.
    - VERIFY: test still passes.
    
    This keeps the feedback loop tight: if you break something during refactor, the test catches it immediately.

13. **Refactored code must not change test behavior.**
    - If you refactor the implementation and a test starts failing, one of two things:
      1. You changed observable behavior (was it accidental?).
      2. Your test was over-specified (testing implementation details).
    - If (2), update the test. If (1), either revert or ask if the behavior change is intentional.

14. **Avoid test code duplication with setup/helper methods.**
    - **Bad** (copy-paste setup):
      ```kotlin
      @Test fun test1() {
        val repo = mockk<UserRepository>()
        coEvery { repo.getUser("123") } returns User("123")
        val useCase = LoginUseCase(repo)
        // test1 code
      }
      
      @Test fun test2() {
        val repo = mockk<UserRepository>()
        coEvery { repo.getUser("123") } returns User("123")
        val useCase = LoginUseCase(repo)
        // test2 code
      }
      ```
    
    **Better** (@Before setUp, or helper method):
      ```kotlin
      private lateinit var repo: UserRepository
      private lateinit var useCase: LoginUseCase
      
      @Before
      fun setUp() {
        repo = mockk { coEvery { getUser("123") } returns User("123") }
        useCase = LoginUseCase(repo)
      }
      
      @Test fun test1() { /* test1 code */ }
      @Test fun test2() { /* test2 code */ }
      ```

### Assertions & Validation

15. **Use specific assertion functions; fail fast with useful messages.**
    - **Bad** (generic, no message):
      ```kotlin
      assertTrue(result == expectedUser)  // What failed? No context.
      ```
    
    **Better** (specific, descriptive):
      ```kotlin
      assertEquals(expectedUser, result, "User login should return the expected user")
      // Or (Kotlin):
      result shouldBe expectedUser
      assertThat(result).isEqualTo(expectedUser)  // Truth library
      ```
    
    For complex objects, compare meaningful fields:
    ```kotlin
    assertEquals(expectedUser.id, result.id)
    assertEquals(expectedUser.email, result.email)
    // Or use a data-class-aware equality library
    ```

16. **No assertions on logging, UI state, or side effects unless central to the test.**
    - **Bad**: Asserting a log line was written (brittle, couples to log format).
    - **Good**: Asserting that an exception was thrown and handled correctly.
    - **OK**: Asserting ViewModel emits a specific state when data arrives.

### Flutter-Specific Patterns

17. **Widget tests: test the UI logic (ViewModel state → Widget render), not the Framework.**
    - **Good widget test**: "When ViewModel emits loading state, widget shows progress indicator."
    - **Bad widget test**: "Framework correctly rendered a CircularProgressIndicator." (that's Framework testing, not yours)
    
    ```dart
    testWidgets('Shows loading indicator when state is loading', (WidgetTester tester) async {
      final mockViewModel = MockLoginViewModel();
      when(mockViewModel.state).thenReturn(LoginState.loading());
      
      await tester.pumpWidget(createApp(viewModel: mockViewModel));
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    ```

18. **Use `pump()` and `pumpAndSettle()` correctly to avoid flakiness. GOLDEN FILES MUST use `pumpAndSettle()`.**
    - `pump()`: advance the animation clock by a duration, rebuild widgets once.
    - `pumpAndSettle()`: pump repeatedly until no more pending frames (animations complete, streams settle).
    - **CRITICAL for visual regression testing**: Always use `pumpAndSettle()` before capturing golden files to ensure animations are complete.
    - For async operations (API calls): mock them or use `pumpAndSettle()` to let the future resolve.
    
    **Flaky example** (won't wait for async):
    ```dart
    await tester.tap(find.byText('Login'));
    expect(find.byText('Welcome'), findsOneWidget);  // Might not be there yet!
    ```
    
    **Better**:
    ```dart
    await tester.tap(find.byText('Login'));
    await tester.pumpAndSettle();  // Wait for async, animations
    expect(find.byText('Welcome'), findsOneWidget);
    ```
    
    **Golden test example** (visual regression):
    ```dart
    testWidgets('LoginScreen golden test — success state', (WidgetTester tester) async {
      await tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      
      final mockViewModel = MockLoginViewModel();
      when(mockViewModel.state).thenReturn(LoginState.success(User('test')));
      
      await tester.pumpWidget(createApp(viewModel: mockViewModel));
      await tester.pumpAndSettle();  // ✓ MUST wait for animations before golden capture
      
      // Golden file saved: test/goldens/login_screen_success.png
      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('goldens/login_screen_success.png'),
      );
    });
    ```

### Kotlin/Android-Specific Patterns

19. **Use `runTest` (not `runBlocking`) for coroutine tests. Use `coEvery` for suspend mocks.**
    - **Bad** (`runBlocking` blocks the test thread and doesn't respect coroutine test dispatchers):
      ```kotlin
      @Test
      fun testLoginAsync() {
        val result = useCase.login("a", "b")  // Returns a Deferred or suspend fun
        assertEquals(expected, result)  // Doesn't work; result not ready
      }
      ```
    
    **Good** (using runTest for suspend functions):
      ```kotlin
      @Test
      fun testLoginAsync() = runTest {
        val result = useCase.login("a", "b")  // Suspend function; runTest waits
        assertEquals(expected, result)
      }
      ```
    
    Or with coEvery (MockK):
    ```kotlin
    @Test
    fun testLoginMocked() = runTest {
      val mockRepo = mockk<UserRepository>()
      coEvery { mockRepo.login(any(), any()) } returns User("test")
      val useCase = LoginUseCase(mockRepo)
      
      val result = useCase.login("a", "b")
      assertEquals(expected, result)
    }
    ```

20. **Inject `CoroutineDispatcher` instead of hardcoding `Dispatchers.IO` or `Dispatchers.Main` in ViewModels and repositories.**
    - Hardcoded dispatchers make tests non-deterministic and require `TestCoroutineScheduler` workarounds.
    - Inject `dispatchers: CoroutineDispatchers` (a wrapper interface) via constructor; tests pass `UnconfinedTestDispatcher()`.
    
    **❌ BAD — hardcoded dispatcher**:
    ```kotlin
    class LoginViewModel(val useCase: LoginUseCase) : ViewModel() {
      fun login(email: String, password: String) {
        viewModelScope.launch(Dispatchers.IO) {  // ❌ Hardcoded; untestable
          _state.value = useCase.login(email, password)
        }
      }
    }
    ```
    
    **✅ GOOD — injected dispatcher**:
    ```kotlin
    interface AppDispatchers {
      val io: CoroutineDispatcher
      val main: CoroutineDispatcher
    }
    
    class LoginViewModel(
      val useCase: LoginUseCase,
      val dispatchers: AppDispatchers  // ✓ Injected
    ) : ViewModel() {
      fun login(email: String, password: String) {
        viewModelScope.launch(dispatchers.io) {
          _state.value = useCase.login(email, password)
        }
      }
    }
    
    // In test:
    val testDispatchers = object : AppDispatchers {
      override val io = UnconfinedTestDispatcher()
      override val main = UnconfinedTestDispatcher()
    }
    val viewModel = LoginViewModel(mockUseCase, testDispatchers)
    ```

## Output format for AI assistants

When generating test code or reviewing implementations using this skill:
- Output diffs only — not full files. Show only changed or new lines.
- No preamble like "Here's your complete test class" or "I've restructured the tests."
- Format: old line prefixed with `-`, new line prefixed with `+`.
- Never dump entire files.

**Why**: With Prompt Caching, diffs-only output saves 40–60% of tokens when reviewing multiple features.

**❌ BAD**:
```
Here's your complete LoginViewModel with improvements:

class LoginViewModel(
  private val loginUseCase: LoginUseCase,
  private val analyticsService: AnalyticsService
) : ViewModel() {
  // ... 50 more lines
}
```

**✅ GOOD**:
```kotlin
// LoginViewModel: Add error state emission

- val result = loginUseCase(email, password)
+ val result = loginUseCase(email, password)
+ if (result.isFailure) {
+   _state.value = LoginState.Error(result.exceptionOrNull())
+ }
```

## Self-check before delivery

Before committing test code:

1. **Red-Green-Refactor cycle followed?** Did I write failing test → passing code → refactored clean code?
2. **Test name describes scenario and outcome?** (e.g., `loginUseCaseThrowsOnInvalidEmail`, not `testLogin`)
3. **Test tests behavior, not implementation?** (Would refactoring the code break the test?)
4. **Happy path + at least 2 sad paths tested?** (Success case + errors + edge cases)
5. **Boundaries tested?** (Empty, null, zero, max, special chars)
6. **No hard-coded fixtures; mocks are appropriate?** (Repository interface mocked, not concrete class)
7. **Test is deterministic, not flaky?** (No timing issues, no random data, no network calls)
8. **Setup code not duplicated?** (Use @Before or helper methods)
9. **Assertions are specific and fail fast?** (Not generic assertTrue; includes messages)
10. **Refactoring doesn't change observable behavior?** (Test still passes; code is cleaner)

If you cannot answer **yes** to all, refactor the test or code before merging.

## When the user pushes back on a rule

These rules come from *Test-Driven Development: By Example* (Beck) and *Growing Object-Oriented Software, Guided by Tests* (Freeman & Pryce). If a rule feels too strict:

- **Test is too slow (hitting the database)?** Move to integration tests; unit test with mocks.
- **Test name is too long?** Extract a helper method or simplify the scenario.
- **Need to test implementation detail?** You might have tight coupling; consider if the class does too much.
- **Mocks are too complex?** You might be testing too many behaviors at once; split into smaller tests.

Document exceptions in test comments.

## Troubleshooting

- If tests are slow, check: Are you hitting the database (move to integration tests)? Are you making network calls (mock them)? Are you waiting unnecessarily?
- If tests are brittle (fail on refactor), check: Are you mocking implementation details instead of contracts? Are you testing behavior or internals?
- If test setup is complex, the code might do too much. Consider splitting the class.
- If a test fails randomly, it's likely async timing or shared state. Use `advanceUntilIdle()` (Kotlin) or `pumpAndSettle()` (Flutter).

## What this skill does not do

- Set up your test framework or dependencies (that's gradle/pubspec.yaml).
- Generate coverage reports (use `coverage`, `jacoco`, or `lcov`).
- Replace integration/e2e tests. Unit TDD feeds into larger test pyramid.
- Mandate test counts. Write enough tests to be confident; avoid over-testing trivial code.
