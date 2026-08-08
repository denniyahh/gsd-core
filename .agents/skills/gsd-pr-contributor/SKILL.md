---
name: gsd-pr-contributor
description: Validates and prepares GSD pull requests to meet open-gsd upstream contribution standards.
---

# GSD PR Contributor Skill

Use this skill when preparing to open a Pull Request against `open-gsd/gsd-core`. It ensures all strict repository checks pass before submission.

## 1. Branch and Issue Check
- Ensure you are working on a branch off `upstream/next` (not `main`).
- Ensure there is an approved linked issue with the `confirmed-bug`, `approved-enhancement`, or `approved-feature` label.

## 2. Changeset Requirement
- Run `npm run changeset -- --type <Type> --pr <PR_NUMBER> --body "<Description>"` to create a changeset in `.changeset/`.
- Ensure the changeset frontmatter contains `pr: <PR_NUMBER>`.
- Allowed types: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

## 3. Documentation Updates
- If your changeset is `Added`, `Changed`, `Deprecated`, or `Removed`, you must modify at least one markdown file in `docs/` or `README.md`.
- If the change truly has no docs impact, you MUST add `<!-- docs-exempt: <reason> -->` on its own line inside the body of the changeset fragment.

## 4. PR Title Format
- Your PR title MUST strictly be formatted as `type(#<issue>): short summary`.
- Examples: `fix(#1542): roadmap rollback`, `feat(#39): milestone-prefixed phase IDs`.
- Do not use brackets like `[fix]`.

## 5. PR Body Template
- Do not use the default template.
- Identify the type of your PR and read the contents of the matching template:
  - `.github/PULL_REQUEST_TEMPLATE/fix.md`
  - `.github/PULL_REQUEST_TEMPLATE/enhancement.md`
  - `.github/PULL_REQUEST_TEMPLATE/feature.md`
- Fill out all required fields, including the checklist, regression testing, and root cause sections, and use it as the body of your `gh pr create` command.

## 5. Local Pre-Push Verification (STRICT)
- You MUST run `npm run build && npm run lint:ci && npm test` locally before pushing code to `origin`.
- Ensure `tests/helpers/git-fixture.cjs` sets `process.env.GSD_TEST_MODE = '1'` to avoid test mode drift.

## 6. Maintainer Communication & CI Verification Rule
- ALWAYS query CI status via `gh run list --workflow Tests` or `gh pr checks <PR_NUMBER>`. Never rely on un-filtered `gh run list` (which returns single-job sidecars).
- Do NOT post a comment to maintainers stating that a PR is ready for review until ALL GitHub Actions CI checks have completed successfully (100% green).

