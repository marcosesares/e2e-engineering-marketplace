# e2e-loop — FINAL regression pass (gate 4)

> **GATE 4 STUBBED — pending E2E automation (ADR 0022, not deleted).** Right now flight only AUTHORS the regression test-case docs (steps + validations + automation backlog); steps 2–3 below (automate + run suite) are a `TODO` placeholder. This doc is the spec for when automation lands. Interim verification = expert review + lint/compile + self-review + human-QA checklist.

Runs ONCE after the slice loop reaches COMPLETE (all stories `done`). Automates the REGRESSION (cross-slice) test-cases — the app-wide journeys that span multiple stories — because only now does the whole feature exist for such a journey to be written. Then runs the full accumulated suite. Provenance: ADR 0010 + playwright_project reference.

## What to do
1. Take the **regression**-shape test-cases authored upfront by to-issues.
2. Automate each as an executable E2E in the project stack (Playwright when web UI). These cross slices the per-slice feature E2Es could not.
3. Run the FULL accumulated suite: feature E2Es (from slices) + new regression E2Es + unit/integration tests.
4. Map each new E2E back to its test-case id (traceability).

## HARD GATE 4 — E2E suite green → post-implementation
The full suite must pass before leaving Implementation. A failure here re-opens the loop:
- Failure traces to a specific story → re-dispatch that slice.
- Failure is cross-slice (integration gap) → new slice or systematic-debugging.
Do not proceed to post-impl on a red or skipped suite.

## Disposition
A test-case with an E2E = **Automated**. One left without = **Manual** → it becomes part of the post-impl human-QA script. Record dispositions.

## Red flags (stop)
- Automating regression journeys before the feature is COMPLETE (the journey doesn't exist yet).
- Skipping/ignoring a red test to "move on" (gate 4 is hard).
- Hardcoded sleeps instead of wait conditions (testing principle 3).
