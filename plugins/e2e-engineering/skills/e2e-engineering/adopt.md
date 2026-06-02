# adopt — one-time onboarding of e2e-engineering into in-progress project

Invoked via `/e2e-engineering adopt`. ONE-TIME, separate from per-task flow. Splits onboarding into two halves of very different blast radius: DOCS conform now (under human review), CODE conforms over time (one human-chosen refactor at a time). Code NEVER auto-refactored. See ADR 0011.

## Half 1 — DOCS (auto-DRAFT, human review)
Auto-DRAFT standards scaffolding from existing code + docs, present for human review/edit — do NOT silently commit.
- **CONTEXT.md** — draft glossary from domain language already in code.
- **constitution.md** — draft coding + testing standards reflecting how project already works (seed from karpathy + qa defaults, adjust to observed reality).
- **ARCHITECTURE.md** — draft project structure + conventions from existing code (5 sections: layering, ownership rules, naming, integration patterns, anti-patterns — schema: [architecture](./schemas/architecture.md)). Write §Index line numbers AFTER all five sections written. "Right route" map every future slice sub-agent steers by — wrong draft propagates everywhere, human review mandatory.
- **ADRs** — draft `docs/adr/*` capturing load-bearing decisions already embedded in code.

Present each for human review/edit. Reason: incorrect glossary or constitution gets injected into EVERY future sub-agent, propagating wrong domain language everywhere. Docs conform immediately — but only after review.

## Half 2 — CODE (map → backlog → triage, human picks)
- Run [map-codebase](./pre-impl/map-codebase.md) REPO-WIDE (one time it's not change-scoped) → prioritized refactor backlog.
- Route candidates through [triage](./impl/triage.md) → issues.
- HUMAN picks which become refactor Tasks. Each conforms incrementally through normal gated flow: full PRD → HARD GATE 1 → slices + TDD → mandatory e2e → review → human-QA. Refactor Tasks run FULL flow (ADR 0012).
- Code NEVER automatically rewritten to standards.

## Net
Docs conform now (human-reviewed). Code conforms over time, one human-chosen refactor at a time.

## Red flags (stop)
- Auto-committing drafted standards docs without human review.
- Auto-refactoring whole codebase (maximal blast radius — forbidden).
- Treating adopt as per-task flow (one-time onboarding only).
- Writing ARCHITECTURE.md without §Index.
