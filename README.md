# 📱 Mobile Engineering Skills

> **Battle-tested, token-optimized AI guardrails for Senior Mobile Team Leads and Engineers.**

Professional AI agent skills for building high-quality Kotlin/Android and Flutter mobile applications with SOLID principles, Clean Architecture, and test-driven development patterns. Built for real engineering—not vibe coding.

Engineered for **13+ years** of production mobile development across Android, Flutter, and Kotlin Multiplatform.

---

## 🎯 What This Repository Does

This is a **skill package** that supercharges your AI-assisted mobile development workflow. Instead of manually reviewing architecture and tests on every feature, these skills:

✅ **Automate expert architecture reviews** — Catch layer leakage, circular deps, DI violations before they hit main
✅ **Enforce TDD discipline** — Guide red-green-refactor cycles with test-first patterns
✅ **Token-optimize AI interactions** — Use Prompt Caching & diffs-only outputs to save tokens and speed up reviews
✅ **Standardize elite patterns** — Enforce SOLID, Clean Architecture, unidirectional data flow across teams

---

## 📚 Included Skills

### 1. **mobile-architecture-guard** 🏗️
Review Kotlin/Android and Flutter code for SOLID principles, Clean Architecture, modular design, and architectural patterns before merge.

**What it validates:**
- ✓ Layer separation (Presentation → Domain → Data with no upward dependencies)
- ✓ Dependency injection (constructor injection, no hardcoded deps)
- ✓ Feature-based modularization (no circular imports)
- ✓ Repository patterns & state management (MVVM, BLoC, Provider, UDF)
- ✓ Testing boundaries (domain testable without framework)
- ✓ Anti-patterns (ViewModel wrappers, prop drilling, God objects)

**Delivers:** Structured findings on architectural violations, layer leakage, dependency violations, and state management issues.

---

### 2. **mobile-tdd-guard** 🧪
Test-driven development workflow for Kotlin/Android and Flutter: red-green-refactor cycle with proper mocking, boundary testing, and visual regression testing.

**What it enforces:**
- ✓ Red-Green-Refactor discipline (test first, minimal code, refactor)
- ✓ Unit vs. integration testing scope
- ✓ Mock contracts, not implementations (Mockito, MockK, mockito-dart)
- ✓ Test naming & specification clarity
- ✓ Boundary conditions & edge case coverage
- ✓ Flutter widget & golden testing (visual regressions)
- ✓ Kotlin coroutine testing (runTest, suspend function mocking)
- ✓ Token-optimized output (diffs-only, no full file dumps)

**Delivers:** Guided red-green-refactor cycles with proper test structure, mocking patterns, and visual test automation.

---

## 💎 Why Use This? (The Case for AI-Assisted Architecture & Testing)

### **Problem: Without These Skills**

You write a feature in Claude Code. The code compiles, passes tests locally... but when reviewed:
- ❌ ViewModels call repositories directly (layer violation)
- ❌ State duplicated across 5 composables (prop drilling)
- ❌ Tests mock implementation details, break on refactor
- ❌ Database layer mixed with business logic
- ❌ Hard dependencies → untestable code

**Cost**: Rework, technical debt, slow onboarding for new team members.

### **Solution: Token-Optimized AI Guardrails**

These skills use **Prompt Caching** and **Diffs-Only Output** to:

1. **Save Tokens (40-60% reduction)**
   - Skill definitions cached in system context (no re-sending per request)
   - AI outputs only changed lines (diffs), not full files
   - Imperatives guide AI to skip verbose explanations

2. **Standardize Architecture Across Teams**
   - Architecture rules become testable (20 imperatives per skill)
   - Every developer reviews with same standards
   - New team members align faster

3. **Catch Issues Before Code Review**
   - AI invokes skill before sharing code
   - Finds layer violations, circular deps, state bugs in seconds
   - Saves human reviewers 30+ minutes per PR

4. **TDD-First Development**
   - Skill guides red-green-refactor cycle
   - AI doesn't skip test writing
   - Visual regression testing automated (golden files)

---

## ⚡ Quick Start (2 minutes)

### **Installation Options**

#### **Option A: npm/npx** (Recommended)
```bash
npx skills@latest add IbrahimHemaida/mobile-engineering-skills
```

#### **Option B: Manual (Git Clone)**
```bash
git clone https://github.com/IbrahimHemaida/mobile-engineering-skills.git
cp -r skills/mobile-* ~/.claude/skills/
```

#### **Option C: Download Folder**
Download `skills/` folder and copy to your agent's skill directory.

---

## 🚀 Implementation Guides

### **For Claude Code CLI**

#### **Step 1: Configure `.clauderc` or `.anthropic/instructions`**

Create `~/.clauderc` or `~/.anthropic/instructions.md`:

```yaml
# .clauderc
skills:
  - name: mobile-architecture-guard
    path: ~/.claude/skills/mobile-architecture-guard/SKILL.md
    triggers:
      - "review this architecture"
      - "check the dependency graph"
      - "validate module boundaries"
  
  - name: mobile-tdd-guard
    path: ~/.claude/skills/mobile-tdd-guard/SKILL.md
    triggers:
      - "TDD this feature"
      - "write tests first"
      - "red-green-refactor"

prompt-caching:
  enabled: true
  ttl: 3600  # 1 hour cache
```

Or in instructions.md:

