---
name: ai-context-budget-guard
description: Manage AI context budget across long-running mobile engineering sessions by writing compact session digests instead of re-reading full chat history. Use this at the end of a work session, before running /compact, when starting a new session on an existing project, when the user asks to "summarize progress" or "save context", or when a project has accumulated multiple AI coding sessions and context usage is climbing. Works with Claude Code (CLAUDE.md, auto-memory), Cursor rules, and any AI coding tool that re-reads project files at session start. Trigger this whenever token usage, context window limits, or "the AI keeps forgetting/re-reading everything" comes up.
---

# ai-context-budget-guard

You are managing AI context budget across a multi-session mobile engineering project. This skill does not replace your AI tool's built-in memory (CLAUDE.md, auto-memory, /compact) — it disciplines *what* goes into those mechanisms so each session starts focused instead of bloated. A session that ends without a digest forces the next session to either re-read the whole history or lose the thread entirely; this skill prevents both.

## Compatibility

This skill works with:
- **Claude Code**: writes into `CLAUDE.md` / project auto-memory so the native mechanism carries the digest forward — this skill does not duplicate that system, it feeds it.
- **Cursor / other AI IDEs**: writes into `.cursor/rules/` or an equivalent project-context file the tool re-reads at session start.
- **Any AI coding tool**: works as a plain-file convention (`.ai/context/`) even without native memory support.

This skill complements mobile-architecture-guard and mobile-tdd-guard: those two guard *what* the code looks like; this one guards *how much history* the AI has to carry to reason about it correctly.

## Reference files

- `references/templates.md` — copy-paste templates for the Session Digest, the Index file, and a compressed "archived digest" format. Load this when creating the first digest in a new project or when the inline templates below need the full annotated version.

## How to use this skill

**End-of-session mode** (primary): Before ending a work session — or right before the context window fills up — write a Session Digest (see template below) and append one line to the project's Index file.

**New-session mode**: When starting work on a project that already has `.ai/context/INDEX.md`, read the index first (not the individual digests), and only open a specific digest if the current task clearly relates to it.

**Pre-compact mode**: If the AI tool is about to auto-summarize (e.g. Claude Code's `/compact`), write the digest *before* compaction runs, since compaction is lossy and a written digest survives it while a mental summary does not.

## Why this skill exists

Long-running AI-assisted mobile projects fail on context, not just on code:
- **Full re-reads every session**: the AI opens every file and re-derives decisions already made, burning tokens and time before doing any actual work.
- **Lost decisions**: "we already tried X and rejected it" gets re-proposed because nothing recorded the rejection.
- **Context window exhaustion**: long sessions hit the limit mid-task, forcing a lossy auto-summary at the worst possible moment.
- **No link between sessions**: session 5 doesn't know what session 2 decided about the auth module, so it silently contradicts it.
- **Digest bloat**: teams that *do* write summaries often write full transcripts instead of decisions, which defeats the purpose — a 2,000-word "summary" is not a summary.

A short, structured digest plus a one-line index solves all five without inventing a new storage system — it just uses the ones your AI tool already reads.

## Always-applied imperatives

### Digest Discipline

1. **One digest per meaningful session, not per message.** A "meaningful session" produced a decision, shipped a change, or rejected an approach. Don't digest trivial Q&A sessions — that's noise in the index.

2. **Digests record decisions and state, never full content.** No pasted code, no full diffs, no reproduced conversation. Reference file paths and line numbers instead of quoting the file. If a decision needs justification, one sentence, not the reasoning chain that led there.

   **Anti-pattern**:
   ```
   ## Session 4
   We discussed the auth module for a while. First I looked at using Firebase,
   then we considered Auth0, then we went back and forth about token refresh
   strategies, and eventually decided... [400 more words]
   ```

   **Correct**:
   ```
   ## Session 4 — Auth token refresh
   Decision: refresh token in interceptor, not ViewModel (keeps it framework-agnostic).
   Rejected: Firebase Auth SDK (adds 2MB, we don't need social login).
   Files: data/auth/AuthInterceptor.kt, domain/auth/RefreshTokenUseCase.kt
   Next: wire up retry-after-refresh in NetworkModule.
   ```

3. **Target 30–50 lines per digest.** If a digest is pushing past that, the session covered too much — split it, or the digest is including detail that belongs in code comments, not context memory.

4. **Every digest ends with "Next".** One line stating what the next session should pick up. This is the single most-read line in the entire system — write it like a handoff to a colleague, not a diary entry.

### Index Discipline

5. **The Index is the only file read at session start — never all digests.** One line per digest: date, one-line topic, path to the full digest. The AI (or the engineer) decides from that line alone whether to open the full digest.

   ```
   2026-06-14 | Auth token refresh strategy | digests/2026-06-14-auth-refresh.md
   2026-06-18 | Payment retry backoff policy | digests/2026-06-18-payment-retry.md
   2026-06-22 | Rejected: switching to GetIt from Hilt | digests/2026-06-22-di-decision.md
   ```

6. **Never open a digest "just in case."** Only open one whose index line is clearly relevant to the current task. Opening every digest defeats the entire purpose of having an index.

7. **Rejected approaches get their own index line, even if nothing shipped.** A rejection prevents the same dead end from being re-explored two sessions later — the whole point of the system.

### Compression & Archiving

8. **After ~10 digests, compress the oldest into one archive line.** Old digests collapse into a single line in an `ARCHIVE.md`: date range, and only the decisions still relevant to current code. Anything superseded by a later decision gets dropped entirely, not summarized.

9. **A decision superseded by a later one is deleted, not kept "for history."** Git history is the audit trail; the context system is a working memory, not an archive. If session 8 reversed a session 3 decision, session 3's digest line should be edited to say "superseded by 2026-06-20, see that digest" — not left standing as if still true.

10. **Never let the Index itself exceed ~40 lines.** If it does, archive is overdue (rule 8). An index that's too long to scan in one read has stopped doing its job.

### Native Tool Integration

11. **On Claude Code: write the digest's "Next" line and open decisions into `CLAUDE.md` or auto-memory, not just a standalone file.** A digest sitting in `.ai/context/` that nothing auto-loads still requires someone to remember to read it. Feed the parts that should persist into the mechanism the tool already reads at session start.

12. **Don't duplicate what auto-memory already captures.** If the AI tool has its own auto-memory (e.g. Claude Code's), don't hand-write a digest entry for something it already recorded — check `/memory` (or equivalent) first. This skill's job is the *decisions and rejections* layer; let native auto-memory handle preference/style learning it already does well.

