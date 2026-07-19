# Cross-Platform PowerShell (5.1 + 7.x)

Writing scripts that run on Windows PowerShell 5.1 (.NET Framework) and PowerShell 7+ (.NET, all platforms).

## Compatibility Tiers

Cross-platform PowerShell 7 support is always the baseline. 5.1 support is preferred but conditional:

- **Tier 1 (default): 5.1 + 7, all platforms.** Everything in this document applies.
- **Tier 2: PS 7+ only, all platforms.** Justified when the project explicitly targets PS 7, a required module is Core-only, or PS7 features carry real value. The "Syntax: What 5.1 Does NOT Have" section and 5.1-specific workarounds (TLS forcing, `-UseBasicParsing`, `$IsWindows` guard, BOM requirement) no longer apply — use PS 7 syntax freely. **All other sections still apply**: path handling, encoding explicitness, case-sensitivity, cmdlet platform availability, native command traps.

Dropping 5.1 does not mean dropping Linux/macOS. Never narrow to Windows-only without a hard technical reason (WinForms/WPF, Registry, Windows-only modules).

## Version & Platform Detection

```powershell
# Edition: 'Desktop' = 5.1, 'Core' = 6+/7+
$PSVersionTable.PSEdition
$PSVersionTable.PSVersion

# $IsWindows/$IsLinux/$IsMacOS exist only in PS 6+.
# In 5.1 they are undefined ($null), which is falsy — so guard like this:
$script:IsWinPlatform = if ($PSVersionTable.PSEdition -eq 'Desktop') { $true } else { $IsWindows }

# Or the common one-liner (safe in both editions):
if ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows) { <# Windows #> }
```

**Never** write `if ($IsWindows)` alone in a script that must run on 5.1 — under `Set-StrictMode` it throws, and without strict mode it silently evaluates false on 5.1 (which IS Windows).

Declare intent at the top:

```powershell
#Requires -Version 5.1
```

Do **not** use `#Requires -PSEdition Core` unless the script truly cannot run on 5.1.

## Syntax: What 5.1 Does NOT Have

Avoid these PS 7-only features in shared code:

| PS 7 feature | 5.1-compatible replacement |
|---|---|
| Ternary `$X ? 'a' : 'b'` | `if ($X) { 'a' } else { 'b' }` |
| Null-coalescing `$A ?? $B` | `if ($null -ne $A) { $A } else { $B }` |
| Null-conditional `${A}?.Foo` | `if ($null -ne $A) { $A.Foo }` |
| Pipeline chains `cmd1 && cmd2` | `cmd1; if ($?) { cmd2 }` |
| `ForEach-Object -Parallel` | `Start-Job` / runspace pools / sequential |
| `clean {}` block (7.3+) | `finally` / `end` block |
| `Get-Error` | `$Error[0] \| Format-List * -Force` |
| `Invoke-RestMethod -SkipCertificateCheck` | Custom `ServicePointManager` callback (5.1) |
| `ConvertFrom-Json -AsHashtable` | Iterate PSCustomObject properties |
| `Join-Path a b c` (multiple children) | `Join-Path (Join-Path a b) c` |

`ConvertTo-Json` depth default differs (2 in 5.1, also 2 in 7 but 7 warns on truncation) — always pass `-Depth` explicitly.

## File Paths

```powershell
# ALWAYS build paths with Join-Path — never hardcode \ or /
$Config = Join-Path $HOME '.myapp/config.json'   # forward slash inside literals is OK on Windows too

# Separators when you need them
[IO.Path]::DirectorySeparatorChar   # \ on Windows, / elsewhere
[IO.Path]::PathSeparator            # ; on Windows, : elsewhere (for PATH-style lists)

# Split PATH portably
$env:PATH -split [IO.Path]::PathSeparator
```

