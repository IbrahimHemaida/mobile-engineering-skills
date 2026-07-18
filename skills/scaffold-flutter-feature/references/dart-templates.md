# Flutter Feature Templates

Placeholders: `{Name}` = PascalCase (e.g. `Profile`), `{name}` = snake_case (e.g. `profile`).

## Domain Layer

**domain/entities/{name}.dart**
```dart
class {Name} extends Equatable {
  final String id;
  // fields inferred from the user's description, or left minimal if none given

  const {Name}({required this.id});

  @override
  List<Object?> get props => [id];
}
```

**domain/repositories/{name}_repository.dart**
```dart
abstract class {Name}Repository {
  Future<Either<Failure, {Name}>> get{Name}(String id);
  Future<Either<Failure, Unit>> update{Name}({Name} entity);
}
```

**domain/usecases/get_{name}_usecase.dart**
```dart
@injectable
class Get{Name}UseCase {
  final {Name}Repository repository;
  Get{Name}UseCase(this.repository);

  Future<Either<Failure, {Name}>> call(String id) => repository.get{Name}(id);
}
```

**domain/usecases/update_{name}_usecase.dart**
```dart
@injectable
class Update{Name}UseCase {
  final {Name}Repository repository;
  Update{Name}UseCase(this.repository);

  Future<Either<Failure, Unit>> call({Name} entity) => repository.update{Name}(entity);
}
```

## Data Layer

**data/models/{name}_model.dart**
```dart
class {Name}Model extends {Name} {
  const {Name}Model({required super.id});

  factory {Name}Model.fromJson(Map<String, dynamic> json) =>
      {Name}Model(id: json['id'] as String);

  Map<String, dynamic> toJson() => {'id': id};
}
```

**data/datasources/{name}_remote_datasource.dart**
```dart
abstract class {Name}RemoteDataSource {
  Future<{Name}Model> get{Name}(String id);
  Future<void> update{Name}({Name}Model model);
}

@LazySingleton(as: {Name}RemoteDataSource)
class {Name}RemoteDataSourceImpl implements {Name}RemoteDataSource {
  final Dio dio;
  {Name}RemoteDataSourceImpl(this.dio);

  @override
  Future<{Name}Model> get{Name}(String id) async {
    final response = await dio.get('/{name}s/$id');
    return {Name}Model.fromJson(response.data);
  }

  @override
  Future<void> update{Name}({Name}Model model) async {
    await dio.put('/{name}s/${model.id}', data: model.toJson());
  }
}
```

**data/datasources/{name}_local_datasource.dart**
```dart
abstract class {Name}LocalDataSource {
  Future<{Name}Model?> getCached{Name}(String id);
  Future<void> cache{Name}({Name}Model model);
}

@LazySingleton(as: {Name}LocalDataSource)
class {Name}LocalDataSourceImpl implements {Name}LocalDataSource {
  final Box<Map> box; // Hive box, or swap for sqflite/drift per project convention
  {Name}LocalDataSourceImpl(this.box);

  @override
  Future<{Name}Model?> getCached{Name}(String id) async {
    final raw = box.get(id);
    return raw == null ? null : {Name}Model.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> cache{Name}({Name}Model model) async {
    await box.put(model.id, model.toJson());
  }
}
```

**data/repositories/{name}_repository_impl.dart**
```dart
@LazySingleton(as: {Name}Repository)
class {Name}RepositoryImpl implements {Name}Repository {
  final {Name}RemoteDataSource remote;
  final {Name}LocalDataSource local;

  {Name}RepositoryImpl(this.remote, this.local);

  @override
  Future<Either<Failure, {Name}>> get{Name}(String id) async {
    try {
      final cached = await local.getCached{Name}(id);
      if (cached != null) return Right(cached);

      final remoteModel = await remote.get{Name}(id);
      await local.cache{Name}(remoteModel);
      return Right(remoteModel);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> update{Name}({Name} entity) async {
    try {
      final model = {Name}Model(id: entity.id);
      await remote.update{Name}(model);
      await local.cache{Name}(model);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

## Presentation Layer (BLoC)

**presentation/bloc/{name}_event.dart**
```dart
abstract class {Name}Event extends Equatable {
  const {Name}Event();
  @override
  List<Object?> get props => [];
}

class Load{Name}Requested extends {Name}Event {
  final String id;
  const Load{Name}Requested(this.id);
  @override
  List<Object?> get props => [id];
}

