$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$skills = Join-Path $root "skills"

function Read-SkillText {
    param([Parameter(Mandatory = $true)][string]$RelativePath)
    return Get-Content -Raw -LiteralPath (Join-Path $skills $RelativePath)
}

Describe "Superpowers token budget policy" {
    It "caps automatic reasoning below ultra for every shared workflow" {
        $modelPolicyFiles = @(
            "brainstorming\SKILL.md",
            "writing-plans\SKILL.md",
            "subagent-driven-development\SKILL.md"
        )

        foreach ($relativePath in $modelPolicyFiles) {
            $content = Read-SkillText $relativePath
            $content | Should Match "reasoning effort is capped at high"
            $content | Should Not Match "frontier-planning|frontier-review"
            $content | Should Not Match "strongest available|best currently available|nearest stronger"
        }
    }

    It "limits new implementation plans to compact executable documents" {
        $content = Read-SkillText "writing-plans\SKILL.md"
        $content | Should Match "250 lines"
        $content | Should Match "task brief"
        $content | Should Not Match "Complete code in every step"
    }

    It "loads a full execution plan once and then uses durable compact state" {
        $executing = Read-SkillText "executing-plans\SKILL.md"
        $sdd = Read-SkillText "subagent-driven-development\SKILL.md"
        $verification = Read-SkillText "verification-before-completion\SKILL.md"

        $executing | Should Match "Read the plan file once"
        $executing | Should Match "Do not reopen the full plan"
        $sdd | Should Match "Read plan file once"
        $sdd | Should Match "Do not reopen the full plan"
        $verification | Should Match "durable checklist"
        $verification | Should Not Match "Re-read plan"
    }

    It "applies the same compact resume contract to Codex Claude and Gemini" {
        $codex = Read-SkillText "using-superpowers\references\codex-tools.md"
        $claude = Read-SkillText "using-superpowers\references\claude-tools.md"
        $gemini = Read-SkillText "using-superpowers\references\antigravity-tools.md"

        foreach ($content in @($codex, $claude, $gemini)) {
            $content | Should Match "Do\s+not re-read the full plan"
            $content | Should Match "compact"
        }
        $gemini | Should Not Match "before starting each step"
    }
}
