# e2e-loop — FINAL regression pass (gate 4)

> **GATE 4 STUBBED — pending E2E automation (ADR 0022, not deleted).** Flight only AUTHORS regression test-case docs (steps + validations + automation backlog); steps 2–3 below (automate + run suite) = `TODO` placeholder. This doc is spec for when automation lands. Interim verification = expert review + lint/compile + self-review + human-QA checklist.

Runs ONCE after slice loop reaches COMPLETE (all stories `done`). Automates REGRESSION (cross-slice) test-cases — app-wide journeys spanning multiple stories — only now does whole feature exist for such journey. Then runs full accumulated suite.

## What to do
1. Take **regression**-shape test-cases authored upfront by to-issues.
2. Automate each as executable E2E in project stack (Playwright for web UI). These cross slices per-slice feature E2Es could not.
3. Run FULL accumulated suite: feature E2Es (from slices) + new regression E2Es + unit/integration tests.
4. Map each new E2E back to its test-case id (traceability).

## HARD GATE 4 — E2E suite green → post-implementation
Full suite must pass before leaving Implementation. Failure → re-opens loop:
- Failure traces to specific story → re-dispatch that slice.
- Failure is cross-slice (integration gap) → new slice or systematic-debugging.
Do not proceed to post-impl on red or skipped suite.

## Disposition
Test-case with E2E = **Automated**. Left without = **Manual** → part of post-impl human-QA script. Record dispositions.

## Red flags (stop)
- Automating regression journeys before feature COMPLETE (journey doesn't exist yet).
- Skipping/ignoring red test to "move on" (gate 4 is hard).
- Hardcoded sleeps instead of wait conditions (testing principle 3).
