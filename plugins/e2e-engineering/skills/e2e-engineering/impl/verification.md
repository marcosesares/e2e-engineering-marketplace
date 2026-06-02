# verification — verify-before-completion (gate 5)

Final Implementation-phase check, AFTER E2E green (gate 4). Distinct from gate 4: gate 4 = automated E2E suite green; gate 5 = full suite re-run + LIVE exercise of feature + every PRD acceptance criterion ticked. Catches what automated E2E misses — visual/interaction regressions, criteria not encoded as tests. Wires existing harness skills — does NOT reimplement app launching.

> **GATE 5 STUBBED — pending E2E automation (ADR 0022, not deleted).** Live `/run`+`/verify` exercise below = `TODO` placeholder while automation stubbed + flight headless. Interim: flight's self-review ticks PRD acceptance criteria against code, human-QA checklist walks rest. This doc is spec for when automation lands. No context monitoring (ADR 0022 removed).

## What to do
1. **Full suite re-run** — ALL tests (not just changed slices). Confirm green from clean state.
2. **Live exercise** — invoke `/run` (launch app) + `/verify` (exercise + observe). Web UI → drive real browser; CLI/server/lib → per-project pattern. Watch golden path AND edge cases; watch for regressions in other features.
3. **PRD acceptance-criteria checklist** — walk every story's `acceptanceCriteria[]`, tick each against observed behavior. Untick-able = not done.

## HARD GATE 5 — verification-before-completion
All THREE passing = implementation done → hand to post-implementation. UI/feature can't be exercised → SAY SO explicitly — do not claim success on tests alone.

## Red flags (stop)
- Marking done on green test suite without live exercise (gate 4 ≠ gate 5).
- Claiming UI works without driving it in browser.
- Acceptance criterion with no evidence it's met.
- Re-running only changed slices instead of full suite.
