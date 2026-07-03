# Context Budget Templates

Copy-paste templates for the three file types this skill produces. Keep the
folder convention consistent so both humans and AI tools know where to look:

```
.ai/context/
├── INDEX.md          # one line per digest, read at every session start
├── digests/
│   ├── 2026-06-14-auth-refresh.md
│   └── 2026-06-18-payment-retry.md
└── ARCHIVE.md         # compressed history, only decisions still relevant
```

---

## 1. Session Digest template

Save as `digests/YYYY-MM-DD-short-topic.md`. Target 30–50 lines.

```markdown
# Session: <short topic>
Date: YYYY-MM-DD

## Goal
<one sentence — what this session set out to do>

## Decisions
- <decision 1, one line, with the "why" in a trailing clause if needed>
- <decision 2>

## Rejected
- <approach rejected, one line, with why in 3–6 words>

## Files touched
- path/to/File1.kt
- path/to/File2.dart

## Open questions
- <anything left unresolved, if any>

## Next
<the single most important thing the next session should do first>
```

### Filled example

```markdown
# Session: Auth token refresh
Date: 2026-06-14

## Goal
Decide how to handle access token refresh on 401 responses.

## Decisions
- Refresh happens in an OkHttp Authenticator/Interceptor, not in the ViewModel
  (keeps retry logic framework-agnostic and testable without Android context).
- Refresh token stored via EncryptedSharedPreferences, injected as interface.

## Rejected
- Firebase Auth SDK — adds 2MB, no social login requirement.
- Refreshing token inside each repository method — duplicated retry logic.

## Files touched
- data/auth/AuthInterceptor.kt
- domain/auth/RefreshTokenUseCase.kt
- data/auth/TokenStorage.kt (interface)

## Open questions
- Should refresh failures log out the user immediately or queue a retry?

## Next
Wire up retry-after-refresh behavior in NetworkModule; resolve the open
question above before touching the logout flow.
```

---

## 2. Index template

Save as `INDEX.md`. One line per digest. Never let this exceed ~40 lines —
archive older entries once it does (see template 3).

```markdown
# Context Index

Read this file first. Only open a digest if its line is clearly relevant
to the current task. Do not open every digest "just in case."

| Date | Topic | Digest |
|------|-------|--------|
| 2026-06-14 | Auth token refresh strategy | digests/2026-06-14-auth-refresh.md |
| 2026-06-18 | Payment retry backoff policy | digests/2026-06-18-payment-retry.md |
| 2026-06-22 | Rejected: switching DI from Hilt to GetIt | digests/2026-06-22-di-decision.md |
```

---

## 3. Archive template

Save as `ARCHIVE.md`. Used when the Index passes ~40 lines or a digest
folder passes ~10 entries. Each archived block replaces several digests
with only the decisions still relevant to the current codebase — anything
superseded by a later decision is dropped, not summarized.

```markdown
# Archived Context (pre-2026-06-01)

## Still relevant
- Auth uses interceptor-based refresh, not ViewModel-based (2026-05-02).
- Payments module is feature-modularized under :feature:payments (2026-05-10).

## Superseded (kept for one line only, do not re-litigate)
- Original DI choice was Koin — replaced by Hilt on 2026-05-20, see
  digests/2026-05-20-di-migration.md if the migration reasoning is needed.
```

---

## Notes on integrating with Claude Code

If the project uses Claude Code, don't stop at the plain-file convention
above — feed the "Next" line and any decision meant to persist into
`CLAUDE.md` or project auto-memory so it's loaded automatically at the
start of every session without anyone needing to remember to check
`.ai/context/INDEX.md` manually. The plain-file structure still serves as
the durable, version-controlled source of truth; the native memory file is
the fast path that guarantees it actually gets read.

---

## 4. Bootstrap directive (paste into `CLAUDE.md` or `.cursorrules`)

```markdown
At the start of ANY session, your very first action is to read
`.ai/context/INDEX.md`. Do not read any code files or historical logs
until you have evaluated the index.
```

This is what makes the Index actually get read — without it, an AI tool
defaults to scanning the project from scratch out of habit even when an
index exists.

---

## 5. `/save-context` slash command (Claude Code)

Save as `.claude/commands/save-context.md`:

```markdown
---
description: Write a session digest and update the context index before ending the session
---

Halt active work. Evaluate this session against ai-context-budget-guard's
Digest Discipline and Index Discipline rules, then output:
1. A Session Digest (30-50 lines, decisions/rejections/Scope-DI-if-applicable/files/Next)
2. The single Index line to append

Do not include full diffs or pasted code. If nothing in this session
warrants a digest, say so instead of manufacturing one.
```

Invoke with `/save-context` at the end of a session. For tools without
custom slash command support, use the plain-text trigger `::save-context`
or `::end-session` instead — the SKILL.md's Quick Trigger section covers
this.
