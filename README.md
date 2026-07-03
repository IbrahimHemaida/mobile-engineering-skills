# 📱 Mobile Engineering Skills

> **Battle-tested, token-optimized AI System Instructions/Guardrails for Senior Mobile Team Leads & Engineers**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platforms: Android | Flutter | KMM](https://img.shields.io/badge/Platforms-Android%20%7C%20Flutter%20%7C%20KMM-brightgreen)](https://github.com/IbrahimHemaida/mobile-engineering-skills)

## The Problem

AI coding assistants (Claude Code, Cursor, Copilot) are fast — and left unguided, that speed is exactly what breaks a mobile codebase. Given a loose prompt, an AI tool will happily:
- Flatten Clean Architecture into one god-file because it's faster than writing three
- Pass a raw `@Serializable`/`@Entity` model straight to the UI instead of writing a mapper
- Fix one file and silently break three others that depended on the old contract
- Re-read your entire project history every session, burning tokens and losing track of decisions you already made
- Ship code that "looks right" but was never actually compiled against your real build

None of this shows up in the diff. It shows up three sprints later as a production bug or a codebase nobody wants to touch.

## The Solution

Six AI skill packages — plain-language system instructions that Claude Code and Cursor read automatically — that act as a strict senior reviewer sitting between the AI and your merge button. They don't write your code faster; they stop the AI from writing the wrong code confidently. Each skill is scoped, testable, and enforces one concern: architecture, testing, security, accessibility, KMM migration safety, or AI context/token discipline.

## How to Use

```bash
curl -fsSL https://raw.githubusercontent.com/IbrahimHemaida/mobile-engineering-skills/main/install.sh | bash
```

That's it for Claude Code — skills are auto-discovered from `~/.claude/skills/` with no restart needed. See [Installation](#-installation) below for Cursor, Claude.ai/Claude Desktop, and project-scoped (`--project`) setup.

---

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
| ⚡ **Lower Token Overhead** | Diffs-only output, imperative references instead of full re-explanations, and session digests instead of full history replays |
| 🎯 **Standardize Elite Patterns** | Team consistency: SOLID, Clean Architecture, Unidirectional Data Flow |
| 🔍 **Catch Issues Early** | AI invokes skills before code review — saves 30+ minutes per PR |

> **Note**: A few sections below reference `clean-code-guard` and `test-guard` as complementary skills (general-purpose code quality and test quality review, not mobile-specific). These are **optional companion skills and are not included in this repository** — the six skills below are fully self-contained and don't require them. If you use them elsewhere in your own setup, they slot in alongside these for a fuller review pipeline.

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

**24 Imperatives** governing architecture decisions with real-world examples, including explicit UI-model leakage prevention (no `@Serializable`/`@Entity` reaching the UI directly), same-diff DI registration, a project-wide "blast radius" search before changing public symbols, and a required local build pass before presenting a final diff.

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

**20 Imperatives** guiding TDD cycles with framework-specific patterns.

---

### **3. ai-context-budget-guard** 🧠

Manage AI context budget across long-running mobile engineering sessions by writing compact session digests instead of re-reading full chat history every time.

**Solves:**
- ✓ AI re-reading entire project history at the start of every session
- ✓ Decisions and rejected approaches getting silently re-litigated
- ✓ Context window exhaustion mid-task from unmanaged session length
- ✓ Bloated "summaries" that are full transcripts in disguise

**How:** one short Session Digest (30–50 lines) per meaningful session, linked from a single Index file. Only the Index is read at session start; digests are opened on demand. Feeds directly into Claude Code's `CLAUDE.md` / auto-memory instead of duplicating it.

**16 Imperatives** covering digest discipline (including mobile-specific DI/module-boundary tracking and exclusion of generated build artifacts), index discipline, compression, native tool integration, and enforced session-start bootstrapping. Includes a `::save-context` quick trigger and a ready-to-use Claude Code `/save-context` slash command.

---

### **4. mobile-security-guard** 🔒

Review Kotlin/Android and Flutter code for security vulnerabilities before merge — exposed secrets, missing certificate pinning, insecure local storage, and unsafe WebView/deep-link/IPC surfaces.

**Validates:**
- ✓ No secrets, API keys, or credentials in tracked source
- ✓ Certificate pinning on auth/sensitive endpoints, with a backup pin
- ✓ Cleartext traffic default-denied; no disabled TLS validation
- ✓ Encrypted local storage for tokens/PII (EncryptedSharedPreferences, flutter_secure_storage)
- ✓ Exported components are intentional, not default-on
- ✓ Deep link and intent inputs validated as untrusted, with server-side authorization
- ✓ WebView JS bridges scoped to trusted origins
- ✓ Debug bypasses and verbose logging stripped from release builds
- ✗ **Bans** disabled TrustManager/hostname verification "fixes"

**21 Imperatives**, plus a severity-ranked findings report format (Critical/High/Medium/Low) for security reviews. Includes `@Keep`/reflection-safety guidance for serialization and crypto models under R8/ProGuard.

---

### **5. mobile-accessibility-guard** ♿

Review Kotlin/Android and Flutter code for WCAG 2.1 AA accessibility violations before merge — missing content descriptions/semantics, undersized touch targets, insufficient color contrast, and broken screen reader flow.

**Validates:**
- ✓ Content descriptions/semantics on all meaningful non-text elements
- ✓ Touch targets ≥48dp/44pt-equivalent
- ✓ Color contrast: 4.5:1 text, 3:1 large text/UI components — checked against rendered colors
- ✓ No status/validation information relies on color alone
- ✓ Screen reader reading order matches visual order
- ✓ Form fields have programmatically associated labels
- ✓ Dynamic content changes and validation errors are announced, not just displayed
- ✓ Custom tappable widgets expose correct semantic role (button, header, etc.)
- ✗ **Bans** treating accessibility as a pre-release-only QA pass

**20 Imperatives**, plus a severity-ranked findings report format referencing specific WCAG success criteria.

---

### **6. mobile-kmm-migration-guard** 🔀

Review Kotlin Multiplatform Mobile (KMM) code for platform leakage, unsafe `expect`/`actual` usage, JVM-only dependencies in shared code, and iOS interop hazards.

**Validates:**
- ✓ No `android.*`/`androidx.*` or Foundation/UIKit imports in `commonMain`
- ✓ `expect`/`actual` used only for genuine platform divergence
- ✓ `kotlinx-datetime`, `kotlinx.serialization`, and Ktor client instead of `java.time`, `Serializable`/Gson, and OkHttp/Retrofit directly in shared code
- ✓ SQLDelight (or an explicit abstraction) instead of Room in shared persistence
- ✓ No blocking calls on `Dispatchers.Main` (punished harder on iOS than Android)
- ✓ Exceptions crossing into Swift are caught and converted, not left uncaught
- ✓ Migration sequenced pure-logic-first, not attempted as a big-bang rewrite
- ✗ **Bans** business logic duplicated across `actual` implementations

**21 Imperatives**, plus a migration readiness report format for assessing whether a module is ready to move to shared code. Includes explicit `Flow`/`StateFlow`-to-Swift interop guidance (SKIE or equivalent) and a named Multiplatform Settings replacement for platform key-value storage.

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

These skills integrate into your review workflow to:

#### 3. **Catch Issues Early**
- AI invokes skill before sharing code
- Saves human reviewers 30+ minutes per PR

#### 4. **TDD-First Development**
- Guardrail guides red-green-refactor cycle
- Visual regression testing automated (golden files)

---

## 🚀 Installation

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/IbrahimHemaida/mobile-engineering-skills/main/install.sh | bash
```

Installs all six skills to `~/.claude/skills/` (available across every project). For a project-scoped install instead (shared with your team via git, this project only):

```bash
curl -fsSL https://raw.githubusercontent.com/IbrahimHemaida/mobile-engineering-skills/main/install.sh | bash -s -- --project
```

### Manual

```bash
git clone https://github.com/IbrahimHemaida/mobile-engineering-skills.git
mkdir -p ~/.claude/skills
cp -r mobile-engineering-skills/skills/* ~/.claude/skills/
```

Both methods copy all six skills to your user-level Claude Code skills directory (`~/.claude/skills/`), where they're available across every project. To scope skills to a single project, copy them into `.claude/skills/` inside that project's repo, or use `--project` with the one-liner above.

---

## 📋 Implementation Guides

### **Claude Code**

Claude Code auto-discovers skills placed under `.claude/skills/<skill-name>/SKILL.md` (project-level, shared with your team via git) or `~/.claude/skills/<skill-name>/SKILL.md` (user-level, available across all your projects). No separate config file is needed — Claude reads each skill's `description` field and applies it automatically when it's relevant to what you're doing.

```bash
mkdir -p ~/.claude/skills
cp -r skills/mobile-architecture-guard skills/mobile-tdd-guard skills/mobile-security-guard skills/mobile-accessibility-guard skills/mobile-kmm-migration-guard skills/ai-context-budget-guard ~/.claude/skills/
```

You can also invoke a skill directly instead of waiting for automatic matching:

```bash
/mobile-architecture-guard Review this feature for layer violations
/mobile-tdd-guard TDD the payment retry logic
/mobile-security-guard Audit this auth flow for security issues
/mobile-accessibility-guard Check this screen for WCAG AA issues
/mobile-kmm-migration-guard Review this commonMain code for platform leakage
/ai-context-budget-guard Write a session digest before we wrap up
```

---

### **Cursor IDE**

This repo ships ready-to-use rule files in `.cursor/rules/` — one `.mdc` file per skill, each a thin pointer to the corresponding `skills/*/SKILL.md` rather than a duplicated copy, so the ruleset can't drift between the Claude Code and Cursor versions.

```bash
git clone https://github.com/IbrahimHemaida/mobile-engineering-skills.git
cp -r mobile-engineering-skills/.cursor path/to/your-project/
```

Five of the six rules use `alwaysApply: false` with a `description` and `globs` — Cursor loads them automatically when you're working in a matching file (`.kt`, `.dart`, `commonMain/**`, etc.) or when the task description matches. `ai-context-budget-guard.mdc` is the one exception, set to `alwaysApply: true`, since its value depends on being loaded every session rather than only when a specific file type is open.

Commit `.cursor/rules/` to your project's git repo so the whole team shares the same rules.

---

### **Claude.ai / Claude Desktop**

1. Go to **Settings → Capabilities** and enable **Code execution and file creation** (required for Skills; Team/Enterprise users enable it under Organization settings instead).
2. Go to **Customize → Skills** and upload each skill folder as a zip — one skill per zip (`mobile-architecture-guard`, `mobile-tdd-guard`, `mobile-security-guard`, `mobile-accessibility-guard`, `mobile-kmm-migration-guard`, `ai-context-budget-guard`).
3. Claude applies a skill automatically when it's relevant to your request — you don't need to reference it by name every time.

Skill availability depends on your plan (Free/Pro/Max/Team/Enterprise); see [Anthropic's Skills documentation](https://support.claude.com/en/articles/12512180-use-skills-in-claude) for current details.

Regardless of which surface you use, keeping prompts to diffs and specific imperative references (e.g. "fix per imperative #4") instead of pasting full files or full skill content each turn is what actually reduces token overhead — the skills are written with that in mind (see `Output format` sections in each SKILL.md).

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
