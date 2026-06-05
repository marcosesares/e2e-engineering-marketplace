# verification — verify-before-completion (HARD GATE 5)

> **RESCOPED — ADR 0024 (Fork Y).** = full automated suite (unit + API) green **+** AC-checklist against CODE. **No live-UI exercise** — `/run` + `/verify` removed (agent live-UI verification too costly; UI is verified by the human-QA Manual walk post-impl). Executed inside self-review. Hard, agent-enforced, non-overridable.

Final Implementation-phase check, after the DAG drains. Blocks `done` (→ `pending-qa`) on a red suite or an unmet AC.

## What to do
1. **Full suite re-run** — ALL automated tests (unit Vitest + API/integration Playwright `request`), not just changed slices. Confirm green from clean state. Red → re-open loop (trace failure to story → re-dispatch slice; cross-slice gap → new slice / systematic-debugging).
2. **AC-checklist against code** — walk every story's `acceptanceCriteria[]`; for each confirm an implementing code path AND a covering automated test (unit/API) OR a Manual test-case (UI) exists. No mapping = not done.
3. Record into `verification-result.json` ([schema](../schemas/verification-result.json.md)); `method` = `automated` (suite) | `manual` (UI → human-QA) | `self-review` (code read).

## HARD GATE 5
Suite green AND every AC mapped = implementation done → hand to post-implementation (`pending-qa`). UI ACs are mapped to Manual test-cases (proven later in human-QA), NOT exercised here.

## Red flags (stop)
- Opening the app / `/run` / `/verify` for UI checks (removed — Fork Y; UI is human-QA's job).
- Marking done on a red or partial suite.
- AC with no implementing code path and no covering test (automated or Manual).
- Re-running only changed slices instead of the full suite.
- Claiming a UI AC "verified" by reading code beyond "a handler/route exists" (behavioral UI proof = human walk).
