# PowerShell Style Guide

Formatting and readability conventions from the community PowerShell Practice and Style guide (PoshCode). These govern how code looks; see [best-practices.md](best-practices.md) for how code behaves.

## Table of Contents
1. [Code Layout & Formatting](#code-layout--formatting)
2. [Capitalization](#capitalization)
3. [Readability](#readability)
4. [Comments](#comments)
5. [Comment-Based Help](#comment-based-help)

---

## Code Layout & Formatting

- **One True Brace Style**: opening brace ends the line, closing brace starts its own line. Exception: small scriptblocks passed as parameters may stay on one line: `Where-Object { $_.Enabled }`
- **Indent 4 spaces** per level, never tabs
- **Line length ≤ 115 characters**
- **No backticks for line continuation** — hard to read, easy to miss, easy to mistype. Instead: splatting, or break after `|`, `,`, or an opening bracket/brace/paren (implied continuation)
- **No semicolons** as line terminators; none in multi-line hashtables
- **Blank lines**: two around function/class definitions, one between class methods, one at end of file; single blank lines for logical sections inside functions
- **Spacing**:
  - One space around operators (`$a -eq $b`) and after commas/semicolons
  - No space inside `[]` or plain `()`; one space inside `$( ... )` and `{ ... }` subexpressions
  - No space before unary operators: `-1`, `$i++`

```powershell
# Good
if ($Path) {
    $files = Get-ChildItem -Path $Path |
        Where-Object { $_.Length -gt 1MB } |
        Sort-Object -Property Length -Descending
}
```

### Splatting Instead of Backticks
```powershell
# Good
$params = @{
    Path        = $sourcePath
    Destination = $destPath
    Recurse     = $true
    Force       = $true
    ErrorAction = 'Stop'
}
Copy-Item @params

# Bad
Copy-Item -Path $sourcePath `
          -Destination $destPath `
          -Recurse -Force
```

Align hashtable/splat assignments on `=` as above.

---

## Capitalization

| Element | Case | Example |
|---------|------|---------|
| Functions, cmdlets | PascalCase | `Get-WidgetStatus` |
| Parameters | PascalCase | `-ComputerName` |
| Module names, classes | PascalCase | `WidgetTools` |
| Script/global variables | PascalCase | `$ScriptRootConfig` |
| Local variables | camelCase acceptable | `$itemCount` |
| Language keywords | lowercase | `foreach`, `try`, `param` |
| Comment-help keywords | UPPERCASE | `.SYNOPSIS` |
| Two-letter acronyms | both capitals | `$PSBoundParameters`, `Get-PSDrive` |

---

## Readability

- **Full cmdlet names, never aliases** in saved code: `Where-Object` not `?`, `ForEach-Object` not `%`, `Get-ChildItem` not `gci`/`ls`. Aliases are for the interactive shell only.
- **Full parameter names, no positional arguments** in saved code:

```powershell
# Good
Get-Process -Name 'notepad'

# Bad
Get-Process notepad
gps notepad
```

- **Natural line breaks** after pipe characters, one pipeline stage per line:

```powershell
Get-Process |
    Where-Object { $_.CPU -gt 100 } |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 10
```

- Indent within constructs to show what belongs to them; format consistently throughout a file

---

## Comments

- Comments explain **why** — reasoning, decisions, constraints — never restate what the code does
- Write in English, complete sentences; keep synchronized with the code or delete them
- **Inline comments**: at least two spaces after the code; align consecutive inline comments in a block
- One block comment above a section beats a comment on every line
- Block comments: `#` + single space per line, indented to code level; `<# ... #>` for long documentation with delimiters on their own lines

```powershell
$retryDelay = 30          # Vendor API rate-limits at 2 req/min
$maxAttempts = 5          # SLA allows up to 2.5 min total wait

# DNS may lag behind the API's provisioning response, so we poll
# instead of trusting the first success reply.
while (-not (Resolve-DnsName $fqdn -ErrorAction SilentlyContinue)) {
    Start-Sleep -Seconds $retryDelay
}
```

---

## Comment-Based Help

Required for every public function. Place inside the function, at the top. Minimum: `.SYNOPSIS` plus one `.EXAMPLE` per major use case. Add `.INPUTS`/`.OUTPUTS` for pipeline functions, `.NOTES` for background, `.LINK` for references. Write in plain language — no jargon.

```powershell
function Get-ServerStatus {
    <#
    .SYNOPSIS
        Gets the operational status of specified servers.

    .DESCRIPTION
        Retrieves operational status including CPU, memory,
        and network information from remote servers.

    .EXAMPLE
        Get-ServerStatus -Name 'Server01'

        Gets status for Server01.

    .EXAMPLE
        'Server01', 'Server02' | Get-ServerStatus

        Gets status for multiple servers via pipeline.
    #>
    [CmdletBinding()]
    param(
        # The server name(s) to query.
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Name
    )
    # Implementation
}
```

**Parameter documentation**: prefer a comment inside the `param` block directly above each parameter (as shown) over `.PARAMETER` sections — it stays in sync when parameters change.
