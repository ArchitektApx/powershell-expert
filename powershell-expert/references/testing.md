# Testing PowerShell with Pester 5

Pester 5+ patterns for testing scripts, functions, and modules. Install: `Install-PSResource -Name Pester -Scope CurrentUser -TrustRepository`.

## File Layout

- Test file per unit under test: `Get-Widget.Tests.ps1` next to or under `tests/`
- Pester auto-discovers `*.Tests.ps1`
- Run all: `Invoke-Pester` from the project root; single file: `Invoke-Pester -Path ./tests/Get-Widget.Tests.ps1`

## Discovery vs Run — the #1 Pester 5 Gotcha

Pester 5 runs each file twice: **discovery** (finds `Describe`/`It` blocks) then **run**. Code at file top level or directly inside `Describe` executes during discovery — before any `BeforeAll`. Consequences:

- **All setup goes in `BeforeAll`/`BeforeEach`** — dot-sourcing, `Import-Module`, test data
- Variables defined in `BeforeAll` are available in `It` blocks of the same scope
- Data used to *generate* tests (`-ForEach`/`-TestCases` values) must exist at discovery time — top level or `BeforeDiscovery {}`

```powershell
BeforeAll {
    # Dot-source the unit under test; $PSCommandPath = path of this test file
    . ($PSCommandPath -replace '\.Tests\.ps1$', '.ps1')
}

Describe 'Get-Widget' {
    Context 'with valid input' {
        It 'returns one object per name' {
            $result = Get-Widget -Name 'a', 'b'
            $result | Should -HaveCount 2
        }

        It 'emits the custom type' {
            (Get-Widget -Name 'a').PSObject.TypeNames | Should -Contain 'Acme.Widget'
        }
    }

    Context 'with invalid input' {
        It 'throws on empty name' {
            { Get-Widget -Name '' } | Should -Throw
        }
    }
}
```

## Assertions (Should)

```powershell
$x | Should -Be 5                 # -eq (case-insensitive for strings)
$x | Should -BeExactly 'Name'     # case-sensitive
$x | Should -BeOfType [int]
$x | Should -HaveCount 3
$x | Should -Contain 'item'
$x | Should -Match '^\d+$'        # regex
$x | Should -BeNullOrEmpty
$x | Should -Not -BeNullOrEmpty
{ Remove-Widget -Name 'x' } | Should -Throw -ExceptionType ([InvalidOperationException])
```

## Mocking

```powershell
Describe 'Sync-Widget' {
    BeforeAll {
        . $PSScriptRoot/Sync-Widget.ps1

        Mock Invoke-RestMethod { @{ status = 'ok' } }
        Mock Write-EventLogEntry {}   # silence side effects
    }

    It 'calls the API once per widget' {
        Sync-Widget -Name 'a', 'b'
        Should -Invoke Invoke-RestMethod -Times 2 -Exactly
    }

    It 'passes the widget name in the body' {
        Sync-Widget -Name 'a'
        Should -Invoke Invoke-RestMethod -ParameterFilter { $Body -match '"name":"a"' }
    }
}
```

- Mocks are scoped to their `Describe`/`Context`; mocking a **module's** internals needs `Mock -ModuleName ModuleName`
- Only commands can be mocked — wrap .NET calls in small functions if tests must intercept them

## Data-Driven Tests

```powershell
It 'validates <Name> as <Expected>' -TestCases @(
    @{ Name = 'good-name'; Expected = $true }
    @{ Name = '';          Expected = $false }
    @{ Name = 'bad name!'; Expected = $false }
) {
    Test-WidgetName -Name $Name | Should -Be $Expected
}
```

## TestDrive & TestRegistry

- `TestDrive:\` — temp directory unique per `Describe`, auto-cleaned; use for all file I/O in tests
- `$TestDrive` — its real filesystem path, for .NET APIs that need absolute paths

```powershell
It 'writes the export file' {
    Export-Widget -Path (Join-Path $TestDrive 'out.json')
    Join-Path $TestDrive 'out.json' | Should -Exist
}
```

## PSScriptAnalyzer as a Test

```powershell
Describe 'Static analysis' {
    It 'has no PSScriptAnalyzer findings' {
        $findings = Invoke-ScriptAnalyzer -Path $PSScriptRoot/.. -Recurse -Settings PSGallery
        $findings | Out-String | Write-Host
        $findings | Should -BeNullOrEmpty
    }
}
```

For cross-platform Tier 1 code, use the compat settings file: `-Settings ./scripts/PSScriptAnalyzer.Tier1.psd1` (see [cross-platform.md](cross-platform.md)).