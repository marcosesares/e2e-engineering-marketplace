# prototype — conditional

Fires when taste/UX or state-machine uncertainty needs concrete feedback. grill-with-docs gates it AND picks branch. THROWAWAY experiment — NOT final implementation.

## Branch: ui
For visual / UX / interaction uncertainty.
- Build quick visual variants. Cheap, disposable.
- Feedback loop: browser-driven — render and look (Playwright MCP / screenshots). Show user variants, let them react.
- Goal: resolve taste/layout/flow questions before committing to PRD.

## Branch: logic
For state-machine / algorithm / terminal-app uncertainty.
- Build minimal spike of core logic or state machine.
- Feedback loop: textual — run it, print states/transitions, inspect output.
- Goal: prove model behaves before committing to PRD.

## Rules
- Throwaway. Do NOT carry prototype code into implementation. Output = understanding, not artifacts.
- Feed conclusions back into grill-with-docs notes / to-prd.

## Red flags (stop)
- Polishing prototype as if production.
- Prototype code leaking into real implementation (skipped TDD + constitution).
- Prototyping when uncertainty is not taste/UX/state-machine (use research instead).