13. **Respect the host tool's size limits.** If the memory file has a line cap (e.g. Claude Code's project memory file has a documented ~200-line load limit), don't let digest content push it over — that's what the archive step (rule 8) is for.

## Output format for AI assistants

When writing a digest or index entry:
- Output the digest as a single fenced block, ready to append — not prose describing what the digest should contain.
- No preamble like "Here's a summary of everything we discussed."
- If updating `CLAUDE.md` or auto-memory directly, show only the new lines being added, same diffs-only convention as mobile-architecture-guard and mobile-tdd-guard.

## Self-check before ending a session

1. **Is there a decision, rejection, or shipped change worth recording?** If not, skip the digest — don't manufacture one.
2. **Does the digest avoid pasted code/full diffs?** File paths and line refs only.
3. **Is it under 50 lines?**
4. **Does it end with a clear "Next"?**
5. **Did I add exactly one line to the Index?**
6. **Did I check whether native auto-memory already captured this before hand-writing it?**
7. **Is the Index still under ~40 lines, or is an archive pass due?**
8. **Did I mark any decision this session reversed as superseded in its original digest?**

If you cannot answer yes to all of these, the digest isn't ready.

## When the user pushes back on a rule

- **"I want the full conversation kept, not just decisions."** Keep the raw transcript wherever your tool already stores sessions (Claude Code keeps session files locally) — that's not what the digest is for. The digest is the fast-path summary; the full history still exists underneath it if truly needed.
- **"50 lines isn't enough for a complex session."** Split the session into two digests along a natural seam (e.g. "auth design" and "auth testing") rather than writing one long one.
- **"We don't use Claude Code, we don't have auto-memory."** Fine — rules 11–13 become optional; the plain-file Index + digest convention (rules 1–10) works standalone with any tool.

## Troubleshooting

- If the AI still re-reads everything despite an index existing, check the AI is actually being pointed at the index file — some tools need an explicit `@` reference or an instruction in `CLAUDE.md` telling it to check the index first.
- If digests keep growing past 50 lines, the session is probably covering too many unrelated tasks — that's a signal to split the work, not just the digest.
- If decisions keep getting silently re-litigated, check whether rejections are actually getting their own index line (rule 7) — a decision with no rejection record looks, to the next session, like it was never considered.

## What this skill does not do

- Replace your AI tool's native memory system — it feeds it.
- Store secrets, credentials, or sensitive data in digests (same rules as committing to git — digests are typically version-controlled).
- Guarantee token savings on its own; savings come from the discipline of *not* re-reading full history, which requires the index actually being consulted.
- Manage code-level or architecture-level quality — use mobile-architecture-guard and mobile-tdd-guard for that.
