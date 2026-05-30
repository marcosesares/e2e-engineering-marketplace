# Schema — codebase-map.md

Produced by `map-codebase` on brownfield tasks only. SCOPED to *this* change — not a global reverse-engineering artifact. Sprint-lifetime, may rot (like research.md). NOT C4/ERD/NxN matrices. Lives at the **Task root**: `.e2e-engineering/tasks/<id>/codebase-map.md` multi-Task, `.e2e-engineering/codebase-map.md` single-Task legacy. Written there directly — never base-then-copy.

## Template (exactly five sections)

```markdown
# Codebase Map — <task description>

## 1. Blast-radius modules
<modules/files this change touches or ripples into. Scoped, not the whole repo.>

## 2. Seams
<where tests attach: adapters, interfaces, injection points, boundaries the e2e/feature tests hook into.>

## 3. Local impact
<concrete list of call sites / consumers affected by the change.>

## 4. Existing language
<terms the code already uses for this domain. Fed to grill-with-docs to reconcile against CONTEXT.md glossary.>

## 5. Refactor candidates  [NOT THIS TASK]
<shallow modules, missing seams, duplicated rules surfaced while mapping.>
<WALLED: tagged NOT THIS TASK, routed to NEW issues via triage, human-gated into their own refactor Task.>
<EXCLUDED from slice-subagent context. The orchestrator enforces the wall.>
```

## Rules
- Section 4 → grill-with-docs (language reconciliation, in pre-impl — map-codebase runs just before it).
- Section 5 is surface-only. Never actioned in this task. Protects scope discipline (constitution testing principle 4). README "de-slop" = a refactor Task fed by these candidates, never an AFK whole-repo refactor.
- Greenfield tasks skip map-codebase entirely; no codebase-map.md is created.
