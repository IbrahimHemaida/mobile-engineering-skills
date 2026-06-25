# Changelog

All notable changes to mobile-engineering-skills will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-25

### Added

#### Skills
- **mobile-architecture-guard**: Review Kotlin/Android and Flutter code for SOLID principles, Clean Architecture, modular design
  - 20 imperatives covering layer separation, dependency injection, module structure, state management, repository patterns
  - Complete integration guide with examples

- **mobile-tdd-guard**: Test-driven development workflow for mobile development (red-green-refactor cycle)
  - 20 imperatives covering test structure, mocking, boundary testing, framework-specific patterns
  - Kotlin/Android and Flutter specific guidance

#### Reference Documentation
- **SOLID Principles in Kotlin**: Detailed examples of Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **Clean Architecture**: Three-layer architecture (Domain, Data, Presentation) with Kotlin examples
- **Dependency Injection**: Constructor injection, DI containers (Hilt, GetIt), testing patterns
- **Kotlin Testing Patterns**: JUnit, MockK, StateFlow, LiveData, coroutine testing
- **Flutter Testing Patterns**: Widget tests, BLoC testing, mockito patterns, pump vs pumpAndSettle

#### Examples
- Kotlin Clean Architecture project structure
- Flutter BLoC architecture example
- TDD workflow examples for both platforms

#### Infrastructure
- GitHub Actions workflow for validation
- npm/npx installation support
- MIT License
- Contributing guidelines

### Features

#### mobile-architecture-guard
- Enforce SRP (one ViewModel per screen, one repository per domain concept)
- Validate layer dependencies (Presentation → Domain ← Data)
- Detect circular imports between features
- Check dependency injection patterns
- Validate state management centralization
- Ensure domain layer framework-independence
- Module boundary validation
- Testing boundary checks

#### mobile-tdd-guard
- Guide red-green-refactor cycle
- Mock external dependencies properly
- Test behavior, not implementation
- Validate boundary/edge case testing
- Prevent test duplication
- Flutter-specific patterns (pump, pumpAndSettle, bloc_test)
- Kotlin-specific patterns (runTest, StateFlow, coEvery)
- Exception handling best practices

### Documentation
- Comprehensive README with quick start
- Detailed SKILL.md files for each skill
- Reference guides for architecture and testing
- Real-world examples for both Kotlin and Flutter
- Troubleshooting guides

---

## Future Roadmap

### Planned for v1.1
- [ ] Domain modeling skill (sharpen project vocabulary and terms)
- [ ] Kotlin-specific refactoring patterns
- [ ] Flutter-specific performance optimization skill
- [ ] Healthcare domain-specific patterns (Patient, Appointment, Prescription entities)
- [ ] More examples (e-commerce, social apps, fintech)

### Planned for v1.2
- [ ] KMM (Kotlin Multiplatform Mobile) specific guidance
- [ ] Integration test patterns
- [ ] CI/CD best practices for mobile
- [ ] Performance profiling skill

### Community Contributions Welcome
- Additional language examples (Swift, Dart-specific patterns)
- Domain-specific examples (healthcare, e-commerce, fintech)
- Refactoring patterns
- Anti-patterns and how to fix them

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Reporting issues
- Suggesting improvements
- Submitting pull requests
- Coding standards

---

## Notes

These skills are based on:
- Clean Architecture (Robert C. Martin, 2012)
- Test-Driven Development (Kent Beck, 2002)
- SOLID Principles (Robert C. Martin)
- Domain-Driven Design (Eric Evans, 2003)
- Growing Object-Oriented Software, Guided by Tests (Freeman & Pryce, 2009)
- The Pragmatic Programmer (Hunt & Thomas, 2019)

Over 13+ years of mobile engineering experience across Android, iOS, Flutter, and Kotlin Multiplatform.
