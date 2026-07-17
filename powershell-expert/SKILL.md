---
name: powershell-expert
description: Develop PowerShell scripts, tools, modules, and GUIs following Microsoft best practices. Use when writing PowerShell code, creating Windows Forms/WPF interfaces, working with PowerShell Gallery modules, or needing cmdlet/module recommendations. Covers script development, parameter design, pipeline handling, error management, GUI creation patterns, Pester testing, and cross-platform compatibility (Windows PowerShell 5.1 and PowerShell 7 on Windows/Linux/macOS). Verifies module availability and cmdlet syntax against live documentation when accuracy is critical.
---

# PowerShell Expert

Develop production-quality PowerShell scripts, tools, and GUIs using Microsoft best practices and the PowerShell ecosystem.

## Quick Reference

### Script Structure
```powershell
#Requires -Version 5.1

<#
.SYNOPSIS
    Brief description.
.DESCRIPTION
    Detailed description.
.PARAMETER Name
    Parameter description.
.EXAMPLE
    Example-Usage -Name 'Value'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Name,

    [switch]$Force
)

begin {
    # One-time setup
}

process {
    foreach ($item in $Name) {
        # Per-item processing
    }
}

end {
    # Cleanup
}
```

### Function Template
```powershell
function Verb-Noun {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('CN')]
        [string]$ComputerName = [Environment]::MachineName,

        [switch]$PassThru
    )

    process {
        if ($PSCmdlet.ShouldProcess($Name, 'Action')) {
            # Implementation
            if ($PassThru) { $result }   # implicit output - no Write-Output, no return
        }
    }
}
```

## Workflow

### 1. Script Development
Follow naming and parameter conventions:
- **Verb-Noun** format with approved verbs (`Get-Verb`)
- **Strong typing** with validation attributes
- **Pipeline support** via `ValueFromPipeline`
- **-WhatIf/-Confirm** for destructive operations

Non-negotiables (community standard):
- Full cmdlet + parameter names in saved code — no aliases, no positional args
- No backtick line continuation — splat instead; OTBS braces, 4-space indent
- No `Write-Host` except `Show-*`/`Format-*` or interactive prompts; emit objects, not text
- No `return` for output in advanced functions — emit from `process {}`; one output type, declare `[OutputType()]`
- `-ErrorAction Stop` inside `try`; copy `$_` first in `catch`; never test `$?`
- Never `+=` arrays/strings in loops — collect loop output or use `List[T]`/`-join`
- Credentials as `[PSCredential]`, never plaintext `[string]`; no `Invoke-Expression`

See [best-practices.md](references/best-practices.md) for behavior rules, [style-guide.md](references/style-guide.md) for formatting.

Test non-trivial code with Pester 5 — see [testing.md](references/testing.md) for setup, mocking, and CI patterns.

### 2. GUI Development
**Windows-only** — WinForms/WPF work in 5.1 and PS 7 on Windows, but not on Linux/macOS. For cross-platform interactivity use console UX (`Read-Host`, `$Host.UI.PromptForChoice`, `Out-GridView` alternatives) or a web UI (e.g., Pode).

Windows Forms for simple dialogs, WPF/XAML for complex interfaces:

```powershell
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form -Property @{
    Text          = 'Title'
    Size          = New-Object System.Drawing.Size(400, 300)
    StartPosition = 'CenterScreen'
}
```

See [gui-development.md](references/gui-development.md) for controls, events, and templates.

### 3. Cross-Platform Scripts

**Default target: PowerShell 7 on all platforms (Windows/Linux/macOS). Add Windows PowerShell 5.1 support when feasible — drop it only with a concrete reason.**

Choose the compatibility tier before writing code:

