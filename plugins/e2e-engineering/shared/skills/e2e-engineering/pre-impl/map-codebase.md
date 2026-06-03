# map-codebase — brownfield, conditional, runs FIRST

Fires only on brownfield (task targets existing code), gated by `taskType` — NOT by grilling. Skipped for greenfield. Runs FIRST in pre-impl, BEFORE [grill-with-docs](./grill-with-docs.md), so grilling walks in familiar with existing functionality (§4 existing-language + seams feed doc-aware grill). Produces `codebase-map.md` at **Task root** (`.e2e-engineering/tasks/<id>/` multi-Task, `.e2e-engineering/` single-Task legacy — set in SKILL.md Step 1). Write THERE directly, never base then copy. SCOPED to *this* change. Sprint-lifetime, may rot. See ADR 0009. Schema: [codebase-map](../schemas/codebase-map.md).

## What to do

Explore only blast radius of planned change. Fill five sections:

1. **§1 Blast-radius modules** — modules/files this change touches or ripples into. Scoped.
2. **§2 Seams** — where tests attach: adapters, interfaces, injection points, boundaries.
3. **§3 Local impact** — concrete call sites / consumers affected.
4. **§4 Existing language** — terms code already uses for this domain. → feeds grill-with-docs.
5. **§5 Refactor candidates [NOT THIS TASK]** — shallow modules, missing seams, duplicated rules noticed while mapping.

**Write §Index after all sections are written.** Count actual line numbers for each section and fill the `§Index` block at top of file (see schema template). Readers (orchestrator in e2e-flight Step 2, sub-agents) use this index with `offset/limit` to read only §1–§3 without loading §4–§5.

## The wall (enforce)
§5 SURFACE-ONLY and WALLED:
- Tag every candidate `NOT THIS TASK`.
- Route to NEW issues via [triage](../impl/triage.md) → human-gated into own refactor Task.
- EXCLUDE from slice-subagent context. Orchestrator enforces this.
- Never action in this task. Protects scope discipline.

## Reconcile against ARCHITECTURE.md
While mapping, compare code against `ARCHITECTURE.md` (if exists):
- Code matches doc → nothing to do.
- Code reveals convention doc DOESN'T cover, or doc is stale → PROPOSE addition/correction for human review (pre-impl is human-write phase for ARCHITECTURE.md). Seed here so to-issues + fan-out steer slices correctly.
- No ARCHITECTURE.md yet → seed relevant sections from findings, human-reviewed. Write §Index after seeding.
- §4 stays language-only; structure/ownership/naming live in ARCHITECTURE.md.

## Outputs feed
- §4 → [grill-with-docs](./grill-with-docs.md) (very next step).
- §1–§3 → [to-issues](../impl/to-issues.md) (slices respect existing seams).
- ARCHITECTURE.md proposals → human review → durable conventions to-issues/fan-out/quality-check rely on.

## Red flags (stop)
- Global reverse-engineering artifacts (full C4, ERD, spec-impact matrix). Too heavy, rots fast.
- Mapping whole repo instead of change blast radius.
- Actioning refactor candidate in this task.
- Forgetting to write §Index after sections (readers can't use offset/limit without it).
