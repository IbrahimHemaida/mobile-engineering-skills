# Kotlin/Android Testing Patterns

## Unit Testing with JUnit & MockK

### Setup

```gradle
dependencies {
  testImplementation "junit:junit:4.13.2"
  testImplementation "io.mockk:mockk:1.13.5"
  testImplementation "org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.1"
  testImplementation "com.google.truth:truth:1.1.5"
}
```

---

## Test Structure: Arrange-Act-Assert

```kotlin
@Test
fun loginUseCaseReturnsUserOnValidCreds() = runTest {
  // ARRANGE: Set up test data and mocks
  val mockRepository = mockk<AuthRepository>()
  coEvery { mockRepository.login("test@example.com", "password") } returns User("test@example.com")
  val useCase = LoginUseCase(mockRepository)
  
  // ACT: Call the function under test
  val result = useCase.login("test@example.com", "password")
  
  // ASSERT: Verify the result
  assertEquals(User("test@example.com"), result)
}
```

---

## MockK Basics

### Creating Mocks

```kotlin
// Simple mock
val mockRepo = mockk<UserRepository>()

// Mock with default behavior
val mockRepo = mockk<UserRepository> {
  coEvery { getUser("123") } returns User("123")
}

// Spy (calls real methods but can be verified)
val spyRepo = spyk<UserRepository>()
```

### Setting Up Behavior

```kotlin
// Regular function
every { mockRepo.getUser("123") } returns User("123")

// Suspend function (must use coEvery)
coEvery { mockRepo.login("a@b.c", "pass") } returns User("a@b.c")

// Throwing exception
every { mockRepo.deleteUser("999") } throws UserNotFoundException()

// Returning different values on consecutive calls
every { mockRepo.getUser(any()) } returnsMany listOf(User("1"), User("2"))

// Any argument matcher
every { mockRepo.getUser(any()) } returns User("default")

// Specific matcher
every { mockRepo.getUser(match { it.startsWith("admin") }) } returns AdminUser()
```

### Verifying Calls

```kotlin
// Was this called?
verify { mockRepo.getUser("123") }

// How many times?
verify(exactly = 3) { mockRepo.getUser("123") }

// Never called
verify(inverse = true) { mockRepo.deleteUser("123") }

// Order matters
verifyOrder {
  mockRepo.getUser("123")
  mockRepo.updateUser(any())
}

// Verify suspend function
coVerify { mockRepo.login("a@b.c", "pass") }
```

---

## Testing Suspend Functions

### Using runTest (Structured Concurrency)

```kotlin
class LoginUseCaseTest {
  @Test
  fun loginUseCaseReturnsUserOnValidCreds() = runTest {
    val mockRepo = mockk<AuthRepository>()
    coEvery { mockRepo.login("a@b.c", "pass") } returns User("a@b.c")
    
    val useCase = LoginUseCase(mockRepo)
    val result = useCase.login("a@b.c", "pass")
    
    assertEquals(User("a@b.c"), result)
    // ✓ Test waits for suspend function to complete
  }
}
```

### Handling Multiple Coroutines

```kotlin
@Test
fun viewModelEmitsMultipleStates() = runTest {
  val mockUseCase = mockk<LoadUserUseCase>()
  coEvery { mockUseCase.invoke("123") } returns User("123")
  
  val viewModel = UserViewModel(mockUseCase)
  
  // Start loading
  viewModel.loadUser("123")
  
  // runTest automatically waits for coroutines
  advanceUntilIdle()
  
  // Check final state
  assertEquals(UserState.Success(User("123")), viewModel.state.value)
}
```

---

## Testing StateFlow / LiveData

### StateFlow (Modern Kotlin)

```kotlin
@Test
fun viewModelEmitsLoadingThenSuccess() = runTest {
  val mockUseCase = mockk<GetUserUseCase>()
  coEvery { mockUseCase("123") } returns User("123")
  
  val viewModel = UserViewModel(mockUseCase)
  
  val collectedStates = mutableListOf<UserState>()
  val job = launch {
    viewModel.state.collect { collectedStates.add(it) }
  }
  
  viewModel.loadUser("123")
  advanceUntilIdle()
  job.cancel()
  
  assertEquals(
    listOf(
      UserState.Idle,
      UserState.Loading,
      UserState.Success(User("123"))
    ),
    collectedStates
  )
}
```

