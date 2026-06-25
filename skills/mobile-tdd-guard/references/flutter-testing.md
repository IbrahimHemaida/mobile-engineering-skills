# Flutter Testing Patterns

## Unit Testing

### Setup

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  bloc_test: ^9.1.0
  get_it: ^7.5.0
```

### Basic Unit Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('LoginUseCase', () {
    late LoginUseCase loginUseCase;
    late MockUserRepository mockRepository;
    
    setUp(() {
      mockRepository = MockUserRepository();
      loginUseCase = LoginUseCase(mockRepository);
    });
    
    test('returns user on valid credentials', () async {
      // ARRANGE
      when(mockRepository.login('test@example.com', 'password'))
        .thenAnswer((_) async => User('test@example.com'));
      
      // ACT
      final result = await loginUseCase.login('test@example.com', 'password');
      
      // ASSERT
      expect(result, User('test@example.com'));
      verify(mockRepository.login('test@example.com', 'password')).called(1);
    });
    
    test('throws exception on invalid credentials', () async {
      when(mockRepository.login('test@example.com', 'wrong'))
        .thenThrow(InvalidCredentialsException());
      
      expect(
        () => loginUseCase.login('test@example.com', 'wrong'),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });
  });
}
```

---

## Widget Testing

### Basic Widget Test

```dart
void main() {
  group('LoginScreen', () {
    late MockLoginBloc mockLoginBloc;
    
    setUp(() {
      mockLoginBloc = MockLoginBloc();
    });
    
    testWidgets('displays error message on login failure', (WidgetTester tester) async {
      // ARRANGE
      when(mockLoginBloc.state)
        .thenReturn(LoginState.error('Invalid credentials'));
      
      // ACT
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<LoginBloc>(
            create: (_) => mockLoginBloc,
            child: const LoginScreen(),
          ),
        ),
      );
      
      // ASSERT
      expect(find.text('Invalid credentials'), findsOneWidget);
    });
    
    testWidgets('navigates to home on successful login', (WidgetTester tester) async {
      when(mockLoginBloc.state)
        .thenReturn(LoginState.success(User('test')));
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<LoginBloc>(
            create: (_) => mockLoginBloc,
            child: const LoginScreen(),
          ),
          routes: {
            '/home': (_) => const HomeScreen(),
          },
        ),
      );
      
      // Wait for navigation
      await tester.pumpAndSettle();
      
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
```

---

## BLoC Testing (bloc_test)

```dart
void main() {
  group('UserBloc', () {
    late UserBloc userBloc;
    late MockUserRepository mockRepository;
    
    setUp(() {
      mockRepository = MockUserRepository();
      userBloc = UserBloc(mockRepository);
    });
    
    blocTest<UserBloc, UserState>(
      'emits [Loading, Success] when LoadUser succeeds',
      build: () {
        when(mockRepository.getUser('123'))
          .thenAnswer((_) async => User('123', 'John'));
        return userBloc;
      },
      act: (bloc) => bloc.add(LoadUser('123')),
      expect: () => [
        UserState.loading(),
        UserState.success(User('123', 'John')),
      ],
      verify: (_) {
        verify(mockRepository.getUser('123')).called(1);
      },
    );
    
    blocTest<UserBloc, UserState>(
      'emits [Loading, Error] when LoadUser fails',
      build: () {
        when(mockRepository.getUser('999'))
          .thenThrow(UserNotFoundException());
        return userBloc;
      },
      act: (bloc) => bloc.add(LoadUser('999')),
      expect: () => [
        UserState.loading(),
        isA<UserState>().having((s) => s.error, 'error', isNotNull),
      ],
    );
  });
}
```

---

## Pump vs PumpAndSettle

```dart
// pump(): Advance animation clock, rebuild once
testWidgets('button shows pressed state', (tester) async {
  await tester.pumpWidget(MyApp());
  
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();  // Rebuild once; animation hasn't completed
  
  expect(find.byType(AnimatedOpacity), findsOneWidget);
});

// pumpAndSettle(): Pump until no more animations/futures
testWidgets('page loads data', (tester) async {
  await tester.pumpWidget(MyApp());
  
  await tester.tap(find.text('Load'));
  await tester.pumpAndSettle();  // Wait for future, animations
  
  expect(find.text('Data loaded'), findsOneWidget);
});
```

---

## Mockito Best Practices in Dart

### Generating Mocks

```dart
// Using build_runner
import 'package:mockito/annotations.dart';

@GenerateMocks([UserRepository, PaymentRepository])
void main() {
}

// Generated in test/user_bloc_test.mocks.dart
class MockUserRepository extends Mock implements UserRepository {}
class MockPaymentRepository extends Mock implements PaymentRepository {}
```

