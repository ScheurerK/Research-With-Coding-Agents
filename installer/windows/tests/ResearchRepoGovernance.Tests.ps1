$root = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent $root)
$skills = Join-Path $repoRoot "components\superpowers\skills"
$skill = Join-Path $skills "research-repo-governance\SKILL.md"
$fullGovernance = Join-Path $skills "research-repo-governance\references\full-governance.md"

Describe "Research repo governance agent-context preservation" {
    It "treats repo-specific AGENTS and CLAUDE files as additive local deltas" {
        $content = Get-Content -Raw -LiteralPath $fullGovernance

        $content | Should Match "additive local deltas"
        $content | Should Match "not replacements for global agent instructions"
        $content | Should Match 'using-superpowers'
        $content | Should Match 'Do not weaken, remove, or contradict globally installed Markplane/Superpowers/router/privacy rules'
    }

    It "requires generated CLAUDE companions to preserve the global bootstrap" {
        $content = Get-Content -Raw -LiteralPath $fullGovernance

        $content | Should Match 'Global bootstrap remains authoritative'
        $content | Should Match 'main agents load `using-superpowers` before actions'
        $content | Should Match 'only adds repository-specific rules'
    }

    It "keeps the quick skill file explicit about global bootstrap precedence" {
        $content = Get-Content -Raw -LiteralPath $skill

        $content | Should Match 'Repo-specific `AGENTS.md`/`CLAUDE.md` files are additive'
        $content | Should Match 'must not weaken global `using-superpowers`'
    }
}