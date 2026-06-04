# Schema — review-bundle.json

Manifest-first review input sidecar. Written by orchestrator before expert-review dispatch. Lives at `tasks/<task-id>/manifests/<story-id>/review-bundle.json`.

```json
{
  "sliceId": "string — story id slug",
  "taskBranch": "string",
  "sliceBranch": "string",
  "baseCommit": "string — task branch commit before slice merge",
  "headCommit": "string — slice branch head commit",
  "reviewers": ["backend-architect | dba | frontend-reviewer | test-reviewer"],
  "changedFiles": ["path", "..."],
  "diffStat": "string — compact git diff --stat output",
  "testEvidence": [
    {
      "command": "string",
      "outcome": "pass | fail | skipped",
      "summary": "string — one-line result",
      "logPath": "string | null — path relative to Task root"
    }
  ],
  "prdExcerptPath": "string — path relative to Task root or null",
  "testCasePaths": ["path", "..."],
  "notes": ["string"]
}
```

## Invariants
- Orchestrator writes pointers + cheap metadata only. No full raw diffs or full test logs.
- Reviewer workers use `baseCommit`, `headCommit`, `changedFiles`, and paths to pull scoped evidence themselves.
- `test-reviewer` must be present in `reviewers[]` for every slice.
- Path in prompts is relative to Task root: `manifests/<story-id>/review-bundle.json`.
