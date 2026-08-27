# QA

Judge a change against the **product plan** on the issue (`references/plan.md`). Not a restatement of how to open a PR.

## When

`phase:qa` — a reviewable change exists that claims this issue.

## Procedure

1. Claim `status:doing`.
2. Read the issue (canonical plan) and the change.
3. Check acceptance criteria and in/out of scope. Implementation extras that are not in the plan are either out of scope (fail) or a plan hole (back to refine).
4. Verdict **on the issue** (comment).
5. **Pass** — close the issue (or leave project-specific close rules). Clear `doing`.
6. **Bug in the change** — `phase:implement` + `status:open`.
7. **Plan was wrong / product hole** — `phase:refine` + `status:open` (or `blocked`).

## Done when

A written verdict: pass, implement-again, or refine-again, with AC cited.
