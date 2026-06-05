# Schema — verification-result.json

Evidence sidecar for GATE 5 (verification-before-completion). **ACTIVE — ADR 0024 (Fork Y):** = full automated suite (unit+API) green + AC-checklist-vs-code, no live-UI exercise. Written at gate 5 inside self-review. Lives at `tasks/<task-id>/manifests/<story-id>/verification-result.json` (or `manifests/_task/verification-result.json` for task-level verification).

```json
{
  "scope": "story-id | _task — story-scoped or task-level verification",
  "status": "passed | failed",
  "suiteGreen": "boolean — full unit+API suite green from clean state",
  "checklist": [
    {
      "criterion": "string — acceptance criteria text",
      "verified": "boolean",
      "method": "automated | manual | self-review"
    }
  ],
  "notes": "string — caveman-ultra; gaps or deferred items"
}
```

## Invariants
- **Active (Fork Y, ADR 0024).** `status: passed` requires `suiteGreen: true` AND every `checklist[]` item `verified: true`.
- `method: automated` = covered by unit/API test (green). `method: manual` = UI AC mapped to a Manual test-case (proven later in human-QA). `method: self-review` = code-path confirmed by reading code. **No live-UI exercise** — `/run`+`/verify` removed.
- `scope: _task` = task-level cross-slice verification (post-DAG-drain). `scope: <story-id>` = per-slice (future).
- Orchestrator writes this file at gate 5; updates prd.json with `verificationManifestPath`.
- `checklist[]` maps 1:1 to PRD `acceptanceCriteria[]` for traceability.
