@{
    # Tier 1 compatibility settings: Windows PowerShell 5.1 + PowerShell 7 on all platforms.
    # Usage: Invoke-ScriptAnalyzer -Path .\script.ps1 -Settings <path-to-this-file>
    # For Tier 2 (PS 7+ only), remove PSUseCompatibleSyntax's '5.1' entry and the framework profile.
    Rules = @{
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.0')
        }
        PSUseCompatibleCommands = @{
            Enable         = $true
            TargetProfiles = @(
                'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework',
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
            )
        }
    }
}
