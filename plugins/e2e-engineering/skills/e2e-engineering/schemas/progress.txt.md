# Schema — progress.txt

Append-only learnings log for one Task. **caveman:ultra** style (max compression, full technical substance). Sole writer = orchestrator, at fan-in. Append-only WITHIN a task; reset (overwrite empty) when a new task begins. Lives at the **Task root**: `.e2e-engineering/tasks/<id>/progress.txt` multi-Task, `.e2e-engineering/progress.txt` single-Task legacy. Written there directly — never base-then-copy.

Holds under parallelism because only the orchestrator writes it — subagents return summaries, never append directly.

## Layout (exactly three sections)

```
## Story Log
<id> | <one-line summary> | <files touched> | <learnings>
<id> | ...

## Pending Amendments
<durable learning staged — NOT yet approved. Generic standard OR project-architecture drift a subagent proposed mid-loop.>
<cleared in batch at human-QA gate: human routes each → constitution (generic) | ARCHITECTURE.md (project-specific) | drop>

## Blocked
<id> | <why> | <last systematic-debugging 4-phase diagnosis>
```

## Rules
- Each fan-in: append one Story Log line.
- A durable, reusable learning (not story-specific) → also stage under Pending Amendments. Never auto-merge to constitution OR ARCHITECTURE.md. Architecture drift a subagent proposed in its summary is staged here too — written to ARCHITECTURE.md only by the human at the QA gate.
- 3-strike + systematic-debugging failure → append Blocked line, set story `status: blocked` in prd.json.
- Fresh session resuming a blocked story reads `## Blocked`: deps changed since? re-dispatch once. Else stalled → escalate human.
- caveman:ultra: drop all articles/filler, fragments, exact technical terms. This is machine scratch, not prose.
