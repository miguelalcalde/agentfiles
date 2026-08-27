# Backlog skill — plan (locked)

> Status: locked for implementation. Supersedes the earlier spec draft, reference-tree draft, and agentos alignment draft.
> Scope: this repository (`mikemajara/skills`), skill `backlog` only. Other runtimes may install it; they are not specified here.

---

## Resolution: issue + plan (product only)

There is **one** shaping artifact besides the issue, and it is called a **plan**.

A plan **is** the product spec (what people used to call a PRD): problem, goal, in scope, out of scope, acceptance criteria, open questions. It is **not** a second document for files, APIs, task order, or “how we will implement.”

If the work is too big for one implementable unit, **split into more issues** (each with its own plan or a plan skipped as trivial). Do not add a parent PRD folder and a child PLAN folder.

| Artifact | Role |
| -------- | ---- |
| **Issue** | Canonical unit of work. Labels, discussion, assignment. Source of truth. |
| **Plan** | Product spec for that issue when the issue body is not enough. No implementation details. |
| **Research brief** | Facts and questions **before** a plan exists. Not a plan. Not AC. |

**Writing the plan is refine**, not a separate pipeline phase. There is no `phase:plan` and no `.backlog/plans/` vs `.backlog/prds/` split.

Implementation sequence is the implementer’s job from a product-complete plan (and the repo’s other skills). It is not a backlog artifact.

---

## What this skill is

The skill of running a backlog: capture work, keep issues honest, and move them through research → refine → implement → qa.

It teaches **how to proceed on an issue** (claim, audit, do the phase, leave a durable result, advance labels). It does not teach GitHub-the-product. Default backend is GitHub Issues; `gh` lives in a reference.

Progressive disclosure (skill standard): `SKILL.md` stays thin and always-on when invoked. The agent **reads a reference only when that action is in progress**. Links from `SKILL.md` are one level deep. Any agent with the skill installed can do this. No other system is required.

---

## Decision record

| Topic | Decision |
| ----- | -------- |
| Branch | `main` is canonical; delete `backlog-v2` after this lands |
| Install | One skill: `npx skills add mikemajara/skills --skill backlog` |
| Old phase skills | Retire `backlog-research`, `backlog-refine`, `backlog-plan` as separate installs |
| Source of truth | Issues (GitHub by default) |
| Shaping artifact | **Plan** = product spec only. No parallel PRD. No implementation plan file. |
| Pipeline | `phase:research` → `phase:refine` → `phase:implement` → `phase:qa` |
| Labels | This skill’s **label definition**. Consumers adopt or they don’t. |
| `gh` / scripts | `references/github.md` and `scripts/`, not the core procedure |
| Other products | Out of scope (not named in `SKILL.md` or workflow) |

---

## Label definition

Four axes. Exactly one of each on an open issue this skill is managing.

### `type:*`

`type:feat` | `type:fix` | `type:nit`

### `priority:*`

`priority:high` | `priority:medium` | `priority:low`

### `phase:*` — where in the pipeline

| Label | Means | Open reference |
| ----- | ----- | -------------- |
| `phase:research` | Facts are thin | `references/research.md` |
| `phase:refine` | Shaping the plan / issue until the plan is done | `references/refine.md` (plan template + DoD live here or in `references/plan.md` as the *artifact* spec, not a phase) |
| `phase:implement` | Plan is done (or skipped); write the change | Short Execute in `SKILL.md` |
| `phase:qa` | Change exists; judge it against the plan | `references/qa.md` |

Skip research when facts are enough → start at `phase:refine`. Skip a written plan file when the issue body already *is* a complete plan (typical `type:nit` / obvious `type:fix`) → `phase:implement` with `plan skipped: <reason>` on the issue.

### `status:*` — claim overlay (not a phase)

| Label | Means |
| ----- | ----- |
| `status:open` | Available |
| `status:doing` | Claimed |
| `status:blocked` | Waiting on a human or dependency |
| `status:duplicate` | Same outcome as another issue; close it |

`status:doing` is set while researching, refining, implementing, or doing QA. Restore `status:open` or `blocked` when stopping. Do not change `phase:*` unless that phase actually finished.