| Situation | Tier | `#Requires` |
|-----------|------|-------------|
| No constraint against 5.1 (default) | **Tier 1: 5.1 + 7, all platforms** | `-Version 5.1` |
| Project explicitly targets PS 7, or a required module/API is Core-only, or PS7-only features (ternary, `-Parallel`, `clean{}`) bring real value | **Tier 2: PS 7+, all platforms** | `-Version 7.0` |
| Windows-only tech required (WinForms/WPF, Registry, Windows modules) | Windows-only — still prefer PS 7 syntax unless 5.1 needed | `-Version 5.1` or `7.0` |

When choosing Tier 2, state the reason (e.g., "module X requires PS 7"). If unclear whether 5.1 support matters, ask the user.

**Cross-platform rules apply in every tier** (Tier 2 still runs on Linux/macOS):
- **Paths via `Join-Path`** / `$HOME` / `[IO.Path]`; never hardcode `\` or `C:\`; mind Linux case-sensitivity
- **Explicit `-Encoding`** on all file writes
- **`Get-CimInstance`** not `Get-WmiObject`; guard Windows-only cmdlets with `$IsWindows`

**Tier 1 additionally** requires:
- No PS7-only syntax: ternary, `??`, `?.`, `&&`, `ForEach-Object -Parallel`
- Guard `$IsWindows` — undefined in 5.1: `$PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows`

See [cross-platform.md](references/cross-platform.md) for full syntax table, encoding matrix, cmdlet availability, and PSScriptAnalyzer compat-rule setup.

### 4. PowerShell Gallery Integration
Search and install modules using PSResourceGet:

```powershell
# Search gallery
Find-PSResource -Name 'ModuleName' -Repository PSGallery

# Install module
Install-PSResource -Name 'ModuleName' -Scope CurrentUser -TrustRepository
```

Use [scripts/Search-Gallery.ps1](scripts/Search-Gallery.ps1) for enhanced search.

See [powershellget.md](references/powershellget.md) for full cmdlet reference.

## Key Patterns

### Error Handling
```powershell
try {
    $result = Get-Content -Path $Path -ErrorAction Stop
}
catch [System.IO.FileNotFoundException] {
    Write-Error "File not found: $Path"
    return
}
catch {
    throw
}
```

### Splatting for Readability
```powershell
$params = @{
    Path        = $sourcePath
    Destination = $destPath
    Recurse     = $true
    Force       = $true
}
Copy-Item @params
```

### Pipeline Best Practices
```powershell
# Stream output immediately - implicit output, no buffering, no += arrays
foreach ($item in $collection) {
    Convert-Item $item
}

# Accept pipeline input
param(
    [Parameter(ValueFromPipeline)]
    [string[]]$InputObject
)
process {
    foreach ($obj in $InputObject) {
        # Process each
    }
}
```

## Module Recommendations

When recommending modules, search the PowerShell Gallery. These are common starting points — **always verify via the Live Verification workflow before recommending**:

| Category | Popular Modules |
|----------|----------------|
| **Azure** | `Az`, `Az.Compute`, `Az.Storage` |
| **Testing** | `Pester`, `PSScriptAnalyzer` |
| **Console** | `PSReadLine`, `Terminal-Icons` |
| **Secrets** | `Microsoft.PowerShell.SecretManagement` |
| **Web** | `Pode` (web server), `PoshRSJob` (async) |
| **GUI** | `WPFBot3000`, `PSGUI` |

## Live Verification

You MUST verify information against live sources when accuracy is critical. Do not rely solely on training data for module availability or cmdlet syntax.

**Tools to use:**
- **WebFetch**: Retrieve and parse specific documentation URLs (PowerShell Gallery pages, Microsoft Docs)
- **WebSearch**: Find correct URLs when the exact path is unknown or to verify module existence

### When Verification is Required

| Scenario | Action |
|----------|--------|
| User asks "does module X exist?" | **MUST** verify via PowerShell Gallery |
| Recommending a specific module | **MUST** verify it exists and isn't deprecated |
| Providing exact cmdlet syntax | **SHOULD** verify against Microsoft Docs |
| Module version requirements | **MUST** check gallery for current version |
| General best practices | Static references are sufficient |

### Step 1: Verify Module on PowerShell Gallery

When recommending or checking a module, **use the WebFetch tool** to verify it exists:

**WebFetch call:**
- **URL**: `https://www.powershellgallery.com/packages/{ModuleName}`
- **Prompt**: `Extract: module name, latest version, last updated date, total downloads, and whether it shows any deprecation warning or 'unlisted' status`

