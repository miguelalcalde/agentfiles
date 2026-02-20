---
name: npm-publish
description: Publish npm packages safely with preflight checks, semver bumping, dry-runs, and post-release verification. Use when the user asks to publish to npm, release a package, bump package version, or ship prereleases.
disable-model-invocation: true
---

# npm-publish

You are publishing an npm package. Optimize for safety and repeatability.

## Workflow

Copy this checklist and track progress:

```md
Release Progress:

- [ ] Step 1: Pre-flight checks
- [ ] Step 2: Version and dist-tag decision
- [ ] Step 3: Validate package contents
- [ ] Step 4: Dry-run and publish
- [ ] Step 5: Post-publish verification
- [ ] Step 6: Failure handling (if needed)
```

## Step 1: Pre-flight checks

1. Confirm what should be published:
   - Single package or monorepo workspace
   - Target package path or workspace name
2. Require a clean working tree:
   - `git status --porcelain`
3. Confirm npm authentication and registry:
   - `npm whoami`
   - `npm config get registry`
4. Validate package metadata in `package.json`:
   - `name`, `version`, `license`
   - `main` or `exports`
   - `files` or `.npmignore`
   - `publishConfig` (if present)
5. Stop and ask the user if any required release detail is missing.

## Step 2: Version and dist-tag decision

1. If not explicitly provided, ask for bump type:
   - `patch`, `minor`, `major`, or `prerelease`
2. Decide npm dist-tag:
   - Stable release: `latest`
   - Pre-release: `beta`, `next`, or `rc`
3. Bump version without creating git tag automatically:
   - `npm version <bump> --no-git-tag-version`
4. Update `CHANGELOG.md` when present.

## Step 3: Validate package contents

Run quality gates before publish:

- `npm run lint --if-present`
- `npm test --if-present`
- `npm run build --if-present`
- `npm pack --dry-run`

Inspect dry-run output and ensure no secrets or internal files are included.

## Step 4: Dry-run and publish

Always do a publish dry-run first:

- Stable:
  - `npm publish --dry-run --access public`
- Tagged pre-release:
  - `npm publish --dry-run --tag <tag> --access public`

Then request explicit confirmation from the user for version and tag.

After confirmation, run the real publish:

- Stable:
  - `npm publish --access public`
- Tagged pre-release:
  - `npm publish --tag <tag> --access public`

If npm requires 2FA, use `--otp <code>`.

## Step 5: Post-publish verification

1. Verify package visibility:
   - `npm view <package-name>@<version>`
2. Commit release metadata:
   - `git add package.json package-lock.json CHANGELOG.md` (only files that exist and changed)
   - `git commit -m "chore(release): v<version>"`
3. Tag and push:
   - `git tag v<version>`
   - `git push`
   - `git push --tags`

## Step 6: Failure handling

- If publish fails before upload, fix the issue and retry from dry-run.
- If the wrong version is published, prefer follow-up patch releases and deprecation over unpublish.
- If unpublish/deprecate is needed, explain risks and provide exact commands before executing.

## Guardrails

- Never publish without explicit user confirmation of version and dist-tag.
- Never skip dry-run.
- Never use force-style flags for publish workflows.
- Stop if the working tree is dirty unless user approval is explicit.

## Output format

When invoked, return:

1. Release plan (`package`, `version`, `dist-tag`)
2. Commands executed
3. Validation and publish results
4. Post-publish verification
5. Follow-up actions or rollback guidance
