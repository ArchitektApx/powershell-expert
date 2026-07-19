# PowerShell Best Practices Reference

Based on Microsoft guidance and the community PowerShell Practice and Style guide (PoshCode). Formatting/readability rules live in [style-guide.md](style-guide.md).

## Table of Contents
1. [Naming Conventions](#naming-conventions)
2. [Parameter Design](#parameter-design)
3. [Pipeline Support](#pipeline-support)
4. [Language Pitfalls](#language-pitfalls)
5. [Error Handling](#error-handling)
6. [Output Patterns](#output-patterns)
7. [Performance](#performance)
8. [Security](#security)
9. [Tools vs Controllers](#tools-vs-controllers)

---

## Naming Conventions

### Cmdlet/Function Names
- **Verb-Noun format**: Always use approved verbs from `Get-Verb`
- **Pascal Case**: Capitalize first letter of verb and all noun terms
- **Singular Nouns**: Even for cmdlets operating on multiple items
- **Specific Nouns**: Use product-specific nouns, not generic terms

```powershell
# Good
Get-SQLServerInstance
New-AzureStorageAccount
Remove-UserSession

# Bad
Get-Server           # Too generic
Get-Servers          # Plural noun
get-sqlserverinstance  # Wrong case
Get-SQLServerInstance  # Acronyms >2 letters: PascalCase (Sql), not all caps
```

### Parameter Names
- **Pascal Case**: `ErrorAction`, not `errorAction`
- **Singular Names**: Unless parameter always accepts arrays
- **Standard Names**: Use established parameter names with aliases

```powershell
param(
    [Parameter(Mandatory)]
    [string]$Name,

    # Standard name users know from native cmdlets; aliases for interop
    [Alias('CN', 'ComputerName')]
    [string]$Server,

    [string[]]$Tags  # Plural - accepts array
)
```

### Variable Names
- **$PascalCase** for all variables, including local scope; camelCase only with a specific reason
- **Descriptive names** over abbreviations

### Paths
- Full, explicit paths; relative paths (`.`, `..`) only right after you `Set-Location` yourself
- Base script-relative paths on `$PSScriptRoot`
- **.NET methods and native tools don't use `$PWD`** — they use `[Environment]::CurrentDirectory`. Always pass absolute paths: `[IO.File]::ReadAllText((Convert-Path $Path))`
- Avoid `~` — its meaning depends on the current provider; use `$HOME`

---

## Parameter Design

### Use Strong Typing
```powershell
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [ValidateRange(1, 100)]
    [int]$Count = 10,

    [ValidateSet('Debug', 'Info', 'Warning', 'Error')]
    [string]$LogLevel = 'Info',

    [switch]$Force,

    [nullable[bool]]$Enabled  # Three states: true, false, unspecified
)
```

### Parameter Sets
```powershell
[CmdletBinding(DefaultParameterSetName = 'ByName')]
param(
    [Parameter(ParameterSetName = 'ByName', Position = 0)]
    [string]$Name,

    [Parameter(ParameterSetName = 'ById')]
    [int]$Id,

    [Parameter(ParameterSetName = 'ByObject', ValueFromPipeline)]
    [PSObject]$InputObject
)
```

### Common Parameters to Support
| Parameter | Use Case |
|-----------|----------|
| `-Force` | Override warnings/protections |
| `-PassThru` | Return modified objects |
| `-WhatIf`/`-Confirm` | Free via `SupportsShouldProcess` — never declare manually |
| `-Verbose`/`-Debug` | Free via `[CmdletBinding()]` — never declare manually |

### Path Parameters
```powershell
param(
    [Parameter(ParameterSetName = 'Path')]
    [SupportsWildcards()]
    [string[]]$Path,

    [Parameter(ParameterSetName = 'LiteralPath')]
    [Alias('PSPath')]
    [string[]]$LiteralPath
)
```

---

## Pipeline Support

### Function Structure Rules
- **Always `[CmdletBinding()]`** on scripts and functions — enables common parameters and output streams
- Blocks in order: `param()`, `begin {}`, `process {}`, `end {}`
- **Emit output only from `process {}`** in pipeline functions; `begin`/`end` are for setup/cleanup, not output
- **Don't use `return` to emit output** in advanced functions — place the object on its own line; `return` only for early exit
- Declare `[OutputType([TypeName])]` when the function returns objects
- Include `process {}` whenever a parameter accepts pipeline input

### Accept Pipeline Input
```powershell
param(
    [Parameter(ValueFromPipeline)]
    [string[]]$Name,

    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string]$Path
)

process {
    foreach ($Item in $Name) {
        Get-ItemDetail -Name $Item   # result streams immediately - implicit output
    }
}
```

### Write Objects Immediately
```powershell
# Good - each object streams down the pipeline immediately
foreach ($Item in $Collection) {
    Convert-Item $Item
}

# Bad - array rebuild every iteration (O(n²)), nothing streams
$Results = @()
foreach ($Item in $Collection) {
    $Results += Convert-Item $Item
}
$Results
```

---

## Language Pitfalls

- **`$null` on the left of comparisons**: `if ($null -eq $X)`. With `$X` on the left, comparing a collection *filters* instead of comparing — `@() -eq $null` yields an empty array (falsy), so the check silently passes. PSScriptAnalyzer rule: `PSPossibleIncorrectComparisonWithNull`.
- **Comparison operators filter collections**: `$Array -eq 5` returns the matching *elements*, not a boolean. For membership tests use `-contains`/`-in`; for counting use `.Count`.
- **Single-element unrolling**: a function emitting one object returns that object, not a one-element array. Wrap the call in `@(...)` whenever `.Count` or indexing must work.
- **`Set-StrictMode -Version Latest`** during development catches typo'd variables and missing properties; pair with PSScriptAnalyzer in CI.
- **`[switch]` test**: use `$Force.IsPresent` or just `$Force` — never compare to `$true`.
- **String truthiness**: `'0'` and `' '` are truthy, `''` and `$null` are falsy — test `[string]::IsNullOrEmpty()` / `IsNullOrWhiteSpace()` explicitly for strings.

---

## Error Handling

### Core Rules
- **`-ErrorAction Stop`** on cmdlets inside `try` — non-terminating errors don't trigger `catch` otherwise
- For non-cmdlets (native commands, .NET calls): set `$ErrorActionPreference = 'Stop'` before, restore after
- **Put the whole transaction in the `try` block**, not just the first risky line — no flag variables
- **Copy `$_` to your own variable immediately** in `catch` — subsequent commands overwrite it
- **Never test `$?` or null results** as an error-detection strategy; rely on exceptions
- Don't clear `$Error`; PowerShell maintains it, `$Error[0]` is the latest
- One task per operation (one file, one computer) keeps error handling clean

### Use Try/Catch with Specific Errors
```powershell
try {
    $Content = Get-Content -Path $Path -ErrorAction Stop
    $Data = $Content | ConvertFrom-Json
    Set-Content -Path $OutPath -Value $Data.name -Encoding UTF8 -ErrorAction Stop
}
catch [System.IO.FileNotFoundException] {
    Write-Error "File not found: $Path"
    return
}
catch [System.UnauthorizedAccessException] {
    Write-Error "Access denied: $Path"
    return
}
catch {
    $Err = $_   # capture before doing anything else
    Write-Error "Failed processing '$Path': $($Err.Exception.Message)"
    throw $Err
}
```

### Terminating vs Non-Terminating Errors
```powershell
# Terminating - stops execution
throw "Critical error occurred"
$PSCmdlet.ThrowTerminatingError($ErrorRecord)   # preferred in advanced functions

# Non-terminating - continues execution
Write-Error "Problem with item: $Item"
$PSCmdlet.WriteError($ErrorRecord)
```

### Feedback Methods
```powershell
# Warnings - potential unintended consequences
Write-Warning "File will be overwritten"

# Verbose - detailed operational info (requires -Verbose)
Write-Verbose "Processing file: $Path"

# Debug - troubleshooting info (requires -Debug)
Write-Debug "Variable state: $($Var | ConvertTo-Json)"

# Progress - long-running operations
Write-Progress -Activity "Processing" -Status "Item $I of $Total" -PercentComplete (($I / $Total) * 100)
```

---

## Output Patterns

### Use the Right Stream
- **Output stream**: actual results only — the one stream callers consume. Never mix status strings with data objects.
- **`Write-Host`**: **only** in `Show-*`/`Format-*` functions or interactive prompts — it cannot be captured or redirected. Everything else uses another stream.
- **One output type per command**; declare it with `[OutputType()]`. Multiple types only internally or when piping each to `Out-Default` separately.
- **No `Format-*` inside functions** — formatting destroys objects. Ship a `<Module>.format.ps1xml` referenced in the module manifest; `PSTypeName` binds objects to their view automatically.

### Return Typed Objects
```powershell
# Create custom objects with type name
[PSCustomObject]@{
    PSTypeName = 'MyModule.ServerInfo'   # enables format views + type-based filtering
    Name       = $Server.Name
    Status     = $Server.Status
    IPAddress  = $Server.IP
}
```

### PassThru Pattern
```powershell
function Set-WidgetProperty {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSObject]$InputObject,
        [string]$Value,
        [switch]$PassThru
    )

    process {
        if ($PSCmdlet.ShouldProcess($InputObject.Name, 'Set property')) {
            $InputObject.Property = $Value
            if ($PassThru) { $InputObject }
        }
    }
}
```

### ShouldProcess Pattern
```powershell
function Remove-WidgetCache {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param([string]$Path)

    if ($PSCmdlet.ShouldProcess($Path, 'Delete cache')) {
        # Perform deletion
    }
}
```

---

## Performance

- **Measure before optimizing**: `Measure-Command { ... }` on realistic data, on the target PowerShell version and hardware
- **Never `+=` an array in a loop** — quadratic rebuild. Collect loop output directly, or use `[System.Collections.Generic.List[object]]` with `.Add()`:
  ```powershell
  $Results = foreach ($Item in $Items) { Convert-Item $Item }
  ```
- **Never `+=` strings in a loop** — use `-join`, here-strings, or `[System.Text.StringBuilder]`
- `foreach (...)` statement is faster than piping to `ForEach-Object`; but for large files/streams, pipeline streaming (`Get-Content ... | ForEach-Object`) wins on memory over loading everything first
- **Filter left**: `Get-Process -Name x` beats `Get-Process | Where-Object Name -eq x` — push filters into the cmdlet/provider/query, not the pipeline
- Speed hierarchy when it matters: language features > .NET method calls > cmdlet invocation; direct code > function-call overhead in hot loops
- Don't sacrifice readability for negligible gains on small data — aesthetics and performance both count

---

## Security

- **Never accept or store passwords as `[string]`.** Use `[PSCredential]`:
  ```powershell
  param(
      [System.Management.Automation.Credential()]
      [PSCredential]$Credential = [PSCredential]::Empty
  )
  ```
  The `Credential()` attribute prompts securely if the user passes only a username.
- Accept credentials as parameters — don't call `Get-Credential` inside tool functions
- Extract plaintext only at the last moment, for APIs that demand it: `$Credential.GetNetworkCredential().Password`
- Secure interactive input: `Read-Host -AsSecureString`
- Persist credentials with `Export-CliXml` (DPAPI-encrypted, locked to user+machine, Windows only); load with `Import-CliXml`. Cross-platform or shared secrets: `Microsoft.PowerShell.SecretManagement`
- Never `Invoke-Expression` on user input or downloaded content; avoid it generally — the `&` call operator plus splatting covers almost every legitimate use
- Don't log or `Write-Verbose` secrets

---

## Tools vs Controllers

Two kinds of scripts — don't mix their responsibilities:

- **Tools** (functions in modules): reusable; input via parameters, output raw minimally-processed objects to the pipeline; no formatting, no `Write-Host`, no business assumptions
- **Controllers** (scripts): automate one specific process by composing tools; may format output for humans, write reports, hardcode business specifics; not built for reuse

Rules:
- Check for an existing built-in or gallery command before writing your own
- Code you'll use twice belongs in a function; functions used across projects belong in a module
- Wrap external/native tools in advanced functions so callers keep objects, pipeline, and error semantics; document why the native tool was necessary
- Version requirements: `#Requires -Version X.Y` at script top; `PowerShellVersion = 'X.Y'` in module manifests. Target the lowest version you actually support (see [cross-platform.md](cross-platform.md) tiers)

---

## Code Style

Formatting, capitalization, aliases, splatting, comments, and comment-based help: see [style-guide.md](style-guide.md).
