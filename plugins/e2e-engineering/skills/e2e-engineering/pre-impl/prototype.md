# prototype — conditional

Fires when taste/UX or state-machine uncertainty needs concrete feedback. grill-with-docs gates it AND picks the branch. THROWAWAY experiment — NOT the final implementation. Provenance: mattpocock ui/logic split (different feedback loops).

## Branch: ui
For visual / UX / interaction uncertainty.
- Build quick visual variants. Cheap, disposable.
- Feedback loop: browser-driven — render and look (Playwright MCP / screenshots). Show the user variants, let them react.
- Goal: resolve taste/layout/flow questions before committing to a PRD.

## Branch: logic
For state-machine / algorithm / terminal-app uncertainty.
- Build a minimal spike of the core logic or state machine.
- Feedback loop: textual — run it, print states/transitions, inspect output.
- Goal: prove the model behaves before committing to a PRD.

## Rules
- Throwaway. Do NOT carry prototype code into implementation. Its output is *understanding*, not artifacts.
- Feed conclusions back into grill-with-docs notes / to-prd.

## Red flags (stop)
- Polishing the prototype as if it were production.
- Letting prototype code leak into the real implementation (it skipped TDD + constitution).
- Prototyping when the uncertainty is not taste/UX/state-machine (use research instead).
