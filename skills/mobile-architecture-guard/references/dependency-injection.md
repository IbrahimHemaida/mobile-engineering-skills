# Dependency Injection in Kotlin/Android

## Why Dependency Injection (DI)?

Without DI:
```kotlin
class LoginViewModel : ViewModel() {
  // Hard-coded dependency: can't test, can't change
  private val authRepository = RetrofitAuthRepository()
  
  fun login(email: String, password: String) {
    val user = authRepository.login(email, password)
    // Can't test without hitting real API
  }
}
```

With DI:
```kotlin
class LoginViewModel(
  private val authRepository: AuthRepository  // Injected
) : ViewModel() {
  fun login(email: String, password: String) {
    val user = authRepository.login(email, password)
    // Can test with mock AuthRepository
  }
}
```

---

## Three DI Patterns

### 1. Constructor Injection (RECOMMENDED)

```kotlin
class LoginViewModel(
  private val authRepository: AuthRepository,
  private val analyticsService: AnalyticsService
) : ViewModel() {
  // Dependencies are final, testable
}

// Usage
val viewModel = LoginViewModel(
  authRepository = RealAuthRepository(),
  analyticsService = FirebaseAnalytics()
)

// Testing
val viewModel = LoginViewModel(
  authRepository = MockAuthRepository(),
  analyticsService = MockAnalytics()
)
```

**Pros**:
- Immutable dependencies
- Clear which dependencies are needed
- Easy to test

**Cons**:
- More parameters (solved with DI container)

---

### 2. Setter Injection (NOT RECOMMENDED)

```kotlin
class LoginViewModel : ViewModel() {
  var authRepository: AuthRepository? = null
  
  fun login(email: String, password: String) {
    authRepository?.login(email, password)  // Nullable!
  }
}

// Usage
val viewModel = LoginViewModel()
viewModel.authRepository = RealAuthRepository()
```

**Cons**:
- Nullable dependencies = bugs
- No guarantee dependencies are set
- Hard to test

---

### 3. Service Locator (AVOID for most cases)

```kotlin
object ServiceLocator {
  private val services = mutableMapOf<Class<*>, Any>()
  
  fun register(clazz: Class<*>, instance: Any) {
    services[clazz] = instance
  }
  
  fun <T> get(clazz: Class<T>): T = services[clazz] as T
}

class LoginViewModel : ViewModel() {
  private val authRepository = ServiceLocator.get(AuthRepository::class.java)
}
```

**Cons**:
- Hard to test (global state)
- Dependencies not visible
- Runtime errors if dependency missing

---

## DI Containers

### Manual DI (Simple Projects)

```kotlin
class AuthModule {
  fun provideAuthApi(): AuthApi {
    val retrofit = Retrofit.Builder()
      .baseUrl("https://api.example.com")
      .addConverterFactory(GsonConverterFactory.create())
      .build()
    return retrofit.create(AuthApi::class.java)
  }
  
  fun provideAuthDataSource(): RemoteAuthDataSource {
    return RemoteAuthDataSource(provideAuthApi())
  }
  
  fun provideLocalAuthDataSource(context: Context): LocalAuthDataSource {
    val prefs = context.getSharedPreferences("auth", Context.MODE_PRIVATE)
    return LocalAuthDataSource(prefs)
  }
  
  fun provideAuthRepository(
    remote: RemoteAuthDataSource,
    local: LocalAuthDataSource
  ): AuthRepository {
    return AuthRepositoryImpl(remote, local)
  }
  
  fun provideLoginUseCase(repo: AuthRepository): LoginUseCase {
    return LoginUseCase(repo)
  }
}

// Usage in Activity
class LoginActivity : AppCompatActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    
    val authModule = AuthModule()
    val authApi = authModule.provideAuthApi()
    val remoteDataSource = authModule.provideAuthDataSource()
    val localDataSource = authModule.provideLocalAuthDataSource(this)
    val authRepository = authModule.provideAuthRepository(remoteDataSource, localDataSource)
    val loginUseCase = authModule.provideLoginUseCase(authRepository)
    
    val viewModel = LoginViewModel(loginUseCase)
  }
}
```

---

### Hilt (Android's Recommended DI Framework)