### LiveData (Legacy)

```kotlin
@Test
fun viewModelEmitsUserOnSuccess() {
  val mockUseCase = mockk<GetUserUseCase>()
  every { mockUseCase("123") } returns User("123")
  
  val viewModel = UserViewModel(mockUseCase)
  
  val liveData = viewModel.user
  val observer = mockk<Observer<User>>()
  
  liveData.observeForever(observer)
  viewModel.loadUser("123")
  
  verify { observer.onChanged(User("123")) }
  
  liveData.removeObserver(observer)
}
```

---

## Boundary Testing

### Valid vs Invalid Input

```kotlin
class LoginUseCaseTest {
  private lateinit var useCase: LoginUseCase
  private val mockRepo = mockk<AuthRepository>()
  
  @Before
  fun setUp() {
    useCase = LoginUseCase(mockRepo)
  }
  
  // Happy path
  @Test
  fun loginWithValidEmailAndPassword() = runTest {
    coEvery { mockRepo.login(any(), any()) } returns User("test")
    val result = useCase.login("test@example.com", "password123")
    assertEquals(User("test"), result)
  }
  
  // Sad paths
  @Test
  fun loginWithEmptyEmail() = runTest {
    val result = assertThrows<ValidationException> {
      useCase.login("", "password123")
    }
    assertEquals("Email cannot be empty", result.message)
  }
  
  @Test
  fun loginWithEmptyPassword() = runTest {
    val result = assertThrows<ValidationException> {
      useCase.login("test@example.com", "")
    }
    assertEquals("Password cannot be empty", result.message)
  }
  
  @Test
  fun loginWithInvalidEmailFormat() = runTest {
    val result = assertThrows<ValidationException> {
      useCase.login("notanemail", "password123")
    }
  }
  
  @Test
  fun loginWithWrongCredentials() = runTest {
    coEvery { mockRepo.login(any(), any()) } throws InvalidCredentialsException()
    
    val result = assertThrows<InvalidCredentialsException> {
      useCase.login("test@example.com", "wrongpass")
    }
  }
  
  @Test
  fun loginWithNetworkError() = runTest {
    coEvery { mockRepo.login(any(), any()) } throws NetworkException()
    
    val result = assertThrows<NetworkException> {
      useCase.login("test@example.com", "password123")
    }
  }
}
```

---

## No Test Duplication

### ❌ Bad: Duplicate Setup

```kotlin
@Test
fun test1() {
  val mockRepo = mockk<UserRepository>()
  coEvery { mockRepo.getUser("123") } returns User("123")
  val useCase = GetUserUseCase(mockRepo)
  // test1 logic
}

@Test
fun test2() {
  val mockRepo = mockk<UserRepository>()
  coEvery { mockRepo.getUser("123") } returns User("123")
  val useCase = GetUserUseCase(mockRepo)
  // test2 logic
}
```

### ✅ Good: @Before Setup

```kotlin
class GetUserUseCaseTest {
  private lateinit var useCase: GetUserUseCase
  private val mockRepo = mockk<UserRepository> {
    coEvery { getUser("123") } returns User("123")
  }
  
  @Before
  fun setUp() {
    useCase = GetUserUseCase(mockRepo)
  }
  
  @Test
  fun test1() {
    // test1 logic, reusing setup
  }
  
  @Test
  fun test2() {
    // test2 logic, reusing setup
  }
}
```

---

## Test Naming Convention

### ✅ Good: Function + Scenario + Expected Result

```kotlin
@Test fun getUserReturnsUserOnValidId() { }

@Test fun getUserThrowsNotFoundOnInvalidId() { }

@Test fun loginUseCaseValidatesEmailBeforeCall() { }

@Test fun networkErrorFallsBackToLocalCache() { }
```

### ❌ Bad: Vague Names

```kotlin
@Test fun test1() { }

@Test fun testGetUser() { }

@Test fun testFail() { }
```

---

## Exception Testing

### Using assertThrows

```kotlin
@Test
fun invalidEmailThrowsValidationException() {
  val exception = assertThrows<ValidationException> {
    useCase.validate("notanemail@.com")
  }
  
  assertEquals("Invalid email format", exception.message)
}
```

