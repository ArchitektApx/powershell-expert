# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code skill for PowerShell development. The skill provides templates, best practices, and reference documentation for writing PowerShell scripts, tools, modules, and GUIs.

## Build Commands

```bash
# Package the skill (creates .skill zip file)
zip -r powershell-expert.skill powershell-expert -x "*.DS_Store"

# Install to Claude Code skills directory
cp -r powershell-expert ~/.claude/skills/
```

## Architecture

This is a Claude Code skill following the standard skill structure:

- `powershell-expert/SKILL.md` - Main skill definition with frontmatter (name, description) and core workflow. This is what Claude loads when the skill triggers.
- `powershell-expert/references/` - Detailed documentation loaded on-demand to keep context efficient:
  - `best-practices.md` - Naming, parameters, pipeline, error handling, output, performance, security
  - `style-guide.md` - Formatting, capitalization, readability, comments (PoshCode community standard)
  - `cross-platform.md` - PS 5.1 + 7 compatibility tiers, paths, encoding, platform detection
  - `testing.md` - Pester 5 patterns, mocking, PSScriptAnalyzer, CI matrix
  - `gui-development.md` - Windows Forms and WPF patterns, control examples, event handling
  - `powershellget.md` - PowerShell Gallery cmdlets (PSResourceGet)
- `powershell-expert/scripts/` - Helper scripts and assets:
  - `Search-Gallery.ps1` - Enhanced wrapper for Find-PSResource
  - `PSScriptAnalyzer.Tier1.psd1` - Ready-made compat lint settings (5.1 + 7)

## Skill Design Principles

- SKILL.md should stay under 500 lines; detailed content goes in references/
- Reference files are loaded only when needed (progressive disclosure)
- Scripts can be executed without loading into context
- The description in SKILL.md frontmatter determines when the skill triggers
