# Schema — progress.txt

Append-only learnings log for one Task. **caveman:ultra** style. Sole writer = orchestrator, at fan-in. Append-only WITHIN task; reset (overwrite empty) when new task begins. Lives at **Task root**: `.e2e-engineering/tasks/<id>/progress.txt` multi-Task, `.e2e-engineering/progress.txt` single-Task legacy. Written there directly — never base-then-copy.

Holds under parallelism: only orchestrator writes — sub-agents return summaries, never append directly.

## Layout (exactly three sections)

```
## Story Log
<id> | <one-line summary> | <files touched> | <learnings>
<id> | ...

## Pending Amendments
<durable learning staged — NOT yet approved. Generic standard OR project-architecture drift sub-agent proposed mid-loop.>
<cleared in batch at human-QA gate: human routes each → constitution (generic) | ARCHITECTURE.md (project-specific) | drop>

## Blocked
<id> | <why> | <last systematic-debugging 4-phase diagnosis>
```

## Rules
- Each fan-in: append one Story Log line.
- Durable, reusable learning (not story-specific) → also stage under Pending Amendments. Never auto-merge to constitution OR ARCHITECTURE.md. Architecture drift sub-agent proposed → staged here, written to ARCHITECTURE.md only by human at QA gate.
- 3-strike + systematic-debugging failure → append Blocked line, set story `status: blocked` in prd.json.
- Fresh session resuming blocked story reads `## Blocked`: deps changed since? re-dispatch once. Else stalled → escalate human.
- caveman:ultra: drop all articles/filler, fragments, exact technical terms. Machine scratch, not prose.
