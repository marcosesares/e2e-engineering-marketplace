# review — post-impl fresh-context full-diff audit

Fresh-context, full-diff, cross-slice audit by clean reviewer with NO impl-loop baggage. Targets what per-slice review structurally can't see: cross-slice architecture, seams, whole-feature spec/standards compliance.

## What to do
- Start clean: review FULL diff of task against baseBranch, not story-by-story.
- Audit against PRD (does whole feature meet intent?) and [constitution](../constitution.md) (coding + testing principles).
- Look for cross-slice issues invisible to per-slice review: inconsistent abstractions across slices, duplicated logic between stories, seam leaks, architectural drift, integration gaps E2E didn't catch.
- Rank findings by severity (blocker / major / minor). Be specific: `path:line — problem — fix`.

## Distinction
- **Per-slice review** = orchestrator, in-loop, summary vs spec+constitution, cheap, catches slice-level drift early.
- **This** = fresh context, whole diff, cross-slice arch. Different lens — run both.

## Outcome
- Blockers/majors → back into implementation loop (new slice or fix) before human-QA.
- Clean → proceed to [human-qa](./human-qa.md).

## Red flags (stop)
- Reviewing slice-by-slice (reproduces per-slice review, misses cross-slice issues).
- Carrying impl-loop assumptions in (point is fresh eyes).
- Praise/scope-creep instead of severity-tagged findings.