### Using try-catch

```kotlin
@Test
fun invalidEmailThrowsValidationException() {
  try {
    useCase.validate("notanemail@.com")
    fail("Should have thrown ValidationException")
  } catch (e: ValidationException) {
    assertEquals("Invalid email format", e.message)
  }
}
```

---

## Assertion Libraries

### Truth (Google's assertion library)

```kotlin
@Test
fun userHasCorrectEmail() {
  val user = User("123", "test@example.com")
  assertThat(user.email).isEqualTo("test@example.com")
}

@Test
fun listContainsExpectedUsers() {
  val users = listOf(User("1"), User("2"))
  assertThat(users).hasSize(2)
  assertThat(users).containsExactly(User("1"), User("2"))
}

@Test
fun resultIsSuccess() {
  val result = Result.success(User("123"))
  assertThat(result.isSuccess).isTrue()
}
```

### JUnit Assertions

```kotlin
@Test
fun userHasCorrectEmail() {
  val user = User("123", "test@example.com")
  assertEquals("test@example.com", user.email)
}

@Test
fun listContainsExpectedUsers() {
  val users = listOf(User("1"), User("2"))
  assertEquals(2, users.size)
}
```

---

## Mocking Best Practices

### ✅ Mock the Interface, Not the Implementation

```kotlin
@Test
fun loginSuccess() = runTest {
  // GOOD: Mock the repository interface
  val mockRepo: AuthRepository = mockk()
  coEvery { mockRepo.login("a@b.c", "pass") } returns User("a@b.c")
  
  val useCase = LoginUseCase(mockRepo)
  val result = useCase.login("a@b.c", "pass")
  
  assertEquals(User("a@b.c"), result)
  // ✓ Can swap repository implementation without changing test
}
```

### ❌ Mock Implementation Details

```kotlin
@Test
fun loginSuccess() = runTest {
  // BAD: Mock the HTTP client directly
  val mockHttpClient = mockk<HttpClient>()
  every { mockHttpClient.post(any(), any()) } returns MockResponse(200, "{...}")
  
  val repo = AuthRepository(mockHttpClient)
  val useCase = LoginUseCase(repo)
  val result = useCase.login("a@b.c", "pass")
  
  // ✗ Test is brittle; breaks if you change HTTP client
}
```

---

## Real-World Example: TDD Flow

```kotlin
// RED: Test fails (no implementation)
@Test
fun paymentProcessorRejectsDuplicatePayment() = runTest {
  val mockRepository = mockk<PaymentRepository>()
  val processor = PaymentProcessor(mockRepository)
  
  coEvery { mockRepository.processPayment(any()) } returns PaymentResult.Success("txn_1")
  
  val payment = Payment("txn_1", 100.0)
  
  // First call succeeds
  val result1 = processor.process(payment)
  assertEquals(PaymentResult.Success("txn_1"), result1)
  
  // Second call with same payment should fail
  val result2 = processor.process(payment)
  assertTrue(result2 is PaymentResult.DuplicatePayment)
  // ✗ PaymentProcessor doesn't exist yet — RED
}

// GREEN: Minimal implementation
class PaymentProcessor(private val repo: PaymentRepository) {
  private val processedPayments = mutableSetOf<String>()
  
  suspend fun process(payment: Payment): PaymentResult {
    if (payment.id in processedPayments) {
      return PaymentResult.DuplicatePayment
    }
    
    val result = repo.processPayment(payment)
    processedPayments.add(payment.id)
    return result
  }
}
// ✓ Test passes — GREEN

// REFACTOR: Clean up
class PaymentProcessor(private val repo: PaymentRepository) {
  private val processedPayments = mutableSetOf<String>()
  
  suspend fun process(payment: Payment): PaymentResult {
    checkForDuplicate(payment)
    val result = repo.processPayment(payment)
    recordPayment(payment)
    return result
  }
  
  private fun checkForDuplicate(payment: Payment) {
    require(payment.id !in processedPayments) {
      "Duplicate payment: ${payment.id}"
    }
  }
  
  private fun recordPayment(payment: Payment) {
    processedPayments.add(payment.id)
  }
}
// ✓ Test still passes, code is cleaner
```
