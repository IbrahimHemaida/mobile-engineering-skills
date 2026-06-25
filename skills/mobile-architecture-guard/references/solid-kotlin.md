# SOLID Principles in Kotlin/Android

## Single Responsibility Principle (SRP)

**Definition**: A class should be answerable to one stakeholder group only.

### ❌ Bad: Multiple Reasons to Change

```kotlin
class UserViewModel(private val repo: UserRepository) : ViewModel() {
  private val _user = MutableLiveData<User>()
  val user: LiveData<User> = _user
  
  fun loadUser(id: String) {
    viewModelScope.launch {
      val user = repo.getUser(id)
      _user.value = user
      
      // SRP violation: Also handling caching
      saveUserToCache(user)
      
      // SRP violation: Also handling analytics
      trackUserLoad(id)
      
      // SRP violation: Also handling date formatting
      val formatted = SimpleDateFormat("dd/MM/yyyy").format(Date())
      logEvent("User loaded: $formatted")
    }
  }
  
  private fun saveUserToCache(user: User) { /* ... */ }
  private fun trackUserLoad(id: String) { /* ... */ }
}
```

**Reasons to change**:
1. User loading logic changes
2. Cache strategy changes
3. Analytics implementation changes
4. Date format changes

### ✅ Good: Single Responsibility

```kotlin
// Responsibility: Load and expose user data
class UserViewModel(
  private val loadUserUseCase: LoadUserUseCase,
  private val analyticsService: AnalyticsService
) : ViewModel() {
  private val _user = MutableLiveData<User>()
  val user: LiveData<User> = _user
  
  fun loadUser(id: String) {
    viewModelScope.launch {
      val user = loadUserUseCase.invoke(id)
      _user.value = user
      analyticsService.trackUserLoaded(id)
    }
  }
}

// Responsibility: Orchestrate loading and caching
class LoadUserUseCase(
  private val remoteSource: RemoteUserDataSource,
  private val localCache: UserCache
) {
  suspend operator fun invoke(id: String): User {
    return try {
      val user = remoteSource.getUser(id)
      localCache.save(user)
      user
    } catch (e: Exception) {
      localCache.get(id) ?: throw e
    }
  }
}

// Responsibility: Fetch from remote API only
class RemoteUserDataSource(private val api: UserApi) {
  suspend fun getUser(id: String): User = api.getUser(id)
}

// Responsibility: Cache management only
class UserCache(private val prefs: SharedPreferences) {
  fun save(user: User) {
    prefs.edit().putString("user_${user.id}", user.toJson()).apply()
  }
  
  fun get(id: String): User? {
    val json = prefs.getString("user_$id", null) ?: return null
    return User.fromJson(json)
  }
}

// Responsibility: Analytics only
class AnalyticsService(private val firebase: FirebaseAnalytics) {
  fun trackUserLoaded(userId: String) {
    firebase.logEvent("user_loaded", Bundle().apply {
      putString("user_id", userId)
      putString("timestamp", System.currentTimeMillis().toString())
    })
  }
}
```

**Why it's better**:
- Each class has one reason to change
- Easy to test (mock individual responsibilities)
- Reusable components (AnalyticsService used elsewhere)
- Clear separation of concerns

---

## Open/Closed Principle (OCP)

**Definition**: Software entities should be open for extension, closed for modification.

### ❌ Bad: Modifying Existing Code for New Auth Methods

```kotlin
class AuthUseCase(private val repo: AuthRepository) {
  suspend fun login(email: String, password: String): Result<User> {
    return when {
      email.contains("@gmail.com") -> repo.loginWithGoogle(email, password)
      email.contains("@company.com") -> repo.loginWithCompany(email, password)
      else -> repo.loginWithEmail(email, password)
      // When adding social login, biometric, etc., modify this function
    }
  }
}
```

**Problem**: Adding a new auth method requires changing `AuthUseCase`.

### ✅ Good: Extend via Strategy Pattern

