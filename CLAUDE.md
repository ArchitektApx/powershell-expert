# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project Overview

A Claude Code skill for PowerShell development, distributed as a plugin
marketplace. Everything under `powershell-expert/` is cloned onto every user who
installs from here, so content changes ship with no staged rollout.

## Architecture

The repo is both the marketplace (root) and the single plugin it serves:

- `.claude-plugin/marketplace.json` - Marketplace manifest, points to
  `./powershell-expert` as the plugin source
- `powershell-expert/.claude-plugin/plugin.json` - Plugin manifest. Bump
  `version` on every release together with `CHANGELOG.md` and the README badge,
  otherwise `/plugin marketplace update` has nothing to detect
- `powershell-expert/SKILL.md` - Skill definition with frontmatter (name,
  description) and core workflow. The description decides when the skill
  triggers
- `powershell-expert/references/` - Detailed docs loaded on demand:
  - `best-practices.md` - Naming, parameters, pipeline, error handling, output,
    performance, security
  - `style-guide.md` - Formatting, capitalization, readability, comments
    (PoshCode community standard)
  - `cross-platform.md` - PS 5.1 + 7 compatibility tiers, paths, encoding,
    platform detection
  - `testing.md` - Pester 5 patterns, mocking, PSScriptAnalyzer, CI matrix
  - `powershellget.md` - PowerShell Gallery cmdlets (PSResourceGet)
- `powershell-expert/scripts/` - Assets the skill tells agents to run:
  - `Search-Gallery.ps1` - Wrapper for Find-PSResource, queries PSGallery only
  - `PSScriptAnalyzer.Tier1.psd1` - Compat lint settings (5.1 + 7)

## Skill Design Principles

- SKILL.md stays under 500 lines; detailed content goes in `references/`
- Reference files load only when needed (progressive disclosure)
- Scripts run without loading into context

## Working in this repository

`main` is protected by a ruleset with no bypass, so nothing lands by pushing to
it. Branch, push the branch, open a PR, merge it yourself. To merge, a PR needs
the `verify` check green and squash as its merge method; it needs no approvals.

Every commit must be signed. Local commits inherit `commit.gpgsign`; Dependabot
and squash-merge commits are signed by GitHub.

Repository policy requires every action to be pinned to a full commit SHA. A tag
reference does not fail review, it fails the run.

Dependabot owns action versions and bumps them in one grouped PR monthly.
Bumping a SHA by hand only creates a conflict with the next one.

## Release Process

1. Update `CHANGELOG.md` with the new version and date
2. Update the README badge
3. Set `version` in `powershell-expert/.claude-plugin/plugin.json`
4. Merge via PR, then push tag `v<version>`

`release.yml` packages the `.skill` zip and creates the GitHub release from the
matching `CHANGELOG.md` section. It fails when the changelog has no entry for
the version or `plugin.json` disagrees with the tag.

Manual package: `zip -r powershell-expert.skill powershell-expert -x "*.DS_Store" -x "**/.claude-plugin/*"`

## Invariants

Preserve these through any refactor of `.github/workflows/`:

- **Actions pinned to commit SHAs**, enforced by repository policy.
  `action-gh-release` holds `contents: write`; a moved tag is a write path into
  this repository's releases.
- **`verify.yml` triggers on `pull_request`.** It runs PR-head code, so
  `pull_request_target` would hand fork PRs write access and secrets.
- **Release body passed as `body_path`.** Routed through `GITHUB_OUTPUT`, a
  changelog line matching the heredoc delimiter could write arbitrary step
  outputs.
- **`permissions: contents: read` by default**, `contents: write` only on the
  release job.
- **`verify.yml` refuses hooks, MCP configs, symlinks, executables, and raw
  network or `Invoke-Expression` calls in `powershell-expert/scripts`.** Each
  executes on the installer's machine. Adding one is a deliberate change: update
  the check in the same PR and say why.
- **Marketplace `source` stays a local `./` path.** Sourcing a plugin from
  another repo delegates trust to it for every installer.

## Gotchas

- `powershell-expert.skill` at the repo root is a tracked build artifact.
  Releases build their own; the tracked copy is only for manual install and can
  drift from the tree.
- SKILL.md tells agents to run `Install-PSResource -TrustRepository` and to
  `WebFetch` powershellgallery.com and raw.githubusercontent.com MicrosoftDocs
  pages. Keep those endpoints official; a new host is a new trust decision for
  every user.
- `npx skills` installs flat by frontmatter `name`. A second skill with the same
  `name` clobbers the first.
