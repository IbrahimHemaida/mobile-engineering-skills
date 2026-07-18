# Unidirectional Data Flow (UDF) in Mobile Architecture

## Table of Contents

- [Why UDF](#why-udf)
- [Kotlin/Android UDF Example](#kotlinandroid-udf-example)
- [Flutter UDF Example](#flutter-udf-example)
- [Reviewing State Management](#reviewing-state-management)

## Why UDF

State flows DOWN immutable; events flow UP via explicit actions. This is the core discipline behind imperative #14 in `SKILL.md`:

- **State flows DOWN to UI**: ViewModel/BLoC emits immutable state as `StateFlow<State>`, `LiveData<State>`, or streams.
- **UI reads state ONLY**: Fragment/Activity/Widget observes state, NEVER mutates it.
- **Events flow UP**: UI sends user actions to ViewModel via explicit methods (`login()`, `updateProfile()`), never direct state mutations.
- **Single source of truth per screen/feature**: One ViewModel per screen, not scattered across fragments or widgets.

## Kotlin/Android UDF Example

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

## Flutter UDF Example

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

## Reviewing State Management

Reject any pattern that passes mutable state objects down to the UI, or that allows the UI to directly mutate shared state. Flag violations with reference to imperative #14 in findings.
