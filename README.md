# Mobile Engineering Skills

Professional AI agent skills for building high-quality Kotlin/Android and Flutter mobile applications. These skills enforce SOLID principles, Clean Architecture, and test-driven development patterns based on years of mobile engineering experience.

**For real engineers, not vibe coding.**

---

## 🎯 What's Included

### 1. **mobile-architecture-guard**
Review Kotlin/Android and Flutter code for SOLID principles, Clean Architecture, modular design, and architectural patterns before merge.

**Covers**:
- Layer separation (Presentation → Domain → Data)
- Dependency injection & inversion of control
- Feature-based modularization
- Repository patterns
- State management (MVVM, BLoC, Provider)
- Testing boundaries

**Use when**: Reviewing feature PRs, validating module boundaries, detecting layer leakage, checking for circular dependencies.

---

### 2. **mobile-tdd-guard**
Test-driven development workflow for Kotlin/Android and Flutter: red-green-refactor cycle with proper mocking, boundary testing, and assertion patterns.

**Covers**:
- Red-Green-Refactor discipline
- Unit vs. integration testing
- Mocking strategies (Mockito, MockK, mockito-dart)
- Test naming & specification
- Boundary conditions & edge cases
- Flutter widget testing (pump, pumpAndSettle)
- Kotlin coroutine testing (runTest, coEvery)

**Use when**: Building features via TDD, fixing bugs with reproducible tests, ensuring code is testable from day one.

---

## ⚡ Quick Start (30 seconds)

### Installation

#### Option 1: Using npx (Recommended)
```bash
npx skills@latest add IbrahimHemaida/mobile-engineering-skills
```

#### Option 2: Manual Setup
1. Clone this repo or download the `skills/` directory
2. Copy to your AI agent's skills folder:
   ```bash
   # Claude Code / Cursor
   cp -r skills/mobile-* ~/.claude/skills/
   
   # Or for system-wide
   cp -r skills/mobile-* ~/.agents/skills/
   ```

3. Verify installation:
   ```bash
   ls ~/.claude/skills/ | grep mobile-
   ```

---

## 🚀 How to Use

### In Claude Code / Cursor

**Architecture Review** (after implementing a feature):
```
/mobile-architecture-guard

Paste your feature code. The skill will check:
- Layer separation (no presentation logic in domain)
- Dependency injection (no hardcoded dependencies)
- Module boundaries (no circular imports)
- State management patterns
- Repository contracts
```

**TDD Workflow** (building a new feature):
```
/mobile-tdd-guard

1. Write a failing test that specifies behavior
2. Implement minimal code to pass
3. Refactor for clarity
4. Repeat for next acceptance criterion
```

---

## 📚 Architecture Philosophy

These skills are built on proven principles:

**SOLID Principles** (Uncle Bob, 2014)
- **S**ingle Responsibility: One reason to change per class
- **O**pen/Closed: Open for extension, closed for modification
- **L**iskov Substitution: Subtypes are substitutable for their base types
- **I**nterface Segregation: Depend on specific contracts, not fat interfaces
- **D**ependency Inversion: Depend on abstractions, not concretions

**Clean Architecture** (Uncle Bob, 2012)
- Concentric circles: Entities → Use Cases → Interface Adapters → Frameworks & Drivers
- Dependencies point inward
- Business rules isolated from framework details

**Test-Driven Development** (Beck, 2002)
- Red: Write failing test
- Green: Make test pass
- Refactor: Improve code quality

---

## 🛠️ Skill Reference

### mobile-architecture-guard - 20 Imperatives

1. Three clear layers (Presentation, Domain, Data)
2. No upward dependencies
3. Data layer is plumbing, not business logic
4. Inject everything that changes
5. Constructor injection only; max 4 args
6. Abstractions live with the client
7. Feature-based modules, not layer-based
8. No cross-feature direct imports
9. No circular dependencies
10. ViewModel owns state
11. No state duplication / prop drilling
12. Side effects are explicit
13. Repository is a single-responsibility orchestrator
14. Data sources are interfaces
15. Domain layer testable without framework
16. SRP: One ViewModel per screen
17. OCP: Extend via new use cases, not branches
18. LSP: Mock repositories are drop-in replacements
19. ISP: Domain-specific interfaces, not fat ones
20. DIP: Depend on abstractions

**Full reference**: [skills/mobile-architecture-guard/SKILL.md](skills/mobile-architecture-guard/SKILL.md)

---

### mobile-tdd-guard - 20 Imperatives

1. Write failing test before code
2. Test behavior, not implementation
3. One thing per test
4. Test names describe scenario & outcome
5. Mock external dependencies
6. Mock the interface contract, not implementation
7. No over-specification in mocks
8. No hardcoded success fixtures
9. Test happy + 2 sad paths minimum
10. Test boundary conditions
11. Real behavior matches mock contract
12. Refactor only after test passes
13. Refactored code doesn't change test behavior
14. Avoid test code duplication
15. Use specific assertion functions
16. No assertions on logging/UI unless central
17. (Flutter) Test UI logic, not Framework
18. (Flutter) Use pump() and pumpAndSettle() correctly
19. (Kotlin) Handle coroutines with runTest
20. (Kotlin) Test ViewModel state emission

**Full reference**: [skills/mobile-tdd-guard/SKILL.md](skills/mobile-tdd-guard/SKILL.md)

---

## 📖 Detailed Guides

### For Kotlin/Android Developers
- [SOLID Principles in Kotlin](skills/mobile-architecture-guard/references/solid-kotlin.md)
- [Kotlin Testing Patterns](skills/mobile-tdd-guard/references/kotlin-testing.md)
- [Clean Architecture](skills/mobile-architecture-guard/references/clean-architecture.md)

### For Flutter Developers
- [Flutter Testing Patterns](skills/mobile-tdd-guard/references/flutter-testing.md)
- [Dependency Injection](skills/mobile-architecture-guard/references/dependency-injection.md)

---

## 🤝 Compatibility

| Platform | Testing | DI Framework | State Management |
|----------|---------|--------------|------------------|
| **Android** | JUnit 4/5, Mockito, MockK | Hilt, Dagger | LiveData, StateFlow, RxJava |
| **Flutter** | flutter_test, mockito | GetIt, Provider | BLoC, Provider, GetX, Riverpod |
| **KMM** | Both | Manual or multiplatform DI | Coroutines + Dart equivalents |

---

## 📝 License

MIT License. See [LICENSE](LICENSE) for details.

---

## 🤝 Contributing

Have improvements or new patterns? Submit issues or PRs!

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 💬 Questions?

- File an issue on GitHub
- Read the detailed reference guides in each skill
- Check examples for your platform (Kotlin/Flutter)

---

**Built by [Ibrahim Hemaida](https://github.com/IbrahimHemaida)**
Based on 13+ years of mobile engineering experience.

Happy shipping! 🚀