Rules:
- Forward slashes work as path separators on **all** platforms including Windows — prefer `/` in literals if you must write one.
- Linux/macOS filesystems are **case-sensitive**: `Config.json` ≠ `config.json`. Match exact casing in code and repo.
- No drive letters outside Windows. Never assume `C:\`. Use `$HOME`, `[IO.Path]::GetTempPath()`, `$PSScriptRoot`.
- `$env:USERPROFILE`, `$env:APPDATA`, `$env:TEMP` are Windows-only. Portable equivalents:

```powershell
$HOME                                # home dir, all platforms, both editions
[IO.Path]::GetTempPath()             # temp dir, all platforms
$PSScriptRoot                        # script's own directory
# Per-user app data:
if ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows) {
    $AppData = $env:APPDATA
} else {
    $AppData = Join-Path $HOME '.config'   # XDG convention
}
```

- Environment **variable names** are case-sensitive on Linux: `$env:Path` is `$null` there — always write `$env:PATH`, `$env:HOME` in the exact OS casing.

## Encoding

Biggest silent breakage between editions:

| Cmdlet default | 5.1 | 7+ |
|---|---|---|
| `Out-File`, `>` | UTF-16 LE | UTF-8 no BOM |
| `Set-Content`/`Add-Content` | ANSI (system codepage) | UTF-8 no BOM |
| `Export-Csv` | ASCII | UTF-8 no BOM |

Fix: **always pass `-Encoding` explicitly** on file-writing cmdlets.

```powershell
# 'utf8' means WITH BOM in 5.1, WITHOUT BOM in 7. 'utf8NoBOM' doesn't exist in 5.1.
# Interop-safe choice accepted by both: utf8 (accept the BOM difference), or:
Set-Content -Path $F -Value $Text -Encoding UTF8    # works both; BOM in 5.1 only
```

If BOM-less UTF-8 is required from 5.1, drop to .NET:

```powershell
[IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
```

**Script files themselves**: save `.ps1` with non-ASCII characters as **UTF-8 with BOM** — 5.1 misreads BOM-less UTF-8 as ANSI; PS 7 handles both.

Line endings: use `[Environment]::NewLine` when it matters; don't assume `` `r`n ``.

## Cmdlet Availability

Windows-only, missing or nonfunctional in PS 7 on Linux/macOS:
- `Get-WmiObject` — **removed entirely in PS 7 even on Windows**. Use `Get-CimInstance` (works in 5.1 too — the single best swap for compatibility).
- Windows Forms / WPF (`Add-Type -AssemblyName System.Windows.Forms`) — PS 7 Windows-only; nothing on Linux/macOS.
- Registry provider (`HKLM:`, `Get-ItemProperty` on registry) — Windows only.
- `Get-EventLog` — removed in PS 7; use `Get-WinEvent` (Windows only).
- `Get-Service`/`Get-Process -IncludeUserName` etc. — `Get-Service` exists on PS 7 Windows only.
- `*-Acl`, scheduled task, `NetTCPIP`, `Defender`, most `Windows*` modules — Windows only.

**Windows PowerShell compatibility layer** (PS 7 on Windows): `Import-Module -Name ModuleName -UseWindowsPowerShell` runs a 5.1-only module in a background 5.1 process and proxies it. Caveat: results are **deserialized** objects — no methods, property values only. Useful escape hatch when one legacy module blocks an otherwise Tier 2 script; don't build heavily on it.

5.1 gaps:
- `Invoke-WebRequest`/`Invoke-RestMethod`: pass `-UseBasicParsing` in 5.1 (no-op but valid in 7; default there). Without it 5.1 can hang on machines where IE engine is unavailable.
- Absent in 5.1: `Test-Json`, `Get-Uptime`, `Remove-Alias`; the `-Shuffle` parameter on `Get-Random`.
- TLS: 5.1 may negotiate TLS 1.0 by default. Before web calls (add, don't overwrite existing protocols):

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
```

Guard platform-specific blocks:

```powershell
if ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows) {
    $OS = Get-CimInstance Win32_OperatingSystem
} else {
    $OS = uname -a
}
```

## Native Commands & Aliases

- 5.1 aliases `curl`/`wget` to `Invoke-WebRequest`, `sc` to `Set-Content`. PS 7 removed these; on Linux they hit the real binaries. **Never use those aliases** — spell out the cmdlet or call the native tool by full path/`curl.exe`.
- `sort`, `where` are aliases in PowerShell but native binaries exist on Linux — always use `Sort-Object`, `Where-Object`.
- Exit codes: check `$LASTEXITCODE` after native commands; `$?` semantics for native commands differ subtly across versions.

## .NET API Differences

5.1 runs .NET Framework 4.x; PS 7 runs modern .NET. Avoid:
- APIs added after .NET Framework 4.8 (e.g., `[string]::Create`, many `Span`-based overloads).
- `Add-Type` with C# using new language features — 5.1 compiles with C# 5.
- Assembly loading differs; prefer `Add-Type -AssemblyName` over hardcoded GAC paths.

Culture: parse/format numbers and dates invariantly to avoid locale breakage:

```powershell
[double]::Parse($S, [Globalization.CultureInfo]::InvariantCulture)
$Date.ToString('yyyy-MM-dd')   # not ToShortDateString()
```

## Running on Linux/macOS

Directly executable scripts need a shebang as line 1 and the executable bit:

```powershell
#!/usr/bin/env pwsh
```

```bash
chmod +x ./script.ps1
```

Harmless on Windows (`#!` is a comment). Note: shebang must be line 1, so it goes **above** `#Requires` lines.

## Testing & Linting

```powershell
# Run both engines on Windows:
powershell.exe -NoProfile -File .\script.ps1   # 5.1
pwsh -NoProfile -File .\script.ps1             # 7

# PSScriptAnalyzer compatibility rules — catches most of the above statically.
# Ready-made settings file ships with this skill: scripts/PSScriptAnalyzer.Tier1.psd1
Invoke-ScriptAnalyzer -Path .\script.ps1 -Settings @{
    Rules = @{
        PSUseCompatibleSyntax   = @{ Enable = $true; TargetVersions = @('5.1', '7.0') }
        PSUseCompatibleCommands = @{ Enable = $true; TargetProfiles = @(
            'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework',
            'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
        ) }
    }
}
```

Pester tests: run the suite under both `powershell.exe` and `pwsh` in CI (GitHub Actions: `windows-latest` has both; add `ubuntu-latest` for PS 7 Linux).

## Compatibility Checklist

All tiers:
- [ ] All paths via `Join-Path` / `$HOME` / `[IO.Path]`; no hardcoded `C:\` or `\`
- [ ] Exact file-name casing (Linux case-sensitive)
- [ ] Explicit `-Encoding` on every file write
- [ ] `Get-CimInstance` not `Get-WmiObject`; Windows-only cmdlets guarded
- [ ] No `curl`/`wget`/`sc` aliases
- [ ] `-Depth` on `ConvertTo-Json`
- [ ] Tested on PS 7 (ideally Windows + Linux/MacOS); PSScriptAnalyzer compat rules pass

Tier 1 (5.1 + 7) additionally:
- [ ] `#Requires -Version 5.1`, no PS7-only syntax (ternary, `??`, `&&`)
- [ ] `$IsWindows` guarded for 5.1 (`$PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows`)
- [ ] Script saved UTF-8 **with** BOM if it contains non-ASCII
- [ ] `-UseBasicParsing` on web cmdlets; TLS 1.2 forced in 5.1
- [ ] Tested under both `powershell.exe` and `pwsh` (if powershell.exe is available on the system)
