# Schema — codebase-map.md

Produced by `map-codebase` on brownfield tasks only. SCOPED to *this* change — not global reverse-engineering. Sprint-lifetime, may rot. NOT C4/ERD/NxN matrices. Lives at **Task root**: `.e2e-engineering/tasks/<id>/codebase-map.md` multi-Task, `.e2e-engineering/codebase-map.md` single-Task legacy. Written there directly — never base-then-copy.

## Template (index + five sections)

```markdown
# Codebase Map — <task description>

## §Index
§1: L<start>–L<end>
§2: L<start>–L<end>
§3: L<start>–L<end>
§4: L<start>–L<end>
§5: L<start>–L<end>

## §1 Blast-radius modules
<modules/files this change touches or ripples into. Scoped, not whole repo.>

## §2 Seams
<where tests attach: adapters, interfaces, injection points, boundaries.>

## §3 Local impact
<concrete list of call sites / consumers affected by this change.>

## §4 Existing language
<terms code already uses for this domain. Fed to grill-with-docs to reconcile against CONTEXT.md glossary.>

## §5 Refactor candidates  [NOT THIS TASK]
<shallow modules, missing seams, duplicated rules surfaced while mapping.>
<WALLED: tagged NOT THIS TASK, routed to NEW issues via triage, human-gated into own refactor Task.>
<EXCLUDED from slice-subagent context. Orchestrator enforces wall.>
```

**§Index rule**: writer fills line numbers AFTER writing all sections. Readers (orchestrator, sub-agents) use `offset/limit` on the Read tool — fetch §1–§3 only via index, skip §4–§5 unless needed.

## Rules
- §4 → grill-with-docs (language reconciliation, pre-impl — map-codebase runs just before it).
- §5 surface-only. Never actioned in this task. Protects scope discipline (constitution testing principle 4). README "de-slop" = refactor Task fed by these candidates.
- Greenfield tasks skip map-codebase entirely; no codebase-map.md created.
- Orchestrator reads §1–§3 ONCE in Step 2 (e2e-flight). No re-read per-slice or per-wave.