```kotlin
// Step 1: Add Hilt App
@HiltAndroidApp
class MyApplication : Application()

// Step 2: Create modules
@Module
@InstallIn(SingletonComponent::class)
object AuthModule {
  @Provides
  @Singleton
  fun provideAuthApi(): AuthApi {
    return Retrofit.Builder()
      .baseUrl("https://api.example.com")
      .build()
      .create(AuthApi::class.java)
  }
  
  @Provides
  @Singleton
  fun provideAuthRepository(api: AuthApi): AuthRepository {
    return AuthRepositoryImpl(api)
  }
}

@Module
@InstallIn(ViewModelComponent::class)
object UseCaseModule {
  @Provides
  fun provideLoginUseCase(repo: AuthRepository): LoginUseCase {
    return LoginUseCase(repo)
  }
}

// Step 3: Inject into ViewModel
@HiltViewModel
class LoginViewModel @Inject constructor(
  private val loginUseCase: LoginUseCase
) : ViewModel() {
  fun login(email: String, password: String) {
    viewModelScope.launch {
      loginUseCase(email, password)
    }
  }
}

// Step 4: Inject into Activity
@AndroidEntryPoint
class LoginActivity : AppCompatActivity() {
  private val viewModel: LoginViewModel by viewModels()
  
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    // viewModel is ready with all dependencies injected
  }
}
```

**Pros**:
- Automatic wiring
- Scope management (Singleton, ViewModelScope, etc.)
- Less boilerplate

---

### GetIt (For Flutter)

```dart
// In Flutter: GetIt is the service locator
final getIt = GetIt.instance;

void setupServiceLocator() {
  // Register repositories
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(
      remoteDataSource: getIt<RemoteUserDataSource>(),
      localDataSource: getIt<LocalUserDataSource>(),
    ),
  );
  
  // Register use cases
  getIt.registerSingleton<LoginUseCase>(
    LoginUseCase(getIt<UserRepository>()),
  );
  
  // Register view models / BLoCs
  getIt.registerSingleton<LoginBloc>(
    LoginBloc(getIt<LoginUseCase>()),
  );
}

// Usage in Widget
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LoginBloc>(),
      child: _LoginView(),
    );
  }
}
```

---

## Constructor Injection Guidelines

### ✅ Good: Clear Dependencies

```kotlin
class OrderViewModel(
  private val getOrderUseCase: GetOrderUseCase,
  private val updateOrderUseCase: UpdateOrderUseCase,
  private val analyticsService: AnalyticsService
) : ViewModel()
```

**Clear**: Anyone reading the constructor knows exactly what this ViewModel needs.

### ❌ Bad: Too Many Parameters

```kotlin
class OrderViewModel(
  private val getOrderUseCase: GetOrderUseCase,
  private val updateOrderUseCase: UpdateOrderUseCase,
  private val cancelOrderUseCase: CancelOrderUseCase,
  private val deleteOrderUseCase: DeleteOrderUseCase,
  private val analyticsService: AnalyticsService,
  private val loggingService: LoggingService,
  private val crashReportingService: CrashReportingService,
  private val preferencesService: PreferencesService
) : ViewModel()
```

**Solution**: Create a dependency holder (if truly needed)

```kotlin
data class OrderDependencies(
  val getOrderUseCase: GetOrderUseCase,
  val updateOrderUseCase: UpdateOrderUseCase,
  val cancelOrderUseCase: CancelOrderUseCase,
  val deleteOrderUseCase: DeleteOrderUseCase,
  val analyticsService: AnalyticsService,
  val loggingService: LoggingService,
  val crashReportingService: CrashReportingService,
  val preferencesService: PreferencesService
)

class OrderViewModel(
  private val dependencies: OrderDependencies
) : ViewModel()
```

**Better solution**: The class might be doing too much. Split it.

---

## Testing with DI

```kotlin
class LoginViewModelTest {
  private lateinit var viewModel: LoginViewModel
  private val mockUseCase = mockk<LoginUseCase>()
  
  @Before
  fun setUp() {
    // Inject mock
    viewModel = LoginViewModel(mockUseCase)
  }
  
  @Test
  fun loginWithValidCreds() = runTest {
    coEvery { mockUseCase("a@b.c", "pass") } returns Result.success(User("123"))
    
    viewModel.login("a@b.c", "pass")
    advanceUntilIdle()
    
    assertTrue(viewModel.state.value is LoginState.Success)
  }
  
  @Test
  fun loginWithInvalidCreds() = runTest {
    coEvery { mockUseCase("", "pass") } returns Result.failure(InvalidCredentialsException())
    
    viewModel.login("", "pass")
    advanceUntilIdle()
    
    assertTrue(viewModel.state.value is LoginState.Error)
  }
}
```

---

## DI Checklist

- [ ] All external dependencies are injected (constructor)
- [ ] Repositories injected as interfaces, not concrete classes
- [ ] Use cases injected into ViewModels
- [ ] No `ServiceLocator.get()` calls in business logic
- [ ] No `Context` passed around unless absolutely necessary
- [ ] Testable with mocks (can swap implementations)
