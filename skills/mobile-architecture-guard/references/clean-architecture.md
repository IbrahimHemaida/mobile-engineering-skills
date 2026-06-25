# Clean Architecture in Kotlin/Android

## Three Concentric Circles

```
           Frameworks & Drivers
          (Android, Flutter, Web)
                  ↑
            Interface Adapters
        (Controllers, Presenters,
         Gateways, Repositories)
                  ↑
           Business Rules
        (Use Cases / Interactors)
                  ↑
              Entities
          (Enterprise Rules)
```

**Key rule**: Dependencies point INWARD only. Inner circles never import outer circles.

---

## Layer 1: Entities (Domain Models)

**Responsibility**: Represent core business concepts.

```kotlin
// Pure Kotlin, zero framework imports
data class User(
  val id: String,
  val email: String,
  val name: String,
  val createdAt: Long
)

data class Payment(
  val id: String,
  val userId: String,
  val amount: Double,
  val status: PaymentStatus
)

enum class PaymentStatus {
  PENDING, SUCCESS, FAILED
}
```

**Rules**:
- No Android imports (`android.*`)
- No database imports (`androidx.room.*`)
- No framework code
- Pure data + validation logic

---

## Layer 2: Business Rules (Use Cases)

**Responsibility**: Orchestrate domain entities and repository interactions.

```kotlin
class LoginUseCase(
  private val authRepository: AuthRepository
) {
  suspend operator fun invoke(
    email: String,
    password: String
  ): Result<User> = try {
    // Validation (business rule)
    require(email.isNotEmpty()) { "Email is required" }
    require(password.isNotEmpty()) { "Password is required" }
    
    // Call repository (data access)
    val user = authRepository.login(email, password)
    
    Result.success(user)
  } catch (e: Exception) {
    Result.failure(e)
  }
}

class GetUserProfileUseCase(
  private val userRepository: UserRepository,
  private val paymentRepository: PaymentRepository
) {
  suspend operator fun invoke(userId: String): Result<UserProfile> = try {
    val user = userRepository.getUser(userId)
    val payments = paymentRepository.getPaymentsForUser(userId)
    
    val profile = UserProfile(
      user = user,
      totalSpent = payments.sumOf { it.amount },
      paymentCount = payments.size
    )
    
    Result.success(profile)
  } catch (e: Exception) {
    Result.failure(e)
  }
}
```

**Rules**:
- No Android imports
- No database calls directly
- Uses repository interfaces (abstractions)
- Contains business logic (validation, calculations)
- One use case = one user action

---

## Layer 3: Interface Adapters (Repositories, ViewModels, Screens)

### 3a. Repositories (Data Orchestration)

```kotlin
// Interface defined in Domain layer
interface UserRepository {
  suspend fun getUser(id: String): User
  suspend fun saveUser(user: User): Unit
  suspend fun deleteUser(id: String): Unit
}

// Implementation in Data layer
class UserRepositoryImpl(
  private val remoteSource: RemoteUserDataSource,
  private val localCache: UserLocalDataSource
) : UserRepository {
  override suspend fun getUser(id: String): User {
    return try {
      val user = remoteSource.getUser(id)
      localCache.save(user)
      user
    } catch (e: Exception) {
      localCache.get(id) ?: throw e
    }
  }
  
  override suspend fun saveUser(user: User) {
    remoteSource.saveUser(user)
    localCache.save(user)
  }
  
  override suspend fun deleteUser(id: String) {
    remoteSource.deleteUser(id)
    localCache.delete(id)
  }
}
```

### 3b. Data Sources (Single Responsibility)

```kotlin
// Remote data source (API only)
class RemoteUserDataSource(private val api: UserApi) {
  suspend fun getUser(id: String): User = api.getUser(id)
  suspend fun saveUser(user: User) = api.updateUser(user)
  suspend fun deleteUser(id: String) = api.deleteUser(id)
}

// Local data source (Database/Cache only)
class UserLocalDataSource(private val dao: UserDao) {
  suspend fun get(id: String): User? = dao.getUser(id)
  suspend fun save(user: User) = dao.insert(user)
  suspend fun delete(id: String) = dao.delete(id)
}
```

### 3c. ViewModels (Presentation Logic)

