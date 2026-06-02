# queue.json — schema (Task queue)

Lives at `.e2e-engineering/queue.json`. Cross-Task ordering layer ABOVE per-Task `prd.json`. See ADR 0017, CONTEXT.md "Task queue".

```
{ tasks: [{
    id,                                # kebab-case; also the tasks/<id>/ dir name
    title,
    priority,                          # integer, lower = sooner (P1 most urgent)
    dependsOn: [ids],                  # CROSS-TASK DAG (camelCase). Distinct from story-level
                                       #   depends_on (snake_case, within one prd.json).
    status: todo|in-progress|pending-qa|done|blocked,
    selected: true|false,              # in THIS flight batch (Run selection)
    parentTask: id|null                # set when Task born from QA finding
}] }
```

## Invariants
- **Single in-progress**: at most ONE Task `status:in-progress` at a time. Flight drains Tasks serially; parallelism inside Task only (story fan-out/fan-in).
- **`<e2e-complete>`** fires when no `selected:true` Task is `todo` or `in-progress` (all selected are pending-qa / done / blocked).
- **dependsOn closure**: selecting Task auto-includes unmet `dependsOn` Tasks (batch never internally inconsistent).

## Writers (disjoint fields, never concurrent — ADR 0017)
- **/e2e-engineering** (interactive) CREATES entries at gate 1; sets `priority`, `dependsOn`, `selected`, `parentTask`. Flips `pending-qa → done` at QA sign-off session.
- **/e2e-flight** FLIPS `status` only (todo → in-progress → pending-qa / blocked). One Task per spawn, no driver loop (ADR 0022). Never sets `done`.
- Never run at same time: interactive session fully exits before flight runs.

## Status lifecycle
```
todo ──(flight picks)──> in-progress ──(impl+review)──> pending-qa
                              │                               │
                              └──(3-strike fail)──> blocked    └──(QA session approve)──> done
```
`pending-qa`: flight ran all automatable steps; human sign-off deferred (ADR 0018). `done` = human-approved at QA gate.

## Selection ordering
Flight picks next = `selected:true` AND `status:todo` AND all `dependsOn` in {done, pending-qa}, lowest `priority` number first.
