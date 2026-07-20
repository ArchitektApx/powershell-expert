# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code skill for PowerShell development. The skill provides templates, best practices, and reference documentation for writing PowerShell scripts, tools, and modules.

## Build Commands

```bash
# Package the skill (creates .skill zip file)
zip -r powershell-expert.skill powershell-expert -x "*.DS_Store" -x "**/.claude-plugin/*"

# Install to Claude Code skills directory
cp -r powershell-expert ~/.claude/skills/
```

## Architecture

This repo is both a Claude Code plugin marketplace (root) and the single plugin it serves (`powershell-expert/`):

- `.claude-plugin/marketplace.json` - Marketplace manifest at repo root, points to `./powershell-expert` as the plugin source
- `powershell-expert/.claude-plugin/plugin.json` - Plugin manifest. Bump `version` here on every release alongside `CHANGELOG.md` and the README badge, otherwise `/plugin marketplace update` has nothing to detect
- `powershell-expert/SKILL.md` - Main skill definition with frontmatter (name, description) and core workflow. This is what Claude loads when the skill triggers.
- `powershell-expert/references/` - Detailed documentation loaded on-demand to keep context efficient:
  - `best-practices.md` - Naming, parameters, pipeline, error handling, output, performance, security
  - `style-guide.md` - Formatting, capitalization, readability, comments (PoshCode community standard)
  - `cross-platform.md` - PS 5.1 + 7 compatibility tiers, paths, encoding, platform detection
  - `testing.md` - Pester 5 patterns, mocking, PSScriptAnalyzer, CI matrix
  - `powershellget.md` - PowerShell Gallery cmdlets (PSResourceGet)
- `powershell-expert/scripts/` - Helper scripts and assets:
  - `Search-Gallery.ps1` - Enhanced wrapper for Find-PSResource
  - `PSScriptAnalyzer.Tier1.psd1` - Ready-made compat lint settings (5.1 + 7)

## Skill Design Principles

- SKILL.md should stay under 500 lines; detailed content goes in references/
- Reference files are loaded only when needed (progressive disclosure)
- Scripts can be executed without loading into context
- The description in SKILL.md frontmatter determines when the skill triggers

## Release Process

1. Update `CHANGELOG.md` with the new version number and date
2. Update the README badge with the new version number
3. Update the `version` in `powershell-expert/.claude-plugin/plugin.json`
4. Package the skill for manual installation