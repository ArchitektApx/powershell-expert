# PowerShell Expert Skill

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-1.3.0-green.svg)](CHANGELOG.md)
[![Platform](https://img.shields.io/badge/PowerShell-5.1%20|%207+%20(Windows%20|%20Linux%20|%20macOS)-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skill-blueviolet.svg)](https://claude.ai/code)

A Claude Code skill for developing PowerShell scripts, tools, and modules following Microsoft best practices.

## Features

- **Script Development** - Templates, naming conventions, parameter design, pipeline patterns
- **Best Practices & Style** - Error handling, output, performance, security, plus the community (PoshCode) formatting standard
- **Cross-Platform Compatibility** - Tiered targeting: PowerShell 7 on all platforms by default, Windows PowerShell 5.1 support when feasible; path handling, encoding, platform detection
- **Testing** - Pester 5 patterns, mocking, and a ready-made PSScriptAnalyzer compatibility settings file
- **PowerShell Gallery Integration** - Search, install, and manage modules via PSResourceGet
- **Module Recommendations** - Curated list of popular modules by category
- **Live Verification** - Validates module availability and cmdlet syntax against live documentation

## Installation

### As a plugin (recommended)

Add this repo as a marketplace, then install the plugin. Claude Code checks the marketplace for updates and you can pull them with `/plugin marketplace update`.

```
/plugin marketplace add ArchitektApx/powershell-expert
/plugin install powershell-expert@powershell-expert
```

### Other agents (`npx skills`)

The [skills CLI](https://github.com/vercel-labs/skills) installs the skill into every supported agent it detects (Claude Code, Cursor, Codex, Copilot, and others):

```bash
npx skills@latest add ArchitektApx/powershell-expert
```

This installs the skill only, without marketplace updates. Re-run the command to pull a newer version.

### Manual

Copy the skill folder to your Claude Code skills directory:

```bash
cp -r powershell-expert ~/.claude/skills/
```

Or unzip the packaged skill:

```bash
unzip powershell-expert.skill -d ~/.claude/skills/
```

## Usage

The skill activates automatically when you ask Claude Code to:

- Write PowerShell scripts or functions
- Find or recommend PowerShell modules
- Follow PowerShell best practices

### Example Prompts

```
"Write a PowerShell script to monitor disk space"
"What module should I use for working with Excel files?"
"Help me add proper error handling to this script"
"Make this script work on both Windows PowerShell 5.1 and PowerShell 7 on Linux"
"Write Pester tests for this function"
```

### Live Verification

When accuracy is critical, the skill verifies information against live sources:

| Verification Type | Source |
|-------------------|--------|
| Module exists/active | PowerShell Gallery |
| Cmdlet syntax | Microsoft Learn / raw GitHub docs |
| PSResourceGet cmdlets | Raw GitHub markdown (deterministic URL) |
| Version requirements | Gallery metadata |

Module recommendations are always verified before being presented. If live verification fails, the skill falls back to executing `Search-Gallery.ps1` locally or prompts the user to verify manually.

## Skill Contents

```
powershell-expert/
├── SKILL.md                          # Core workflow and quick reference
├── scripts/
│   ├── Search-Gallery.ps1            # Enhanced PowerShell Gallery search
│   └── PSScriptAnalyzer.Tier1.psd1   # Compat lint settings (5.1 + 7)
└── references/
    ├── best-practices.md    # Naming, parameters, pipeline, errors,
    │                        #   output, performance, security
    ├── style-guide.md       # Formatting, capitalization, readability,
    │                        #   comments (PoshCode community standard)
    ├── cross-platform.md    # 5.1 + 7 compatibility tiers, paths,
    │                        #   encoding, platform detection
    ├── testing.md           # Pester 5, mocking, static analysis
    └── powershellget.md     # Module management cmdlets
```

## Cross-Platform Targeting

Scripts default to the highest compatibility tier that fits the project:

| Tier | Target | When |
|------|--------|------|
| **1** (default) | Windows PowerShell 5.1 + PowerShell 7, all platforms | No constraint against 5.1 |
| **2** | PowerShell 7+, all platforms | Project targets PS 7, or a required module/feature is Core-only |
| Windows-only | 5.1 and/or 7 on Windows | WinForms/WPF, Registry, Windows-only modules |

Dropping 5.1 never means dropping Linux/macOS — cross-platform path, encoding, and cmdlet-availability rules apply in every tier.

## Documentation Sources

- [PowerShell Docs](https://learn.microsoft.com/en-us/powershell/)
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [Module Browser](https://learn.microsoft.com/en-us/powershell/module/)
- [PowerShell-Docs (raw)](https://raw.githubusercontent.com/MicrosoftDocs/PowerShell-Docs/live/reference/)
- [PSResourceGet Docs (raw)](https://raw.githubusercontent.com/MicrosoftDocs/powershell-docs-psget/live/powershell-gallery/powershellget-3.x/Microsoft.PowerShell.PSResourceGet/)
- [PowerShell Practice and Style (PoshCode)](https://github.com/PoshCode/PowerShellPracticeAndStyle)

## License

MIT
