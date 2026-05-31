# queue.json — schema (Task queue)

Lives at `.e2e-engineering/queue.json`. The cross-Task ordering layer ABOVE per-Task `prd.json`. See ADR 0017, CONTEXT.md "Task queue".

```
{ tasks: [{
    id,                                # kebab-case; also the tasks/<id>/ dir name
    title,
    priority,                          # integer, lower = sooner (P1 most urgent)
    dependsOn: [ids],                  # CROSS-TASK DAG (camelCase). Distinct from story-level
                                       #   depends_on (snake_case, within one prd.json).
    status: todo|in-progress|pending-qa|done|blocked,
    selected: true|false,              # in THIS flight batch (Run selection)
    parentTask: id|null                # set when this Task was born from a QA finding
}] }
```

## Invariants
- **Single in-progress**: at most ONE Task is `status:in-progress` at a time. Flight drains Tasks serially; parallelism lives INSIDE a Task (story fan-out/fan-in).
- **`<e2e-complete>`** fires when no `selected:true` Task is `todo` or `in-progress` (all selected are pending-qa / done / blocked).
- **dependsOn closure**: selecting a Task auto-includes its unmet `dependsOn` Tasks (a batch is never internally inconsistent).

## Writers (disjoint fields, never concurrent — ADR 0017)
- **/e2e-engineering** (interactive) CREATES entries at gate 1 and sets `priority`, `dependsOn`, `selected`, `parentTask`.
- **/e2e-flight** FLIPS `status` only (todo → in-progress → pending-qa / blocked / done). One Task per spawn, no driver loop (ADR 0022).
- They never run at the same time: the interactive session fully exits before flight runs.

## Status lifecycle
```
todo ──(flight picks)──> in-progress ──(impl+gate4+gate5auto+review)──> pending-qa
                              │                                              │
                              └──(3-strike fail, all blocked)──> blocked     └──(QA session approve)──> done
```
`done` does NOT mean human-blessed until the QA sign-off session runs — `pending-qa` is the honest intermediate (ADR 0018).

## Selection ordering
Flight picks next = `selected:true` AND `status:todo` AND all `dependsOn` in {done, pending-qa}, lowest `priority` number first.