```kotlin
// Abstraction: closed for modification
interface AuthStrategy {
  suspend fun authenticate(email: String, password: String): User
}

// Gmail strategy
class GoogleAuthStrategy(private val googleAuth: GoogleSignInClient) : AuthStrategy {
  override suspend fun authenticate(email: String, password: String): User {
    // Google-specific logic
  }
}

// Company strategy
class CompanyAuthStrategy(private val api: CompanyApi) : AuthStrategy {
  override suspend fun authenticate(email: String, password: String): User {
    // Company-specific logic
  }
}

// Email strategy
class EmailAuthStrategy(private val api: UserApi) : AuthStrategy {
  override suspend fun authenticate(email: String, password: String): User {
    // Email-specific logic
  }
}

// Social login (new feature — no modification needed!)
class SocialAuthStrategy(private val socialApi: SocialApi) : AuthStrategy {
  override suspend fun authenticate(email: String, password: String): User {
    // Social-specific logic
  }
}

// Use case: CLOSED for modification, OPEN for extension
class AuthUseCase(private val strategyFactory: AuthStrategyFactory) {
  suspend fun login(email: String, password: String): Result<User> {
    val strategy = strategyFactory.getStrategy(email)
    return try {
      Result.success(strategy.authenticate(email, password))
    } catch (e: Exception) {
      Result.failure(e)
    }
  }
}

// Factory: decides which strategy to use
class AuthStrategyFactory {
  fun getStrategy(email: String): AuthStrategy = when {
    email.contains("@gmail.com") -> GoogleAuthStrategy(googleClient)
    email.contains("@company.com") -> CompanyAuthStrategy(companyApi)
    email.contains("@social.") -> SocialAuthStrategy(socialApi)
    else -> EmailAuthStrategy(userApi)
  }
}
```

**Why it's better**:
- New auth methods = new class, no modifications
- Existing code remains stable and tested
- Easy to test each strategy independently

---

## Liskov Substitution Principle (LSP)

**Definition**: Objects of a superclass should be replaceable with objects of its subclasses without breaking the application.

### ❌ Bad: Violating the Contract

```kotlin
interface PaymentRepository {
  suspend fun processPayment(amount: Double): PaymentResult
}

// Stripe implementation — works normally
class StripePaymentRepository : PaymentRepository {
  override suspend fun processPayment(amount: Double): PaymentResult {
    return PaymentResult.Success(transactionId = "stripe_123")
  }
}

// Paypal implementation — VIOLATES CONTRACT
class PaypalPaymentRepository : PaymentRepository {
  override suspend fun processPayment(amount: Double): PaymentResult {
    // Returns null instead of PaymentResult — violates LSP!
    return null  // ← This breaks the contract
  }
}

// Client code assumes contract is upheld
val repo: PaymentRepository = getRepository()
val result = repo.processPayment(100.0)
println(result.transactionId)  // ← Crashes if repo is Paypal!
```

### ✅ Good: Honor the Contract

```kotlin
interface PaymentRepository {
  suspend fun processPayment(amount: Double): PaymentResult
}

sealed class PaymentResult {
  data class Success(val transactionId: String) : PaymentResult()
  data class Failure(val error: PaymentError) : PaymentResult()
}

class StripePaymentRepository : PaymentRepository {
  override suspend fun processPayment(amount: Double): PaymentResult {
    return try {
      val txn = stripeApi.charge(amount)
      PaymentResult.Success(txn.id)
    } catch (e: Exception) {
      PaymentResult.Failure(PaymentError.NetworkError)
    }
  }
}

class PaypalPaymentRepository : PaymentRepository {
  override suspend fun processPayment(amount: Double): PaymentResult {
    return try {
      val txn = paypalApi.pay(amount)
      PaymentResult.Success(txn.id)
    } catch (e: Exception) {
      PaymentResult.Failure(PaymentError.AuthError)
    }
  }
}

// Client code: can use any implementation safely
val repo: PaymentRepository = getRepository()
val result = repo.processPayment(100.0)
when (result) {
  is PaymentResult.Success -> println("Paid: ${result.transactionId}")
  is PaymentResult.Failure -> println("Error: ${result.error}")
}
```

**Why it's better**:
- All implementations honor the contract
- Implementations are drop-in replaceable
- Client code doesn't break on impl changes

---

## Interface Segregation Principle (ISP)

**Definition**: Clients should not depend on interfaces they don't use.

### ❌ Bad: Fat Interface

