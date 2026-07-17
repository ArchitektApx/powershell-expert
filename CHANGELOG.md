# Changelog

All notable changes to the powershell-expert skill are documented in this file.

## [1.2.0] - 2026-07-18

### Added
- Cross-platform reference (`cross-platform.md`): PS 5.1 + 7 compatibility tiers, path handling, encoding matrix, platform detection, cmdlet availability, Windows PowerShell compatibility layer, shebang usage
- Compatibility tier policy in SKILL.md: PowerShell 7 on all platforms as baseline, 5.1 support by default, dropped only with concrete reason
- Style guide reference (`style-guide.md`): PoshCode community standard — brace style, indentation, capitalization, readability, comments, comment-based help
- Testing reference (`testing.md`): Pester 5 discovery/run model, assertions, mocking, data-driven tests, TestDrive, PSScriptAnalyzer as test
- `PSScriptAnalyzer.Tier1.psd1`: ready-made compat lint settings (5.1 + 7)
- Best practices: performance, security, language pitfalls, tools-vs-controllers sections; function structure and error handling core rules
- "Non-negotiables" quick list in SKILL.md workflow

### Changed
- Best practices reference restructured; style content moved to `style-guide.md`
- Examples fixed to follow the skill's own rules (no built-in shadowing, implicit output, approved verbs, no plaintext secrets)
- GUI section marked Windows-only with cross-platform alternatives
- `powershellget.md`: `Ensure-Module` renamed to `Install-RequiredModule` (approved verb), corrected `-IncludeXml` description, secret-vault API key example
- README: cross-platform badge, tier table, updated features and contents tree

## [1.1.0] - 2026-04-12

### Changed
- Module Recommendations table now requires verification via Live Verification workflow before recommending
- Documentation Resources URLs replaced with raw GitHub markdown equivalents for direct WebFetch parsing
- PSResourceGet docs link updated to raw `MicrosoftDocs/powershell-docs-psget` repository URL
- Gallery Status link (`aka.ms/psgallery-status`) replaced with raw GitHub URL to eliminate redirect
- Gallery Issues link (`aka.ms/psgallery-issues`) replaced with direct GitHub Issues URL

### Added
- Raw GitHub URL pattern for PSResourceGet cmdlet docs in Live Verification Step 2
- Raw PSResourceGet docs URL in `powershellget.md` useful links

## [1.0.0] - 2026-04-11

### Added
- Initial skill with SKILL.md, references, and scripts
- Best practices reference (naming, parameters, pipeline, error handling)
- GUI development reference (Windows Forms, WPF, controls, templates)
- PowerShellGet & Gallery reference (PSResourceGet cmdlets)
- Search-Gallery.ps1 helper script
- Live verification workflow with WebFetch/WebSearch tool instructions
- Fallback strategies for offline verification
