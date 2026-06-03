# CLAUDE.md

## Repository Purpose

This repository publishes installable skills.

Expected install commands:

```bash
npx skills add mikemajara/skills --skill backlog
npx skills add mikemajara/skills --skill todoist-api
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
skills/backlog/scripts/backlog-sync.mjs
skills/todoist-api/SKILL.md
skills/todoist-api/references/endpoints.md
skills/todoist-api/references/api-semantics.md
```

The `backlog` skill is intentionally self-contained. It teaches an LLM how to
bootstrap and maintain a lightweight `.backlog/` folder inside whichever project
is using the skill.

Default structure created by the skill:

```text
.backlog/
  inbox.md
  issues.md
  prds/
  plans/
  memory.md
```

## Design Decisions

- Skill name must remain `backlog`.
- Todoist API skill name must remain `todoist-api`.
- Prefer one self-contained `SKILL.md`; keep helper scripts optional, small,
  dependency-free, and directly tied to the `backlog` workflow.
- Keep `todoist-api` as API mechanics/reference only. Task workflow,
  project defaults, date defaults, and user preferences belong in the consuming
  agent's instructions, not in the skill.
- The skill should encode judgment, not ceremony.
- GitHub Issues are canonical for promoted work.
- `.backlog/inbox.md` is for rough ideas not yet promoted to GitHub Issues.
- `.backlog/issues.md` is generated/read-only local visibility into GitHub
  Issues.
- `.backlog/memory.md` is curated context future agents should remember.
- PRDs are created only when product-level clarification helps.
- Plans are created only when implementation needs sequencing, risk tracking, or
  future agent execution.
- Small fixes, chores, and nitpicks can stay as compact inbox items.

## Cleanup History

The repo previously contained reusable agents, commands, settings, an installer,
root backlog scaffold files, and multiple personal skills. Those were removed in
commit `2778632` to make this repo a clean source for only the `backlog` skill.

## Development Notes

- Before changing a skill, read its `SKILL.md` and keep it concise.
- Preserve compatibility with the `skills/<name>/SKILL.md` layout.
- If adding files, make sure they directly support installing or using a skill.
- Update `CHANGELOG.md` when changing the generated `.backlog/` structure,
  migration expectations, or user-visible workflow semantics.
- Do not add generated project `.backlog/` files to this repository; the skill
  should create those in downstream projects.
