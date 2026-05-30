# map-codebase — brownfield, conditional, runs FIRST

Fires only on brownfield (task targets existing code), gated by `taskType` — NOT by grilling. Skipped for greenfield. Runs FIRST in pre-impl, BEFORE [grill-with-docs](./grill-with-docs.md), so grilling walks in familiar with the existing functionality (its §4 existing-language + seams feed the doc-aware grill). Produces `codebase-map.md` at the **Task root** (`.e2e-engineering/tasks/<id>/` multi-Task, `.e2e-engineering/` single-Task legacy — set in SKILL.md Step 1; map-codebase is the first writer, so the root already exists). Write it THERE directly, never to base then copy. SCOPED to *this* change — NOT a global C4/ERD/NxN matrix. Sprint-lifetime, may rot. See ADR 0009. Schema: [codebase-map](../schemas/codebase-map.md).

## What to do

Explore only the blast radius of the planned change. Fill the five sections:

1. **Blast-radius modules** — modules/files this change touches or ripples into. Scoped.
2. **Seams** — where tests attach: adapters, interfaces, injection points, boundaries.
3. **Local impact** — concrete call sites / consumers affected.
4. **Existing language** — terms the code already uses for this domain. → feeds the next step, grill-with-docs.
5. **Refactor candidates [NOT THIS TASK]** — shallow modules, missing seams, duplicated rules you notice while mapping.

## The wall (enforce)
Section 5 is SURFACE-ONLY and WALLED:
- Tag every candidate `NOT THIS TASK`.
- Route them to NEW issues via [triage](../impl/triage.md) → human-gated into their own refactor Task.
- EXCLUDE them from slice-subagent context. The orchestrator enforces this.
- Never action them in this task. Protects scope discipline (constitution testing principle 4).

## Reconcile against ARCHITECTURE.md
While mapping, compare what the code actually does against `ARCHITECTURE.md` (the durable project structure + conventions, if it exists):
- Code matches the doc → nothing to do.
- Code reveals a convention the doc DOESN'T cover, or the doc is stale → PROPOSE the addition/correction for human review (pre-impl is a human-write phase for ARCHITECTURE.md). Seed it here so to-issues + fan-out steer slices correctly.
- No ARCHITECTURE.md yet (greenfield, or pre-adopt) → seed the relevant sections from what you find, human-reviewed.
Section 4 stays language-only (terms); structure/ownership/naming live in ARCHITECTURE.md, not here.

## Outputs feed
- Section 4 → [grill-with-docs](./grill-with-docs.md) (the very next step — informs questions + language reconciliation).
- Sections 1-3 → [to-issues](../impl/to-issues.md) (slices respect existing seams).
- ARCHITECTURE.md proposals → human review → durable conventions to-issues/fan-out/quality-check rely on.

## Red flags (stop)
- Producing global reverse-engineering artifacts (full C4 context/container/component, ERD, spec-impact matrix). Too heavy, rots fast — forbidden.
- Mapping the whole repo instead of the change's blast radius.
- Actioning a refactor candidate in this task.
