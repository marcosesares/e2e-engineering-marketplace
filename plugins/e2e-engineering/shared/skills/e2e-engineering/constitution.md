# Constitution — v1

Standing contract for how code and tests are written. Injected into every implementation sub-agent so all parallel slices share identical rails. Distinct from CONTEXT.md (glossary), ADRs (point-in-time decisions), ARCHITECTURE.md (project-specific structure + conventions). Versioned: bump version line + append changelog when amendments promoted at human-QA gate.

**Boundary vs ARCHITECTURE.md:** holds GENERIC, cross-project engineering standards (test-first, real-interface tests, simplicity). Project-specific rules — which class owns URL path, file naming patterns, integration conventions — live in ARCHITECTURE.md, not here. Generic learning → promote here; project-specific structure → promote to ARCHITECTURE.md (human routes at QA gate).

## Coding principles (karpathy)

### 1. Think before coding
- Assumptions unclear → ASK. Do not guess.
- Request has multiple interpretations → present all, wait for user to pick.
- Simpler approach exists → say so and push back before building.
- Trivial tasks (typo, one-liner) → skip full rigor, apply judgment.

### 2. Simplicity first (new code)
- Write fewest lines satisfying goal.
- Senior engineer calls it overcomplicated → simplify until they wouldn't.
- No speculative abstraction, no features beyond requirement, no design for hypothetical futures. Three similar lines beat premature abstraction.

### 3. Surgical changes (editing existing code)
- Only touch lines tracing directly to request.
- Match existing style of file.
- Remove orphans YOUR OWN change created (unused imports/vars). Do NOT touch pre-existing dead code.
- No "while I'm here" cleanup — separate task.

### 4. Goal-driven execution
- Transform task into verifiable goal before starting.
- Multi-step: state plan as `step → verification check`, verify each before next.
- Single-step: define one success criterion.
- Done = every verification passed, not "code written".

## Testing principles (qa — BR-PL-01..06)

1. **Real-interface interaction** — tests drive system as user/client does (UI clicks, real HTTP), not by poking private properties or internal state.
2. **Diagnosable failures** — failing test must say what broke. No silent `catch` swallowing signal. Assert on observable behavior.
3. **No hardcoded sleeps** — wait on condition (element visible, response received), never `sleep(n)` when wait condition exists.
4. **Scope discipline** — test (and fix) stays inside story scope. No "while I'm here" fixes — surface as refactor candidates.
5. **Readability over defensive coding** — test is spec a human reads; keep it linear and obvious, not robust-but-opaque.
6. **Behavior, not implementation** — assert outcomes stakeholder cares about, so test survives refactor that preserves behavior.

7. **BR-PLAYWRIGHT-01: scope — API/integration only, no UI automation (Fork Y, ADR 0024)** — Playwright in this flow drives **API/integration** (`request` fixture), never browser UI. Agents do NOT open the app for UI verification (too costly + brittle); UI is verified by the human-QA Manual walk. No browser navigate/snapshot/screenshot/POM in slice or verification code.
8. **BR-PLAYWRIGHT-02: API/integration test standard** — follow [standards/api-testing.md](standards/api-testing.md) (canonical): `request` fixture, web-first assertions, M1 docker-compose stack, per-test data isolation, traceability. **Project's own API-test conventions (ARCHITECTURE.md §4) override that baseline.**

## How enforced
- Every slice sub-agent receives this file in context.
- Per-slice review (orchestrator) checks sub-agent summary against this constitution before writing `status: done`.
- Post-impl review audits full diff against it.
- Refactor candidates surfaced mid-slice WALLED (scope discipline) — routed to triage, never actioned in-slice.

## Changelog
- v1 — initial. karpathy coding guidelines + qa BR-PL-01..06.
- v1.1 — Fork Y (ADR 0024): BR-PLAYWRIGHT-01 rescoped (API/integration only, no UI automation); added BR-PLAYWRIGHT-02 (API test standards).