class Save{Name}Requested extends {Name}Event {
  final {Name} entity;
  const Save{Name}Requested(this.entity);
  @override
  List<Object?> get props => [entity];
}
```

**presentation/bloc/{name}_state.dart**
```dart
abstract class {Name}State extends Equatable {
  const {Name}State();
  @override
  List<Object?> get props => [];
}

class {Name}Loading extends {Name}State {}

class {Name}Loaded extends {Name}State {
  final {Name} entity;
  const {Name}Loaded(this.entity);
  @override
  List<Object?> get props => [entity];
}

class {Name}Error extends {Name}State {
  final String message;
  const {Name}Error(this.message);
  @override
  List<Object?> get props => [message];
}
```

**presentation/bloc/{name}_bloc.dart**
```dart
@injectable
class {Name}Bloc extends Bloc<{Name}Event, {Name}State> {
  final Get{Name}UseCase get{Name}UseCase;
  final Update{Name}UseCase update{Name}UseCase;

  {Name}Bloc(this.get{Name}UseCase, this.update{Name}UseCase) : super({Name}Loading()) {
    on<Load{Name}Requested>(_onLoadRequested);
    on<Save{Name}Requested>(_onSaveRequested);
  }

  Future<void> _onLoadRequested(
    Load{Name}Requested event,
    Emitter<{Name}State> emit,
  ) async {
    emit({Name}Loading());
    final result = await get{Name}UseCase(event.id);
    emit(result.fold(
      (failure) => {Name}Error(failure.message),
      (entity) => {Name}Loaded(entity),
    ));
  }

  Future<void> _onSaveRequested(
    Save{Name}Requested event,
    Emitter<{Name}State> emit,
  ) async {
    await update{Name}UseCase(event.entity);
  }
}
```

**presentation/pages/{name}_page.dart**
```dart
class {Name}Page extends StatelessWidget {
  const {Name}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<{Name}Bloc, {Name}State>(
      builder: (context, state) {
        if (state is {Name}Loading) {
          return const Center(
            child: Semantics(
              label: 'Loading {name}',
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (state is {Name}Loaded) {
          return {Name}Content(entity: state.entity);
        }
        if (state is {Name}Error) {
          return Center(
            child: Semantics(
              label: 'Error: ${state.message}',
              child: Text(state.message),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
```

## DI

**core/di/{name}_injection.dart**
```dart
// Registered automatically via @injectable / @LazySingleton annotations above.
// Run `flutter pub run build_runner build` to regenerate injection.config.dart
// after adding this feature's providers.
```

## Tests

**domain/usecases/get_{name}_usecase_test.dart**
```dart
class MockRepository extends Mock implements {Name}Repository {}

void main() {
  late Get{Name}UseCase useCase;
  late MockRepository repository;

  setUp(() {
    repository = MockRepository();
    useCase = Get{Name}UseCase(repository);
  });

  test('returns entity when repository succeeds', () async {
    const expected = {Name}(id: '1');
    when(() => repository.get{Name}('1')).thenAnswer((_) async => const Right(expected));

    final result = await useCase('1');

    expect(result, const Right(expected));
  });
}
```

**presentation/bloc/{name}_bloc_test.dart**
```dart
void main() {
  late MockGet{Name}UseCase getUseCase;
  late MockUpdate{Name}UseCase updateUseCase;

  setUp(() {
    getUseCase = MockGet{Name}UseCase();
    updateUseCase = MockUpdate{Name}UseCase();
  });

  blocTest<{Name}Bloc, {Name}State>(
    'emits [Loading, Loaded] when Load{Name}Requested succeeds',
    build: () {
      when(() => getUseCase('1')).thenAnswer((_) async => const Right({Name}(id: '1')));
      return {Name}Bloc(getUseCase, updateUseCase);
    },
    act: (bloc) => bloc.add(const Load{Name}Requested('1')),
    expect: () => [isA<{Name}Loading>(), const {Name}Loaded({Name}(id: '1'))],
  );
}
```

**presentation/pages/{name}_page_test.dart**
```dart
void main() {
  testWidgets('shows accessible error message on {Name}Error', (tester) async {
    final bloc = Mock{Name}Bloc();
    whenListen(bloc, Stream.value(const {Name}Error('Network error')),
        initialState: {Name}Loading());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<{Name}Bloc>.value(
          value: bloc,
          child: const {Name}Page(),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Error: Network error'), findsOneWidget);
  });
}
```
