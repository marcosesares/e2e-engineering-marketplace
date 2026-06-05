# e2e-loop — task-level e2e QA pass (gate 4 RETIRED)

> **GATE 4 RETIRED — ADR 0024 (Fork Y).** UI E2E is NOT automated. No UI Playwright suite, no "E2E green" exit. This pass AUTHORS cross-slice UI regression test-case DOCS (Manual disposition) for the human-QA walk; it runs NO browser automation. Full automated suite (unit + API) green is checked at gate 5 ([verification](./verification.md)), not here.

Runs ONCE after slice loop reaches COMPLETE (all stories `done`). Only now does the whole feature exist for cross-slice journeys.

## What to do
1. Take **regression**-shape (cross-slice) test-cases authored upfront by to-issues; flesh out full Manual scripts now the feature exists: Preconditions, Steps, Expected, restore step.
2. Disposition = **Manual** — these feed the post-impl human-QA walk (`qa-signoff.md`). NO Playwright UI automation (Fork Y).
3. Write into `tasks/<id>/test-cases/` (caveman-ultra). Map each to its test-case id.

## API/integration regression (optional)
A cross-slice **API** journey spanning stories MAY be automated here as a Playwright `request` test (stable, not brittle), same as in-slice API tests. UI journeys never — Manual only.

## Disposition
unit + API/integration → **Automated** (Vitest / Playwright `request`, in-slice gate 2). All UI → **Manual** → human-QA script.

## Red flags (stop)
- Automating any UI journey with Playwright browser/POM (Fork Y — UI is Manual).
- Authoring regression journeys before feature COMPLETE (journey doesn't exist yet).
- Hardcoded sleeps in any API test instead of wait conditions (testing principle 3).
