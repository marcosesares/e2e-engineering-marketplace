# grill-with-docs — pre-impl doc-aware brainstorm (the only grill)

Karpathy-style brainstorm, made DOC-AWARE. The single grilling skill (absorbs the old grill-me). Runs in pre-implementation AFTER map-codebase (brownfield), so every question is informed by what already exists. Stateless, one question at a time, no question cap. Loops until the user approves the direction. Provenance: mattpocock grill-with-docs + grill-me + superpowers brainstorming gate. See ADR 0019 (map-codebase-first + merged grill).

## Read first (so questions are informed)
Before the first question, read what exists — this is what makes grilling doc-aware:
- `CONTEXT.md` (glossary) — the project's canonical terms.
- `ARCHITECTURE.md` (if present) — durable structure/ownership/naming.
- **Brownfield:** `.e2e-engineering/.../codebase-map.md` — blast radius, seams, and §4 existing language. map-codebase ran first precisely so you walk in familiar with the existing functionality. Never ask what the code already answers — read it.
- **Greenfield / fresh repo:** these may be empty or minimal. Grill anyway; seed CONTEXT.md as terms crystallise.

## What to do
Interview the user relentlessly until you reach a shared, concrete understanding. Walk each branch of the design tree, resolving dependencies one at a time. For each question give your recommended answer.

- Ask ONE question at a time. Wait for the answer before the next.
- If a question is answerable by reading the code/docs, read instead of asking.
- Reconcile language AS YOU GO: when the user's term conflicts with the glossary or the code's existing term ("Glossary says X is A, the code calls it B — which?"), surface it immediately and pin ONE canonical term. Update CONTEXT.md inline as terms resolve (glossary only — no implementation detail).
- Stress-test with concrete scenarios. Probe edge cases. Force precision on boundaries.
- Push back: if you see a simpler approach, say so (constitution: think-before-coding).
- Offer an ADR only when a decision is hard-to-reverse AND surprising AND a real trade-off.

## Gate the conditional pre-impl steps
Before exiting, decide and record (in the notes) which conditional steps still fire:
- **research?** — YES if the task leans on external APIs / unfamiliar libs / unknown protocols. Else NO.
- **prototype?** — YES if taste/UX or state-machine uncertainty needs concrete feedback. Pick the branch: **ui** (visual variants) or **logic** (state machine / terminal). Else NO.

(map-codebase is NOT gated here — it already ran before this skill, driven by taskType: brownfield runs it, greenfield skips it.)

## Exit
User approves the direction → hand caveman:ultra brainstorm notes + conflict-free language + the conditional-step decisions to the orchestrator, which sequences research / prototype / to-prd. Because language was reconciled here, Implementation skips straight to to-issues (no second grill).

## Red flags (stop)
- Building anything here — brainstorm only.
- Asking a question the codebase or glossary already answers.
- Skipping the read-first step (questions would be uninformed — the whole point of doc-aware grilling).
- Letting a term conflict survive into to-prd (every slice would inherit the ambiguity).
- Writing implementation detail into CONTEXT.md.
- Moving on while the user is still uncertain about the core direction.
