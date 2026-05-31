# verification — verify-before-completion (gate 5)

Final Implementation-phase check, AFTER E2E green (gate 4). Distinct from gate 4: gate 4 = automated E2E suite green; gate 5 = full suite re-run + LIVE exercise of the feature + every PRD acceptance criterion ticked. Catches what automated E2E misses — visual/interaction regressions, criteria not encoded as tests. Provenance: superpowers verification-before-completion. Wires existing harness skills — does NOT reimplement app launching.

> **GATE 5 STUBBED — pending E2E automation (ADR 0022, not deleted).** The live `/run`+`/verify` exercise below is a `TODO` placeholder while automation is stubbed + flight is headless. Interim: flight's self-review ticks the PRD acceptance criteria against the code, and the human-QA checklist walks the rest. This doc is the spec for when automation lands. No context monitoring (65% checkpoint removed).

## What to do
1. **Full suite re-run** — ALL tests (not just changed slices). Confirm green from a clean state.
2. **Live exercise** — invoke `/run` (launch the app) + `/verify` (exercise + observe). For web UI, drive the real browser; for CLI/server/lib, use the run/verify skill's per-project pattern. Watch the golden path AND edge cases; watch for regressions in other features.
3. **PRD acceptance-criteria checklist** — walk every story's `acceptanceCriteria[]` and tick each against observed behavior. Untick-able = not done.

## HARD GATE 5 — verification-before-completion
Passing ALL THREE = implementation done → hand to post-implementation. If the UI/feature can't be exercised, SAY SO explicitly — do not claim success on tests alone.

## Red flags (stop)
- Marking done on a green test suite without live exercise (gate 4 ≠ gate 5).
- Claiming a UI works without driving it in a browser.
- An acceptance criterion with no evidence it's met.
- Re-running only changed slices instead of the full suite.
