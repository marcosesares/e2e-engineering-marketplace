# Schema — slice-result.json

Evidence sidecar. Written by orchestrator at impl fan-in. Lives at `tasks/<task-id>/manifests/<story-id>/slice-result.json`. Sub-agents return this shape; orchestrator persists it — sub-agents never write files.

```json
{
  "sliceId": "string — story id slug",
  "status": "done | blocked",
  "summary": "string — caveman-ultra one-liner",
  "testsPassed": "boolean",
  "branch": "string — worktree branch name",
  "findings": [
    {
      "type": "blocker | warning",
      "message": "string"
    }
  ]
}
```

## Invariants
- **Status never authoritative.** Orchestrator reconciles `status` at fan-in; writes canonical value to `prd.json`. Sidecar `status` is informational only.
- `findings[]` empty array if clean. `type:blocker` = contributed to `blocked`; `type:warning` = noted but not blocking.
- Orchestrator writes this file, then updates `prd.json` story's `resultManifestPath` to point at it.
- Path in prd.json is relative to Task root: `manifests/<story-id>/slice-result.json`.