```kotlin
class LoginViewModel(
  private val loginUseCase: LoginUseCase,
  private val analyticsService: AnalyticsService
) : ViewModel() {
  private val _state = MutableStateFlow<LoginState>(LoginState.Idle)
  val state: StateFlow<LoginState> = _state.asStateFlow()
  
  fun login(email: String, password: String) {
    viewModelScope.launch {
      _state.value = LoginState.Loading
      
      val result = loginUseCase(email, password)
      
      _state.value = result.fold(
        onSuccess = { user ->
          analyticsService.trackLoginSuccess(user.id)
          LoginState.Success(user)
        },
        onFailure = { error ->
          analyticsService.trackLoginFailure(error.message ?: "Unknown")
          LoginState.Error(error)
        }
      )
    }
  }
}

sealed class LoginState {
  object Idle : LoginState()
  object Loading : LoginState()
  data class Success(val user: User) : LoginState()
  data class Error(val error: Throwable) : LoginState()
}
```

---

## Layer 4: Frameworks & Drivers (Android/Flutter)

### UI (Composables, Activities, Screens)

```kotlin
@Composable
fun LoginScreen(viewModel: LoginViewModel) {
  val state by viewModel.state.collectAsState()
  
  when (state) {
    is LoginState.Idle -> LoginForm(onLoginClick = { email, password ->
      viewModel.login(email, password)
    })
    is LoginState.Loading -> LoadingIndicator()
    is LoginState.Success -> {
      LaunchedEffect(Unit) {
        // Navigate to home
      }
    }
    is LoginState.Error -> {
      ErrorDialog(error = (state as LoginState.Error).error)
    }
  }
}
```

---

## Dependency Flow (ALWAYS Inward)

```
Activity/Fragment/Composable
         ↓
      ViewModel
         ↓
      UseCase
         ↓
  Repository (interface)
         ↓
  Data Sources (API, Database)
         
Domain Layer: UseCase + Entities + Repository Interfaces
├── No Android imports ✓
├── No database imports ✓
├── No framework imports ✓

Data Layer: Repositories + Data Sources
├── Implements Domain interfaces ✓
├── Has Android/database imports ✓
└── Accessed only through Use Cases ✓

Presentation Layer: Activities, ViewModels, Screens
├── Imports Domain Use Cases ✓
├── Imports Data Layer repos (as interfaces only) ✓
└── Has Android/UI imports ✓
```

---

## Project Structure Example

```
app/
├── feature/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── repository/
│   │   │   │   └── AuthRepositoryImpl.kt
│   │   │   └── datasource/
│   │   │       ├── RemoteAuthDataSource.kt
│   │   │       └── LocalAuthDataSource.kt
│   │   ├── domain/
│   │   │   ├── repository/
│   │   │   │   └── AuthRepository.kt (interface)
│   │   │   └── usecase/
│   │   │       ├── LoginUseCase.kt
│   │   │       └── LogoutUseCase.kt
│   │   └── presentation/
│   │       ├── viewmodel/
│   │       │   └── LoginViewModel.kt
│   │       └── screen/
│   │           └── LoginScreen.kt
│   │
│   └── profile/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── common/
    ├── domain/
    │   └── entities/
    │       └── User.kt
    └── data/
        └── api/
            └── ApiClient.kt
```

**Key points**:
- Feature-based modules (auth, profile, payments)
- Clear layer separation within each feature
- Common module for shared domain models + API setup
- No circular imports possible

---

## Testing Implication

Because of Clear Architecture:

```kotlin
// Domain test: Pure Kotlin, no framework
@Test
fun loginUseCaseRejectsInvalidEmail() = runTest {
  val mockRepo = mockk<AuthRepository>()
  val useCase = LoginUseCase(mockRepo)
  
  val result = useCase("", "password")
  
  assertTrue(result.isFailure)
  verify(inverse = true) { mockRepo.login(any(), any()) }
}

// Data test: Database/API logic
@Test
fun repositoryFallsBackToLocalOnNetworkError() = runTest {
  val mockRemote = mockk<RemoteAuthDataSource>()
  val mockLocal = mockk<LocalAuthDataSource>()
  
  coEvery { mockRemote.getUser("123") } throws NetworkException()
  coEvery { mockLocal.get("123") } returns User("123")
  
  val repo = UserRepositoryImpl(mockRemote, mockLocal)
  val result = repo.getUser("123")
  
  assertEquals("123", result.id)
}

// Presentation test: ViewModel state
@Test
fun viewModelEmitsSuccessOnLoginSuccess() = runTest {
  val mockUseCase = mockk<LoginUseCase>()
  coEvery { mockUseCase("a@b.c", "pass") } returns Result.success(User("123"))
  
  val viewModel = LoginViewModel(mockUseCase, mockAnalytics)
  viewModel.login("a@b.c", "pass")
  advanceUntilIdle()
  
  assertEquals(LoginState.Success(User("123")), viewModel.state.value)
}
```

**Benefit**: Each layer tested independently without depending on others.
