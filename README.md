# 📱 Mobile Engineering Skills

> **Battle-tested, token-optimized AI System Instructions/Guardrails for Senior Mobile Team Leads & Engineers**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platforms: Android | Flutter | KMM](https://img.shields.io/badge/Platforms-Android%20%7C%20Flutter%20%7C%20KMM-brightgreen)](https://github.com/IbrahimHemaida/mobile-engineering-skills)

Professional AI system instructions designed to enforce SOLID principles, Clean Architecture, and Test-Driven Development across Kotlin/Android and Flutter mobile applications. Built for **real engineering**, not vibe coding.

Engineered for **13+ years** of production mobile development experience. Based on battle-tested patterns from hundreds of shipped features across healthcare, fintech, e-commerce, and enterprise mobile platforms.

---

## 🎯 What This Repository Contains

This is a **skill package** containing expertly-crafted AI system instructions that **automate architecture reviews** and **enforce TDD discipline** across your mobile development workflow. Instead of manually reviewing every PR against the same architectural rules, these guardrails let AI-assisted coding tools catch violations in seconds.

### ✨ Core Benefits

| Benefit | Description |
|---------|-------------|
| 🏗️ **Automate Architecture Reviews** | Catch layer leakage, circular dependencies, DI violations before code review |
| 🧪 **Enforce TDD Red-Green-Refactor** | Guide AI through test-first development with structured discipline |
| ⚡ **Token Optimization (40-60% savings)** | Use Prompt Caching + diffs-only output to cut token consumption dramatically |
| 🎯 **Standardize Elite Patterns** | Team consistency: SOLID, Clean Architecture, Unidirectional Data Flow |
| 🔍 **Catch Issues Early** | AI invokes skills before code review — saves 30+ minutes per PR |

---

## 📚 What's Included

### **1. mobile-architecture-guard** 🏗️

Review Kotlin/Android and Flutter code for SOLID principles, Clean Architecture, modular design, and architectural anti-patterns before merge.

**Validates:**
- ✓ Layer separation (Presentation → Domain → Data, no upward dependencies)
- ✓ Dependency Injection (constructor injection, no hardcoded dependencies)
- ✓ Feature-based modules (no circular imports or cross-feature leakage)
- ✓ Repository & Data Source patterns (single-responsibility orchestrators)
- ✓ State Management (Unidirectional Data Flow, immutable state DOWN, events UP)
- ✓ Testing boundaries (domain testable without framework)
- ✓ SOLID principles (SRP, OCP, LSP, ISP, DIP)
- ✗ **Bans ViewModel Decorator anti-pattern** (breaks OS lifecycle)

**22 Imperatives** governing architecture decisions with real-world examples.

---

### **2. mobile-tdd-guard** 🧪

Test-driven development workflow for Kotlin/Android and Flutter: red-green-refactor cycle with proper mocking, boundary testing, and visual regression testing.

**Enforces:**
- ✓ Red-Green-Refactor discipline (test first, minimal code, refactor)
- ✓ Unit vs. integration testing boundaries
- ✓ Mock contracts, not implementations (Mockito, MockK, mockito-dart)
- ✓ Test naming clarity (scenario + outcome, not method name)
- ✓ Boundary condition testing (empty, null, zero, max, edge cases)
- ✓ Flutter Widget & Golden Testing (visual regression prevention)
- ✓ Kotlin coroutine testing (runTest, suspend function mocking)
- ✓ Stub class pattern (for compiled languages like Kotlin/Java)

**21 Imperatives** guiding TDD cycles with framework-specific patterns.

---

## 💎 Why Use This?

### **Problem: Without These Guardrails**

You're using an AI-assisted coding tool. Code compiles, tests pass locally—but when reviewed:

```
❌ ViewModels call repositories directly (layer violation)
❌ State duplicated across composables (prop drilling, memory leaks)
❌ Tests mock implementation details, break on refactor (brittle)
❌ Database logic mixed with business logic (untestable)
❌ Hard dependencies everywhere → untestable code
```

### **Solution: Token-Optimized AI Guardrails**

These skills use **Prompt Caching** and **Diffs-Only Output** to:

#### 1. **Save Tokens (40-60% reduction)**
- Skill definitions cached in system context
- AI outputs only changed lines (diffs), not full files
- 53% token reduction: 6,000 → 2,800 tokens

#### 2. **Standardize Architecture**
- Architecture rules become testable (22 imperatives)
- Every developer reviews with same standards
- Faster team onboarding

#### 3. **Catch Issues Early**
- AI invokes skill before sharing code
- Saves human reviewers 30+ minutes per PR

#### 4. **TDD-First Development**
- Guardrail guides red-green-refactor cycle
- Visual regression testing automated (golden files)

---

## 🚀 Installation

### **Option A: npm/npx** (Easiest)

```bash
npx skills@latest add IbrahimHemaida/mobile-engineering-skills
```

### **Option B: Manual Setup**

```bash
git clone https://github.com/IbrahimHemaida/mobile-engineering-skills.git
cp -r skills/mobile-* ~/.claude/skills/
```

---

## 📋 Implementation Guides

### **Claude Code CLI**

Create `~/.clauderc`:

```yaml
skills:
  - name: mobile-architecture-guard
    path: ~/.claude/skills/mobile-architecture-guard/SKILL.md
  - name: mobile-tdd-guard
    path: ~/.claude/skills/mobile-tdd-guard/SKILL.md

prompt_caching:
  enabled: true
```

Invoke in terminal:

```bash
@mobile-architecture-guard Review this feature for layer violations
@mobile-tdd-guard TDD the payment retry logic
```

---

### **Cursor IDE**

Create `.cursor/rules/mobile-guards.md`:

```markdown
# Mobile Engineering Guards

## Architecture
- Validate layer separation
- Check dependency injection patterns
- Ensure feature-based modules
- Detect circular dependencies

## Testing
- Write failing test first (RED)
- Implement minimal code (GREEN)
- Refactor for clarity (REFACTOR)
```

Invoke with `@` mentions:

```
@mobile-architecture-guard Review this LoginFeature
@mobile-tdd-guard Build payment processing with TDD
```

---

### **Claude Desktop (Prompt Caching)**

1. Create new Project: "Mobile Engineering"
2. Add files:
   - `skills/mobile-architecture-guard/SKILL.md`
   - `skills/mobile-tdd-guard/SKILL.md`
   - Your project code

3. Set Custom Instructions:

```
You are a Senior Mobile Architect reviewing mobile code.
Apply mobile-architecture-guard (22 imperatives) and mobile-tdd-guard (21 imperatives).
Output diffs-only, reference specific imperatives.
```

**Token savings**: 6,000 → 2,800 tokens (53% reduction)

---

## 📖 Guardrails Summary

### **mobile-architecture-guard: 22 Imperatives**

| Category | Details |
|----------|---------|
| **Layer Separation** (1-3) | Three layers, no upward deps, data is plumbing |
| **Dependency Injection** (4-6) | Inject deps, max 4 args, abstractions with client, **BAN ViewModel Wrapper** |
| **Module Structure** (7-9) | Feature-based modules, no cross-feature leakage, no circular deps |
| **State Management** (10-12) | **UDF** (state DOWN, events UP), no prop drilling, side effects explicit |
| **Repositories** (13-14) | Orchestrator-only, data sources as interfaces |
| **Testing Boundaries** (15) | Domain testable without framework |
| **SOLID Principles** (16-20) | SRP, OCP, LSP, ISP, DIP with mobile context |
| **Token Optimization** (21-22) | Diffs-only output, enforce UDF in feedback |

### **mobile-tdd-guard: 21 Imperatives**

| Category | Details |
|----------|---------|
| **Test-First Discipline** (1-4) | Fail first, test behavior, one thing per test, clear names, **stub class pattern** |
| **Mocking & Test Doubles** (5-8) | Mock external deps, mock contracts, no over-spec, no hardcoded fixtures |
| **Coverage & Boundaries** (9-11) | Happy path + 2 sad paths, boundary conditions, real behavior matches mocks |
| **Refactoring** (12-14) | Refactor after GREEN only, avoid duplication, specific assertions |
| **Flutter Testing** (17-18) | Widget tests (UI logic), **golden testing + pumpAndSettle()** |
| **Kotlin Testing** (19) | Coroutines with runTest |
| **Token Optimization** (20-21) | Diffs-only output, zero fluff |

---

## 🎓 Foundations

Based on proven principles:
- **Clean Architecture** — Robert C. Martin, 2012
- **SOLID Principles** — Robert C. Martin
- **Test-Driven Development: By Example** — Kent Beck, 2002
- **Growing Object-Oriented Software, Guided by Tests** — Freeman & Pryce, 2009
- **Domain-Driven Design** — Eric Evans, 2003
- **A Philosophy of Software Design** — John Ousterhout, 2018
- **The Pragmatic Programmer** — Hunt & Thomas, 2019

Plus 13+ years of production mobile engineering experience.

---

## 📝 License

MIT License. See [LICENSE](LICENSE) for details.

---

## 🤝 Contributing

1. Fork the repository
2. Create a branch (`git checkout -b feature/my-pattern`)
3. Commit changes (`git commit -am 'Add new pattern'`)
4. Push to branch (`git push origin feature/my-pattern`)
5. Open a Pull Request

---

## 💬 Questions?

- Open an issue on [GitHub](https://github.com/IbrahimHemaida/mobile-engineering-skills/issues)
- Check the detailed reference guides in each skill folder
- Review examples for your platform (Kotlin/Flutter)

---

<div align="center">

**Built by [Ibrahim Hemaida](https://github.com/IbrahimHemaida)**

Based on 13+ years of mobile engineering excellence.

*For real engineers, not vibe coding.*

[![Made with ❤️](https://img.shields.io/badge/Made%20with-%E2%9D%A4%EF%B8%8F-red)](https://github.com/IbrahimHemaida/mobile-engineering-skills)

</div>