### Setting Up Behavior

```dart
// Returns a value
when(mockRepository.getUser('123'))
  .thenAnswer((_) async => User('123'));

// Throws exception
when(mockRepository.getUser('999'))
  .thenThrow(UserNotFoundException());

// Multiple returns
when(mockRepository.getUsers())
  .thenAnswer((_) async => [User('1'), User('2')]);

// Named parameters
when(mockRepository.login(
  email: anyNamed('email'),
  password: anyNamed('password'),
)).thenAnswer((_) async => User('test'));
```

### Verifying Calls

```dart
// Was called?
verify(mockRepository.getUser('123')).called(1);

// Never called
verifyNever(mockRepository.deleteUser(any));

// Multiple calls
verify(mockRepository.getUser(any)).called(3);

// In order
verifyInOrder([
  mockRepository.getUser('1'),
  mockRepository.updateUser(any),
]);
```

---

## Real-World BLoC TDD Example

```dart
// RED: Test fails
blocTest<PaymentBloc, PaymentState>(
  'emits [Processing, Success] with transaction ID',
  build: () => PaymentBloc(mockPaymentRepository),
  seed: () => PaymentState.idle(),
  act: (bloc) => bloc.add(ProcessPaymentEvent(amount: 100.0)),
  expect: () => [
    isA<PaymentState>().having((s) => s.status, 'status', PaymentStatus.processing),
    isA<PaymentState>()
      .having((s) => s.status, 'status', PaymentStatus.success)
      .having((s) => s.transactionId, 'transactionId', 'txn_123'),
  ],
);

// GREEN: Minimal implementation
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _repository;
  
  PaymentBloc(this._repository) : super(PaymentState.idle()) {
    on<ProcessPaymentEvent>(_onProcessPayment);
  }
  
  FutureOr<void> _onProcessPayment(
    ProcessPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(status: PaymentStatus.processing));
    
    final result = await _repository.processPayment(event.amount);
    
    emit(state.copyWith(
      status: PaymentStatus.success,
      transactionId: result.transactionId,
    ));
  }
}

// REFACTOR: Add error handling
FutureOr<void> _onProcessPayment(
  ProcessPaymentEvent event,
  Emitter<PaymentState> emit,
) async {
  emit(state.copyWith(status: PaymentStatus.processing));
  
  try {
    final result = await _repository.processPayment(event.amount);
    emit(state.copyWith(
      status: PaymentStatus.success,
      transactionId: result.transactionId,
    ));
  } on PaymentException catch (e) {
    emit(state.copyWith(
      status: PaymentStatus.failure,
      error: e.message,
    ));
  }
}
```

---

## Boundary Testing in Flutter

```dart
void main() {
  group('LoginUseCase Boundary Tests', () {
    late LoginUseCase loginUseCase;
    late MockUserRepository mockRepository;
    
    setUp(() {
      mockRepository = MockUserRepository();
      loginUseCase = LoginUseCase(mockRepository);
    });
    
    // Valid case
    test('login with valid credentials', () async {
      when(mockRepository.login('test@ex.com', 'pass123'))
        .thenAnswer((_) async => User('test'));
      
      final result = await loginUseCase.login('test@ex.com', 'pass123');
      expect(result, isNotNull);
    });
    
    // Empty email
    test('login rejects empty email', () async {
      expect(
        () => loginUseCase.login('', 'pass123'),
        throwsA(isA<ValidationException>()),
      );
    });
    
    // Empty password
    test('login rejects empty password', () async {
      expect(
        () => loginUseCase.login('test@ex.com', ''),
        throwsA(isA<ValidationException>()),
      );
    });
    
    // Invalid email format
    test('login rejects invalid email format', () async {
      expect(
        () => loginUseCase.login('notanemail', 'pass123'),
        throwsA(isA<ValidationException>()),
      );
    });
    
    // Network error
    test('login propagates network error', () async {
      when(mockRepository.login(any, any))
        .thenThrow(NetworkException());
      
      expect(
        () => loginUseCase.login('test@ex.com', 'pass123'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
```

---

## Testing Streams & Futures

```dart
test('stream emits values in order', () async {
  final stream = mockRepository.getUserStream('123');
  
  expect(
    stream,
    emitsInOrder([
      User('1'),
      User('2'),
      emitsDone,
    ]),
  );
});

test('future resolves with user', () async {
  when(mockRepository.getUser('123'))
    .thenAnswer((_) async => User('123'));
  
  final user = await loginUseCase.getUser('123');
  
  expect(user.id, '123');
});
```
