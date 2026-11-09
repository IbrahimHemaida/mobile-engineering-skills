---
name: mobile-tdd-guard
description: Test-driven development workflow for Kotlin/Android and Flutter: red-green-refactor, behavior-focused tests, mocking rules, and a token-lean per-step test scope. Use when implementing a feature, fixing a bug with reproduction, or when asked to TDD, write tests first, or after a test fails.
---

# mobile-tdd-guard

You are building mobile features with test-driven development: write a failing test, write the minimal code that passes it, refactor, repeat. Apply it to domain and data code with unit tests, and to presentation code (ViewModels, BLoCs, GetX controllers, widgets) with widget or integration tests.

## Compatibility

- **Kotlin/Android**: JUnit 4/5, MockK or Mockito, Truth, kotlinx-coroutines-test.
- **Flutter**: flutter_test, mocktail or mockito, bloc_test (BLoC projects only), integration_test, golden tests.
- Complements mobile-architecture-guard (layer boundaries) and clean-code-guard (test code quality).

## Reference files

- `references/kotlin-testing.md`: JUnit/MockK setup, coroutine and Flow testing.
- `references/flutter-testing.md`: flutter_test setup, widget test scaffolding, golden configuration.

Open one only when setting up a suite from scratch or when a pattern needs more than the summary here. If a reference file is missing in this installation, do not stop or report it: this file is sufficient on its own.

## The cycle

1. **Red**: write a test that fails because the behavior does not exist yet. In compiled languages create a stub first (throws `NotImplementedError` or returns a dummy) so the test compiles and fails for the right reason.
2. **Green**: write the minimal code that passes. Ugly is fine.
3. **Refactor**: clean code and test without changing behavior; re-run.
4. Next test case.

Use it for new features, acceptance criteria one by one, and bug fixes (the reproduction test comes first). Do not use it for exploratory spikes, and do not call tests written after the code TDD.

## Test scope per step (token and time discipline)

- **Per red-green cycle**: run only the test file(s) you are working on.
- **Per committed step or batch**: run the affected tests: tests added or changed, tests of the changed source files, and non-visual golden tests of changed widgets. If the change touches shared code (core, theme, routing, localization, a service used by several features), run the full suite for that step.
- **Once before merge or push**: run the full suite with the exact command CI uses (read the CI config; do not guess flags).
- Redirect test and analyzer output to a log file outside the source tree, then read only the tail and the failing test names. Never paste a full test log into the conversation.
- Treat the project's own instructions (CLAUDE.md or equivalent) as the authority on gate frequency and commit criteria; this section is the default when they are silent.

## Always-applied imperatives

### Test-first discipline

1. **Write the failing test before the code.** A test that never failed proves nothing. Watch it fail once.
2. **Test behavior, not implementation.** Good: "invalid email returns a validation error". Bad: "repository.login was called exactly 3 times". Ask: would this test survive an internal refactor that keeps behavior? If not, rewrite it.
3. **One behavior per test.** Several assertions on the same result are fine; assertions on unrelated things are separate tests.
4. **Names state scenario and outcome**: `loginUseCaseThrowsAuthExceptionOnBadPassword`, not `testLogin`.

### Mocking and test doubles

5. **Mock external dependencies at the contract boundary** (repository interface, API client, database), never the class under test. Unit tests never touch network or disk.
6. **Mock the interface, not the implementation.** `every { repo.getUser(id) } returns user`, not a mocked SQL string.
7. **No over-specification.** `times(2)`, `inOrder`, exact argument matching: only when the order or count is the behavior, and say why in the test name.
8. **Default-success helpers, overridden per test.** One helper builds the happy-path double; sad-path tests override it. No copy-pasted mock setup.

### Coverage: what to test

9. **Happy path plus at least two sad paths** for every significant behavior (validation, remote call, caching).
10. **Boundaries**: empty, null, zero, negative, max, off-by-one at range edges, Unicode and emoji in text fields.
11. **The mock must match reality.** After green, run at least one integration or contract test against the real implementation so a lying mock cannot ship.

### Refactoring

12. **Refactor only on green**, never between red and green.
13. **A test that breaks during refactor means either behavior changed (confirm it was intended) or the test was over-specified (fix the test).**
14. **Shared setup lives in `setUp`/`@Before` or a helper**, not in every test body.

### Assertions

15. **Specific assertions with messages.** `assertEquals(expected, actual, "...")`, `expect(actual, equals(expected), reason: ...)`, Truth or matchers; never a bare `assertTrue(a == b)`.
16. **No assertions on logs or incidental side effects** unless they are the behavior under test.

### Flutter

17. **Widget tests assert your UI logic** (state in, rendered result out), not the framework. Pump the widget under test with a fake or mocked state holder (BLoC, GetX controller, Notifier), then `find` the expected output.
18. **`pump()` advances one frame; `pumpAndSettle()` waits for animations and futures.** After a tap that triggers async work, `pumpAndSettle()` before asserting. Golden captures always follow `pumpAndSettle()`; set a fixed surface size and tear it down.
19. **Golden tests are for unintended visual change, not design fidelity.** Keep goldens of real widgets in both light and dark themes; regenerate only when the visual change is intended and reviewed.
20. **State holders are tested as plain Dart.** A GetX controller or BLoC is unit-tested without the widget tree (`Get.testMode = true` for GetX; `bloc_test` for BLoC); the widget test then only checks rendering.

### Kotlin/Android

21. **`runTest`, not `runBlocking`, for suspend code; `coEvery` for suspend mocks; `advanceUntilIdle()` for scheduled work.**
22. **Inject dispatchers** (an `AppDispatchers` interface) instead of hardcoding `Dispatchers.IO`/`Main`; tests pass `UnconfinedTestDispatcher()`.

## Output format

When generating or changing tests, output diffs only: changed or new lines, `-`/`+` prefixed, no full files and no preamble.

## Findings report format (review mode)

```
[SEVERITY] Short title
File: path/to/FileTest.kt:line
Issue: one sentence.
Impact: what this misses or falsely confirms.
Fix: specific remediation (imperative # where relevant).
```

**Critical** = the test cannot fail when behavior is wrong (asserts on its own stub, tests internals). **High** = a missing boundary or error path likely to ship a bug. **Medium** = a lower-risk gap. **Low** = style or duplication.

## Self-check before delivery

1. Did the test fail first, then pass, then survive refactor?
2. Does each name state scenario and outcome?
3. Would an internal refactor keep every test green?
4. Happy path plus two sad paths? Boundaries?
5. Doubles at the contract boundary, no hardcoded success everywhere?
6. Deterministic: no timing, randomness, network, or shared state?
7. Shared setup extracted?
8. Assertions specific, with messages?
9. Only the affected tests ran per step, logs went to a file, and the full CI command ran once before merge?

## When the user pushes back

Rules come from Beck's _TDD by Example_ and Freeman and Pryce's _GOOS_. Slow test: move to integration, mock in unit. Long name: extract a helper. Need to test an internal: the class probably does too much. Complex mocks: too many behaviors in one test. Record exceptions in a test comment.

## What this skill does not do

- Set up frameworks or dependencies.
- Produce coverage reports.
- Replace integration or end-to-end tests.
- Mandate test counts or gate frequency: the project's instructions decide those.