```markdown
# Claude Code Mobile Engineering

When working on mobile features:
1. Use mobile-architecture-guard for architecture reviews
2. Use mobile-tdd-guard for test-driven development
3. Output diffs only (not full files)
4. Validate layer separation before commit
```

#### **Step 2: Invoke in Claude Code Terminal**

```bash
# Start a feature
claude code "Build login feature with TDD"

# Review architecture mid-session
@mobile-architecture-guard
Review this feature for layer violations

# Continue with TDD
@mobile-tdd-guard
Red: write failing test for login validation
```

**Claude Code will:**
- Cache skill definitions (save tokens)
- Output only code changes (diffs)
- Validate architecture before generating code
- Guide TDD cycle step-by-step

---

### **For Cursor IDE**

#### **Step 1: Configure `.cursor/rules/`**

Create `.cursor/rules/mobile-guards.md` in your project:

```markdown
# Mobile Engineering Guards

## Architecture
When reviewing code, use mobile-architecture-guard rules:
- Validate layer separation
- Check dependency injection patterns
- Ensure feature-based modules
- Detect circular dependencies

## Testing
When implementing features, use mobile-tdd-guard:
- Write failing test first (RED)
- Implement minimal code (GREEN)
- Refactor for clarity (REFACTOR)
- Test boundary conditions and edge cases
```

#### **Step 2: Invoke in Cursor Chat/Composer**

```
@mobile-architecture-guard Review this LoginFeature
@mobile-tdd-guard Build payment processing with TDD
```

**Or use @ mentions in Composer:**

```
@mobile-architecture-guard
Check the data layer for repository patterns

[Paste code]

@mobile-tdd-guard
TDD: write test for payment retry logic
```

**Cursor will:**
- Load skill rules into context
- Reference rules in auto-complete suggestions
- Validate code against imperatives
- Suggest refactors based on architectural rules

---

### **For Claude Desktop / Web (Prompt Caching)**

#### **Step 1: Create Project Context**

In Claude Desktop or Web, create a new Project:

1. **New Project** → Name: "Mobile Engineering"
2. **Add Files** → Include:
   - `skills/mobile-architecture-guard/SKILL.md`
   - `skills/mobile-tdd-guard/SKILL.md`
   - `skills/mobile-architecture-guard/references/` (all guides)
   - Your project's `src/` or `lib/` folder

#### **Step 2: Use System Instructions**

Set Custom Instructions for the project:

```
You are a Senior Mobile Architect reviewing Kotlin/Android and Flutter code.

Always apply these guards:
1. mobile-architecture-guard — Validate layer separation, DI, modules, state management
2. mobile-tdd-guard — Enforce red-green-refactor, proper mocking, visual testing

When asked to review code:
- List specific imperative violations (e.g., "Imperative #4: Direct Repository Creation in ViewModel")
- Suggest fixes with code diffs (not full files)
- Cite the relevant reference guide (clean-architecture.md, dependency-injection.md, etc.)

Output format:
- [Imperative #N] Violation: [issue]
- File: [path:line]
- Fix: [suggested code diff]
- Reference: [skill.md section]
```

#### **Step 3: Enable Prompt Caching**

Claude Desktop automatically caches:
- **5K+ character documents** (your skill files)
- **Reference guides** (re-used across multiple reviews)
- **System instructions** (project context)

**Benefit**: Review 5+ features, pay token cost only once for skill definitions.

Example token savings:
```
Without caching:
- 3 architecture reviews × 2K tokens each = 6,000 tokens

With caching (Prompt Caching enabled):
- First review: 2,000 tokens (skills loaded)
- Reviews 2-5: 200 tokens each (cached, 90% savings!)
- Total: 2,800 tokens (vs 6,000)
```

---

## 📋 Architectural Guardrails (Quick Reference)

### **mobile-architecture-guard: 20 Imperatives**

**Layer Separation** (1-3)
- Three clear layers: Presentation, Domain, Data
- No upward dependencies (Domain never imports Data/Presentation impl)
- Data layer is plumbing, not business logic

**Dependency Injection** (4-6)
- Inject everything that changes
- Constructor injection only; max 4 args
- Abstractions live with the client

**Module Structure** (7-9)
- Feature-based modules, not layer-based
- No cross-feature direct imports
- No circular dependencies

**State Management** (10-12)
- ViewModel owns state; UI consumes it
- No state duplication / prop drilling
- Side effects explicit, not hidden in init

**Repositories & Testing** (13-20)
- Repository is orchestrator, not business logic
- Domain testable without framework
- SOLID principles: SRP, OCP, LSP, ISP, DIP

---

### **mobile-tdd-guard: 20 Imperatives**

**Test-First Discipline** (1-4)
- Write failing test before code
- Test behavior, not implementation
- One thing per test
- Test names describe scenario & outcome

**Mocking & Test Doubles** (5-8)
- Mock external dependencies (repos, APIs)
- Mock interface contracts, not impl
- No over-specification in mocks
- No hardcoded success fixtures

**Coverage & Boundaries** (9-11)
- Test happy path + 2 sad paths minimum
- Test boundary conditions (empty, null, zero, max)
- Real behavior matches mock contract

**Refactoring & Flutter/Kotlin** (12-20)
- Refactor only after test passes
- Avoid test code duplication
- Flutter: use pump() and pumpAndSettle() correctly
- Kotlin: handle coroutines with runTest
- All languages: specific assertions, no logging checks

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
