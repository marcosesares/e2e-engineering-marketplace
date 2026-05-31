# Constitution — v1

Standing contract for how code and tests are written in this project. Injected into every implementation subagent so all parallel slices share identical rails. Distinct from CONTEXT.md (glossary), ADRs (point-in-time decisions), and ARCHITECTURE.md (project-specific structure + conventions). Versioned: bump the version line and append to the changelog when amendments are promoted at the human-QA gate.

**Boundary vs ARCHITECTURE.md:** this doc holds GENERIC, cross-project engineering standards (test-first, real-interface tests, simplicity). Project-specific rules — which class owns a URL path, file naming patterns, integration conventions — live in ARCHITECTURE.md, not here. A learning that's generic promotes here; one that's specific to this project's structure promotes to ARCHITECTURE.md (human routes it at the QA gate).

## Coding principles (karpathy)

### 1. Think before coding
- If assumptions are unclear, ASK — do not guess.
- If the request has multiple interpretations, present them all and wait for the user to pick. Do not silently choose one.
- If a simpler approach exists than what was asked, say so and push back before building.
- Trivial tasks (typo, one-liner) skip full rigor — apply judgment.

### 2. Simplicity first (new code)
- Write the fewest lines that satisfy the goal.
- If a senior engineer would call it overcomplicated, simplify until they wouldn't.
- No speculative abstraction, no features beyond the requirement, no design for hypothetical futures. Three similar lines beat a premature abstraction.

### 3. Surgical changes (editing existing code)
- Only touch lines that trace directly to the request.
- Match the existing style of the file.
- Remove orphans your OWN change created (unused imports/vars). Do NOT touch pre-existing dead code.
- No "while I'm here" cleanup. That is a separate task.

### 4. Goal-driven execution
- Transform the task into a verifiable goal before starting.
- Multi-step: state the plan as `step → verification check` and verify each step before the next.
- Single-step: define one success criterion.
- Done = every verification passed, not "code written".

## Testing principles (qa — BR-PL-01..06)

1. **Real-interface interaction** — tests drive the system the way a user/client does (UI clicks, real HTTP), not by poking private properties or internal state.
2. **Diagnosable failures** — a failing test must say what broke. No silent `catch` that swallows the signal. Assert on observable behavior.
3. **No hardcoded sleeps** — wait on a condition (element visible, response received), never `sleep(n)`, when a wait condition exists.
4. **Scope discipline** — a test (and its fix) stays inside the story's scope. No "while I'm here" fixes — surface them as refactor candidates instead. Mirrors coding principle 3.
5. **Readability over defensive coding** in test code — a test is a spec a human reads; keep it linear and obvious, not robust-but-opaque.
6. **Behavior, not implementation** — assert outcomes a stakeholder cares about, so the test survives a refactor that preserves behavior.

7. **BR-PLAYWRIGHT-01: Playwright token budget** — Live browser verification (navigate + snapshot + screenshot + evaluate) costs ~2–4K tokens per call. A full acceptance-criteria walk runs 15–30 calls = 30–90K tokens — the highest token-growth phase. (Currently a STUBBED gate-5 step pending automation — ADR 0022.) When it lands, run it in its OWN fresh spawn, never appended to a long implementation context. No 65%/handoff checkpoint mechanic (ADR 0022 removed context monitoring).

## How this is enforced
- Every slice subagent receives this file in context.
- Per-slice review (orchestrator) checks the subagent's summary against this constitution before writing `status: done`.
- Post-impl review audits the full diff against it.
- Refactor candidates surfaced mid-slice are WALLED (principle: scope discipline) — routed to triage, never actioned in-slice.

## Changelog
- v1 — initial. karpathy coding guidelines + qa BR-PL-01..06.
