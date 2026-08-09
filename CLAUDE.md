# CLAUDE.md

## Repository Purpose

This repository publishes installable skills.

Expected install commands:

```bash
npx skills add mikemajara/skills --skill backlog
npx skills add mikemajara/skills --skill sdlc-first-principles
```

Keep the repository focused on small, self-contained skills. Do not reintroduce
the previous portable agent framework, slash commands, setup script, global
installer, or project scaffold files unless explicitly requested.

## Current Shape

Tracked project files should stay minimal:

```text
README.md
CHANGELOG.md
CLAUDE.md
skills/backlog/SKILL.md
skills/backlog/assets/inbox.md
skills/backlog/assets/memory.md
skills/backlog/assets/agent-hint.md
skills/backlog/references/labels.json
skills/backlog/scripts/backlog-setup.mjs
skills/backlog/scripts/backlog-sync.mjs
skills/backlog/scripts/backlog-lib.mjs
skills/backlog/scripts/backlog-dedupe.mjs
skills/backlog/scripts/backlog-status.mjs
skills/backlog/scripts/backlog-issue-audit.mjs
skills/backlog/scripts/backlog-refinement-candidates.mjs
skills/sdlc-first-principles/SKILL.md
```

The `backlog` skill is intentionally self-contained. It teaches an LLM how to
bootstrap and maintain a lightweight `.backlog/` folder inside whichever project
is using the skill.

Default structure created by the skill:

```text
.backlog/
  inbox.md
  prds/
  plans/
  memory.md
```

## Design Decisions

- Skill name must remain `backlog`.
- Prefer one self-contained `SKILL.md`; keep helper scripts optional, small,
  dependency-free, and directly tied to the `backlog` workflow.
- The skill should encode judgment, not ceremony.
- GitHub Issues are canonical for promoted work.
- `.backlog/inbox.md` is for rough ideas not yet promoted to GitHub Issues.
- `.backlog/memory.md` is curated context future agents should remember.
- PRDs are created only when product-level clarification helps.
- Plans are created only when implementation needs sequencing, risk tracking, or
  future agent execution.
- Small fixes, chores, and nitpicks can stay as compact inbox items.

## Cleanup History

The repo previously contained reusable agents, commands, settings, an installer,
root backlog scaffold files, and unrelated personal skills. Keep this repository
focused on the installable skills listed above.

## Development Notes

- Before changing a skill, read its `SKILL.md` and keep it concise.
- Preserve compatibility with the `skills/<name>/SKILL.md` layout.
- If adding files, make sure they directly support installing or using a skill.
- Update `CHANGELOG.md` when changing the generated `.backlog/` structure,
  migration expectations, or user-visible workflow semantics.
- Do not add generated project `.backlog/` files to this repository; the skill
  should create those in downstream projects.