```kotlin
// Client depends on methods it doesn't use
interface DataRepository {
  suspend fun getUser(id: String): User
  suspend fun saveUser(user: User): Unit
  suspend fun deleteUser(id: String): Unit
  suspend fun getPayment(id: String): Payment
  suspend fun savePayment(payment: Payment): Unit
  suspend fun deletePayment(id: String): Unit
  suspend fun generateReport(): Report
}

class UserProfileScreen(private val repo: DataRepository) {
  fun loadProfile(userId: String) {
    val user = repo.getUser(userId)  // Uses this
    // Doesn't care about payment or report methods!
  }
}
```

### ✅ Good: Segregated Interfaces

```kotlin
// Specific interfaces
interface UserRepository {
  suspend fun getUser(id: String): User
  suspend fun saveUser(user: User): Unit
  suspend fun deleteUser(id: String): Unit
}

interface PaymentRepository {
  suspend fun getPayment(id: String): Payment
  suspend fun savePayment(payment: Payment): Unit
  suspend fun deletePayment(id: String): Unit
}

interface ReportRepository {
  suspend fun generateReport(): Report
}

// Each screen depends only on what it uses
class UserProfileScreen(private val userRepo: UserRepository) {
  fun loadProfile(userId: String) {
    val user = userRepo.getUser(userId)
  }
}

class PaymentScreen(private val paymentRepo: PaymentRepository) {
  fun processPayment(payment: Payment) {
    paymentRepo.savePayment(payment)
  }
}

class ReportScreen(private val reportRepo: ReportRepository) {
  fun loadReport() {
    val report = reportRepo.generateReport()
  }
}
```

**Why it's better**:
- Each class depends only on what it uses
- Easy to mock specific repositories
- Changes to payment API don't affect UserProfileScreen

---

## Dependency Inversion Principle (DIP)

**Definition**: Depend on abstractions, not concretions.

### ❌ Bad: Depends on Concrete Implementation

```kotlin
class LoginViewModel : ViewModel() {
  // Direct dependency on concrete HTTP client
  private val apiService = RetrofitAuthService()
  
  fun login(email: String, password: String) {
    viewModelScope.launch {
      // Tightly coupled to RetrofitAuthService
      val user = apiService.login(email, password)
      // Can't test without hitting real API
      // Can't swap Retrofit for another HTTP client
    }
  }
}
```

### ✅ Good: Depends on Abstraction

```kotlin
// Abstraction: ViewModel doesn't know if it's Retrofit, OkHttp, etc.
interface AuthRepository {
  suspend fun login(email: String, password: String): User
}

class LoginViewModel(
  private val authRepo: AuthRepository  // ← Inject abstraction
) : ViewModel() {
  fun login(email: String, password: String) {
    viewModelScope.launch {
      val user = authRepo.login(email, password)
      // Testable: mock AuthRepository
      // Swappable: use any AuthRepository impl
    }
  }
}

// Concrete implementation in Data layer
class RetrofitAuthRepository(
  private val apiService: AuthApi
) : AuthRepository {
  override suspend fun login(email: String, password: String): User {
    return apiService.login(email, password)
  }
}

// Easy to test with a mock
class TestAuthRepository : AuthRepository {
  override suspend fun login(email: String, password: String): User {
    return User("test@example.com")
  }
}

// Usage in production
val authRepo: AuthRepository = RetrofitAuthRepository(retrofitApi)
val viewModel = LoginViewModel(authRepo)

// Usage in tests
val mockRepo: AuthRepository = TestAuthRepository()
val viewModel = LoginViewModel(mockRepo)
```

**Why it's better**:
- ViewModel doesn't know about Retrofit
- Easy to test with mock repository
- Easy to swap HTTP clients (Retrofit → OkHttp → Ktor)
- Dependency flow: Presentation → Domain ← Data

---

## Summary: SOLID Checklist for Kotlin/Android

| Principle | Check For | Red Flag |
|-----------|-----------|----------|
| **SRP** | One reason to change per class | Multiple responsibilities (User + Cache + Analytics) |
| **OCP** | New features = new classes | Modifying existing code for new features |
| **LSP** | Implementations honor contract | Nulls, exceptions, missing fields |
| **ISP** | Classes use all interface methods | Unused methods in interface |
| **DIP** | Depend on interfaces/abstractions | Direct `new ConcreteClass()` |

