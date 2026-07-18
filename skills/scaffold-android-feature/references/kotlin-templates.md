# Kotlin/Android Feature Templates

Placeholders: `{Name}` = PascalCase feature name (e.g. `Profile`), `{name}` = camelCase (e.g. `profile`).

## Domain Layer

**domain/model/{Name}.kt**
```kotlin
data class {Name}(
    val id: String,
    // fields inferred from the user's description, or left minimal if none given
)
```

**domain/repository/{Name}Repository.kt**
```kotlin
interface {Name}Repository {
    suspend fun get{Name}(id: String): Result<{Name}>
    suspend fun update{Name}({name}: {Name}): Result<Unit>
}
```

**domain/usecase/Get{Name}UseCase.kt**
```kotlin
class Get{Name}UseCase @Inject constructor(
    private val repository: {Name}Repository
) {
    suspend operator fun invoke(id: String): Result<{Name}> = repository.get{Name}(id)
}
```

**domain/usecase/Update{Name}UseCase.kt**
```kotlin
class Update{Name}UseCase @Inject constructor(
    private val repository: {Name}Repository
) {
    suspend operator fun invoke({name}: {Name}): Result<Unit> = repository.update{Name}({name})
}
```

## Data Layer

**data/remote/{Name}Dto.kt**
```kotlin
data class {Name}Dto(
    val id: String,
    // mirrors API response shape — do NOT reuse for the domain model directly
)
```

**data/remote/{Name}Api.kt**
```kotlin
interface {Name}Api {
    @GET("{name}s/{id}")
    suspend fun get{Name}(@Path("id") id: String): {Name}Dto

    @PUT("{name}s/{id}")
    suspend fun update{Name}(@Path("id") id: String, @Body dto: {Name}Dto): Response<Unit>
}
```

**data/local/{Name}Entity.kt** (Room)
```kotlin
@Entity(tableName = "{name}s")
data class {Name}Entity(
    @PrimaryKey val id: String,
    // cached fields
)
```

**data/local/{Name}Dao.kt**
```kotlin
@Dao
interface {Name}Dao {
    @Query("SELECT * FROM {name}s WHERE id = :id")
    suspend fun get{Name}(id: String): {Name}Entity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert{Name}(entity: {Name}Entity)
}
```

**data/mapper/{Name}Mapper.kt**
```kotlin
fun {Name}Dto.toDomain(): {Name} = {Name}(id = id)
fun {Name}Entity.toDomain(): {Name} = {Name}(id = id)
fun {Name}.toEntity(): {Name}Entity = {Name}Entity(id = id)
```

**data/repository/{Name}RepositoryImpl.kt**
```kotlin
class {Name}RepositoryImpl @Inject constructor(
    private val api: {Name}Api,
    private val dao: {Name}Dao
) : {Name}Repository {

    override suspend fun get{Name}(id: String): Result<{Name}> = runCatching {
        dao.get{Name}(id)?.toDomain()
            ?: api.get{Name}(id).also { dao.upsert{Name}(it.toEntity(id)) }.toDomain()
    }

    override suspend fun update{Name}({name}: {Name}): Result<Unit> = runCatching {
        api.update{Name}({name}.id, {name}.toDto())
        dao.upsert{Name}({name}.toEntity())
        Unit
    }
}
```

## Presentation Layer

**presentation/{Name}UiState.kt**
```kotlin
sealed interface {Name}UiState {
    data object Loading : {Name}UiState
    data class Success(val {name}: {Name}) : {Name}UiState
    data class Error(val message: String) : {Name}UiState
}
```

**presentation/{Name}ViewModel.kt**
```kotlin
@HiltViewModel
class {Name}ViewModel @Inject constructor(
    private val get{Name}UseCase: Get{Name}UseCase,
    private val update{Name}UseCase: Update{Name}UseCase
) : ViewModel() {

    private val _state = MutableStateFlow<{Name}UiState>({Name}UiState.Loading)
    val state: StateFlow<{Name}UiState> = _state.asStateFlow()

    fun load(id: String) {
        viewModelScope.launch {
            _state.value = {Name}UiState.Loading
            get{Name}UseCase(id).fold(
                onSuccess = { _state.value = {Name}UiState.Success(it) },
                onFailure = { _state.value = {Name}UiState.Error(it.message ?: "Unknown error") }
            )
        }
    }

    fun save({name}: {Name}) {
        viewModelScope.launch {
            update{Name}UseCase({name})
        }
    }
}
```

**presentation/{Name}Screen.kt**
```kotlin
@Composable
fun {Name}Screen(viewModel: {Name}ViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsState()

    when (val s = state) {
        is {Name}UiState.Loading -> CircularProgressIndicator(
            modifier = Modifier.semantics { contentDescription = "Loading {name}" }
        )
        is {Name}UiState.Success -> {Name}Content(
            {name} = s.{name},
            onSave = viewModel::save
        )
        is {Name}UiState.Error -> Text(
            text = s.message,
            modifier = Modifier.semantics { contentDescription = "Error: ${s.message}" }
        )
    }
}
```

## DI

**di/{Name}Module.kt**
```kotlin
@Module
@InstallIn(SingletonComponent::class)
abstract class {Name}Module {
    @Binds
    abstract fun bind{Name}Repository(impl: {Name}RepositoryImpl): {Name}Repository
}
```

## Tests

**domain/usecase/Get{Name}UseCaseTest.kt**
```kotlin
class Get{Name}UseCaseTest {
    private val repository = mockk<{Name}Repository>()
    private val useCase = Get{Name}UseCase(repository)

    @Test
    fun `returns success when repository succeeds`() = runTest {
        val expected = {Name}(id = "1")
        coEvery { repository.get{Name}("1") } returns Result.success(expected)

        val result = useCase("1")

        assertEquals(Result.success(expected), result)
    }

    @Test
    fun `returns failure when repository fails`() = runTest {
        coEvery { repository.get{Name}("1") } returns Result.failure(IOException())

        val result = useCase("1")

        assertTrue(result.isFailure)
    }
}
```

**presentation/{Name}ViewModelTest.kt**
```kotlin
class {Name}ViewModelTest {
    private val get{Name}UseCase = mockk<Get{Name}UseCase>()
    private val update{Name}UseCase = mockk<Update{Name}UseCase>()
    private lateinit var viewModel: {Name}ViewModel

    @Before
    fun setup() {
        viewModel = {Name}ViewModel(get{Name}UseCase, update{Name}UseCase)
    }

    @Test
    fun `load emits Loading then Success`() = runTest {
        val expected = {Name}(id = "1")
        coEvery { get{Name}UseCase("1") } returns Result.success(expected)

        viewModel.state.test {
            viewModel.load("1")
            assertEquals({Name}UiState.Loading, awaitItem())
            assertEquals({Name}UiState.Success(expected), awaitItem())
        }
    }
}
```

**presentation/{Name}ScreenTest.kt**
```kotlin
@get:Rule
val composeRule = createComposeRule()

@Test
fun errorState_showsAccessibleErrorMessage() {
    val fakeViewModel = FakeViewModel(initialState = {Name}UiState.Error("Network error"))

    composeRule.setContent { {Name}Screen(viewModel = fakeViewModel) }

    composeRule.onNodeWithContentDescription("Error: Network error").assertIsDisplayed()
}
```