**If WebFetch returns 404 or error**: The module likely doesn't exist. **Use the WebSearch tool** to confirm:
- **Query**: `{ModuleName} PowerShell module site:powershellgallery.com`

### Step 2: Verify Cmdlet Syntax (When Needed)

Microsoft Docs URLs vary by module. **Use the WebSearch tool** to find the correct documentation page:

**WebSearch call:**
- **Query**: `{Cmdlet-Name} cmdlet site:learn.microsoft.com/en-us/powershell`

**Then use WebFetch** on the returned URL with prompt:
- **Prompt**: `Extract the complete cmdlet syntax, required vs optional parameters, and PowerShell version requirements`

**For PSResourceGet cmdlets specifically**, fetch the raw markdown directly:
- **URL**: `https://raw.githubusercontent.com/MicrosoftDocs/powershell-docs-psget/live/powershell-gallery/powershellget-3.x/Microsoft.PowerShell.PSResourceGet/{Cmdlet-Name}.md`
- **Prompt**: `Extract the complete cmdlet syntax, required vs optional parameters, and examples`

### Step 3: Fallback Strategies

If the WebFetch or WebSearch tools are unavailable or return errors:

1. **For module verification**: Execute `Search-Gallery.ps1` from this skill:
   ```powershell
   ~/.claude/skills/powershell-expert/scripts/Search-Gallery.ps1 -Name 'ModuleName'
   ```

2. **For cmdlet syntax**: Suggest the user run locally:
   ```powershell
   Get-Help Cmdlet-Name -Full
   Get-Command Cmdlet-Name -Syntax
   ```

3. **Clearly state uncertainty**: If verification fails, tell the user:
   > "I wasn't able to verify this against live documentation. Please confirm
   > the module exists by running: `Find-PSResource -Name 'ModuleName'`"

### Verification Examples

**Good** (verified with live data):
> "The ImportExcel module (v7.8.10, updated Oct 2024, 17M+ downloads)
> provides Export-Excel for creating spreadsheets without Excel installed."

**Bad** (unverified claim):
> "Use the Excel-Tools module to export data." ← May not exist!

## Documentation Resources

- **PowerShell Docs**: https://learn.microsoft.com/en-us/powershell/
- **Module Browser**: https://learn.microsoft.com/en-us/powershell/module/
- **PowerShell Gallery**: https://www.powershellgallery.com
- **GitHub Docs (raw)**: https://raw.githubusercontent.com/MicrosoftDocs/PowerShell-Docs/live/reference/
- **PSResourceGet Docs (raw)**: https://raw.githubusercontent.com/MicrosoftDocs/powershell-docs-psget/live/powershell-gallery/powershellget-3.x/Microsoft.PowerShell.PSResourceGet/

## References

- **[best-practices.md](references/best-practices.md)** - Naming, parameters, pipeline, error handling, output, performance, security
- **[style-guide.md](references/style-guide.md)** - Formatting, capitalization, readability, comments, comment-based help
- **[cross-platform.md](references/cross-platform.md)** - PS 5.1 + 7 compatibility, path handling, encoding, platform detection
- **[testing.md](references/testing.md)** - Pester 5, mocking, TestDrive, PSScriptAnalyzer, CI matrix
- **[gui-development.md](references/gui-development.md)** - Windows Forms, WPF, controls, events, templates
- **[powershellget.md](references/powershellget.md)** - Find, install, update, publish modules
