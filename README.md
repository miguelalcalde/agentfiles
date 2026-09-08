# Agentfiles

This repository publishes installable skills.

```bash
npx skills add mikemajara/skills --skill backlog
npx skills add mikemajara/skills --skill sdlc-first-principles
npx skills add mikemajara/skills --skill conversation
npx skills add mikemajara/skills --skill brainstorm
npx skills add mikemajara/skills --skill google-docs
npx skills add mikemajara/skills --skill voice-miguel
npx skills add mikemajara/skills --skill nightly-learn
```

## backlog

Workflow for capturing work and moving issues through research → refine →
implement → qa. GitHub Issues are the default source of truth.

```text
.backlog/
  inbox.md
  plans/
  memory.md
```

- `inbox.md` — optional local scratch until promoted.
- `plans/` — product specs only (what/why/in/out/AC), when the issue body is not enough.
- `memory.md` — durable decisions, blockers, conventions, gotchas.
- A **plan** is the product spec for one issue. Split oversized work into more issues. No implementation-sequence docs.

Example prompts:

```text
Use the backlog skill to initialize this project.
Use the backlog skill to capture this task.
Use the backlog skill to refine the next issue.
```

After install:

```bash
node path/to/skills/backlog/scripts/backlog-setup.mjs
```

`--check` reports skill version and label schema. See `CHANGELOG.md` for
label-schema 3 migration (`status:unknown` / `status:ready` → `phase:*` +
`status:open`).

## sdlc-first-principles

The `sdlc-first-principles` skill applies Elon Musk's five-step process
improvement algorithm to software delivery: challenge requirements, delete
unnecessary work, simplify what remains, accelerate cycle time, and automate
last.

## conversation

Use `conversation` when the idea is already mostly formed. The agent
pressure-tests it with you: gaps, contradictions, missing constraints, and
edge cases. It does not invent a new direction or dump an option catalog.

Example prompts:

```text
Think this through with me — what am I missing?
Pressure-test this plan before I build it.
```

## brainstorm

Use `brainstorm` when you want new angles. The agent generates options,
including unconventional ones, and follows what lands. It does not audit a
plan you already have.

Example prompts:

```text
Brainstorm this with me.
Give me more creative directions for this idea.
```

## google-docs

Thin, connector-agnostic operating rules for Google Docs: create, format,
edit, comments, suggestions, and review. Draft in Markdown; use whatever Docs
tools the harness exposes — do not hard-code a connector.

## voice-miguel

Opt-in voice skill for Miguel Alcalde (`disable-model-invocation: true`).
One thin skill with registers for email, Slack/messaging, blog/essay, and
short summaries. Invoke with "voice-miguel" / "in my voice" — never apply by
default.

## nightly-learn

Periodic (e.g. nightly) consolidation: promote sticky how-to facts from an
agent's **own** memory into skills (or skill patches). Harness-agnostic;
schedule is a per-agent routine. HITL before rewriting shared upstream skills.
