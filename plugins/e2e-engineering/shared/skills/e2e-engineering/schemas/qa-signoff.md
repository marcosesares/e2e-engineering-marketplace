# qa-signoff.md — schema (per-Task human-QA checklist)

Lives at `.e2e-engineering/tasks/<id>/qa-signoff.md`. Written by [/e2e-flight](../../e2e-flight/SKILL.md) when deferring human-QA (ADR 0018). Audit record; `queue.json` holds actionable state. Cleared in [QA sign-off session](../post-impl/human-qa.md) (multi-Task pass).

```markdown
# QA Sign-off: <task-id>
Status: PENDING            # PENDING | APPROVED | REJECTED

## Manual test cases (walk these)
### TC-03: <journey name>
Preconditions: <env/data/login state>
1. <action> → expect <observable result>
2. <action> → expect <observable result>
3. <restore/reset step when needed> → expect <baseline restored>

### TC-07: <journey name>
Preconditions: <env/data/login state>
1. <action> → expect <observable result>

## PRD acceptance criteria (auto-verified — confirm visually)
- [x] AC-1 <criterion>     # flight ticked via /verify
- [ ] AC-4 <criterion>     # needs human eyes (visual / UX)

## Pending amendments (promote / drop)
- constitution: <generic learning from progress.txt>
- ARCHITECTURE.md: <project-specific structure/ownership/naming change>

## Findings (-> triage -> new queue Tasks)
- (filled DURING QA session by human)
  - bug:  <desc>   -> new bugfix Task (parentTask=<this id>); this Task still goes done
  - idea: <desc>   -> new feature Task (status:todo, unselected)

## Decision
- [ ] Approve -> queue status: done
- [ ] Reject  -> reason: ___
```

## Sections: flight fills vs human fills
- **Flight fills** (headless): full Manual test-case scripts (from prd.json testCases disposition Manual, including Preconditions, Steps, Expected), AC list with auto-verified ticked, pending amendments staged from progress.txt.
- **Human fills** (QA session): walks Manual cases, eyeballs visual ACs, decides each amendment, logs Findings, records Decision.

## Manual case rules
- Write full script bodies, not ids/titles only.
- Preserve concrete endpoints, status codes, UI labels, role names, blocked/allowed assertions, and cleanup/restore steps.
- One TC id once. No duplicate cases.

## Why deferred + batched
Human-QA cannot run headless. Flight runs all automatable steps (gates 4, automated half of 5, review), parks human judgment here, sets Task `pending-qa`, continues to next Task. All checklists cleared in one batched session — mirrors pattern-promotion batching (ADR 0014 lineage). See ADR 0018.
