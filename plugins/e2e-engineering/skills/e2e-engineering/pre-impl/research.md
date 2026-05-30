# research — conditional

Fires only when the task leans on external APIs / unfamiliar libs / unknown protocols. grill-with-docs gates it. Skipped cleanly when not needed. Produces `research.md` at the **Task root** (`.e2e-engineering/tasks/<id>/` multi-Task, `.e2e-engineering/` single-Task legacy — SKILL.md Step 1; written there directly, never base-then-copy): sprint-lifetime cache, MAY ROT — flag it stale-able.

## What to do
- Investigate the specific external surface the task depends on: API contracts, lib capabilities/limits, auth, rate limits, version constraints, gotchas.
- Use WebSearch/WebFetch for current docs; verify against the installed version, not memory.
- Capture concrete findings the PRD and slices will rely on — endpoints, payload shapes, error modes, code-level examples.

## Output `research.md`
```markdown
# Research — <topic>  (sprint-lifetime, may rot — verify before reuse)

## Question
<what we needed to learn and why>

## Findings
<concrete, version-pinned facts>

## Implications for the build
<decisions this forces / options it opens>

## Open / unverified
<anything still uncertain>
```

## Red flags (stop)
- Researching things the task does not depend on (scope creep).
- Treating research.md as durable truth — it rots; re-verify before a later task reuses it.
- Recording library behavior from memory without checking the actual installed version.