Do not use `status:unknown` / `status:ready` / `status:needs-plan`.

---

## How work proceeds (tracker-agnostic)

1. Review: claimed work first, then dedupe, then sort by phase.
2. Pick an issue.
3. Audit: labels vs body vs artifacts; fix drift and say why.
4. Claim: `status:doing`.
5. Do the current `phase:*` using the matching reference.
6. Leave the durable result **on the issue** (body and/or comment; plan file only as a buffer, then fold into the issue or pointer).
7. Advance `phase:*` or set `status:blocked`. Clear `doing`.

---

## References (definition of done is per craft)

Each reference is the **skill of that action**, including when it is done. Not one global “definition of good” for all issues.

| File | Craft | Done when |
| ---- | ----- | --------- |
| `references/research.md` | Product research: facts, constraints, unknown unknowns | Enough to write a plan; open questions listed; **no** invented AC, **no** file lists |
| `references/plan.md` | What a plan *is* (template + DoD) | A competent implementer would not invent product behavior. **No** implementation details, file paths, or API shapes |
| `references/refine.md` | Getting an issue to that bar (procedure, hardening by `type:*`) | Issue (and plan if used) meets `plan.md` DoD → `phase:implement`, or `blocked` |
| `references/qa.md` | Judging a change against the plan | Pass → close; product hole → `phase:refine`; bug in the change → `phase:implement` |
| `references/workflow.md` | Phase diagram, skip rules by `type:*` | — |
| `references/drift.md` | Labels vs reality | — |
| `references/github.md` | `gh` + helper scripts **if** the tracker is GitHub | — |
| `references/labels.json` | Machine names/colors for this skill’s labels | — |
| `references/version.json` | Skill semver + `label_schema` | — |

`SKILL.md`: router, label cheat sheet, artifact roles (issue / plan / research brief / memory), reference index, short Execute, hard rules. Target ~150–250 lines.

Hardening stays in `refine.md` (how). Whether to run it stays in refine/workflow skip rules by `type:*` (feat fuller than fix; nit skip with a note). Escalate when the change is cross-cutting, data-model/migration, or external-API sensitive — not a payments special case.

---

## Target tree

```text
skills/backlog/
  SKILL.md
  assets/
    agent-hint.md
    memory.md
    inbox.md                 # optional local scratch; deprecate later toward “the issue is the inbox”
  references/
    version.json
    labels.json
    workflow.md
    research.md
    plan.md                  # artifact + DoD, not a pipeline phase
    refine.md
    qa.md
    drift.md
    github.md
  scripts/                   # existing helpers; keep, document in github.md
```

No `references/handoff.md` aimed at a particular agent runtime. The issue’s labels *are* the handoff.

---

## Versioning

- `version` in `SKILL.md` frontmatter and `references/version.json`
- `label_schema` integer when label names/meanings change (this redesign = new schema)
- `CHANGELOG.md` as today
- Breaking workflow = major; new reference or hardening category = minor; wording = patch
- `backlog-setup.mjs --check` reports version + schema (stamper for repos that opt in). Day-to-day agents **read labels on the issue**, they do not re-implement a taxonomy.

---

## Implementation batches

**Batch 1 — Skeleton on `main`:** stub `references/`, version in frontmatter, index in `SKILL.md`. No live label rename yet.

**Batch 2 — Contract:** `workflow.md`, `plan.md` DoD, `labels.json` (`phase:*` + slim `status:*`). Migration: old `status:unknown` → `phase:refine`; old `status:ready` → `phase:implement`. Close draft PR that added `status:needs-plan` (that concept is gone).

**Batch 3 — Craft playbooks:** `research.md`, `refine.md` (incl. hardening), `qa.md`. Delete separate `backlog-*` skill folders.

**Batch 4 — Operations:** `drift.md`, move `gh` recipes to `github.md`, setup `--check`.

**Batch 5 — Cleanup:** delete `backlog-v2`; README / `CLAUDE.md` single-skill install; inbox deprecation note.

---

## Out of scope

- Which process, channel, or agent product consumes this skill
- Teaching GitHub as the skill (backend only)
- A second artifact for implementation sequencing
- Separate installable `backlog-research` / `backlog-refine` / `backlog-plan`
