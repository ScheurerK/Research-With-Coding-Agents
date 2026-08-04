$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Get-AgentContextContract {
    param([Parameter(Mandatory = $true)][string]$Path)

    $content = Get-Content -Raw -LiteralPath $Path
    $match = [regex]::Match($content, '(?ms)^    ## Agent Context Contract\r?\n(?<body>.*?)(?=^    ## |\z)')
    if (-not $match.Success) {
        return $null
    }
    return $match.Groups["body"].Value.Trim()

    It "makes implementer subagent commits opt-in" {
        $content = Get-Content -Raw -LiteralPath $implementerPrompt
        $content | Should Match "subagent_commit_mode: per-task"
        $content | Should Match "Do not stage or commit unless"
        $content | Should Match "Commit action"
        $content | Should Not Match "Commit your work"
        $content | Should Not Match "Commits created"
    }

    It "documents controller-owned commits as the SDD default" {
        $content = Get-Content -Raw -LiteralPath (Join-Path $root "skills\subagent-driven-development\SKILL.md")
        $content | Should Match "Controller owns commits by default"
        $content | Should Match "Subagents do not stage or commit by default"
        $content | Should Match "subagent_commit_mode: per-task"
        $content | Should Match "research-checkpoint-commits"
    }

    It "keeps research checkpoint commits as the scientific commit owner" {
        $content = Get-Content -Raw -LiteralPath (Join-Path $root "skills\research-checkpoint-commits\SKILL.md")
        $content | Should Match "One primary Markplane TASK owns each scientific Git commit"
    }
}
function Count-Words {
    param([AllowEmptyString()][string]$Text)
    return @([regex]::Matches($Text, '\S+')).Count

    It "makes implementer subagent commits opt-in" {
        $content = Get-Content -Raw -LiteralPath $implementerPrompt
        $content | Should Match "subagent_commit_mode: per-task"
        $content | Should Match "Do not stage or commit unless"
        $content | Should Match "Commit action"
        $content | Should Not Match "Commit your work"
        $content | Should Not Match "Commits created"
    }

    It "documents controller-owned commits as the SDD default" {
        $content = Get-Content -Raw -LiteralPath (Join-Path $root "skills\subagent-driven-development\SKILL.md")
        $content | Should Match "Controller owns commits by default"
        $content | Should Match "Subagents do not stage or commit by default"
        $content | Should Match "subagent_commit_mode: per-task"
        $content | Should Match "research-checkpoint-commits"
    }

    It "keeps research checkpoint commits as the scientific commit owner" {
        $content = Get-Content -Raw -LiteralPath (Join-Path $root "skills\research-checkpoint-commits\SKILL.md")
        $content | Should Match "One primary Markplane TASK owns each scientific Git commit"
    }
}
Describe "Superpowers subagent Markplane contract" {
    $implementerPrompt = Join-Path $root "skills\subagent-driven-development\implementer-prompt.md"
    $reviewerPrompt = Join-Path $root "skills\subagent-driven-development\task-reviewer-prompt.md"
    $dispatchSkill = Join-Path $root "skills\dispatching-parallel-agents\SKILL.md"

    It "adds a compact contract to implementer subagents" {
        $contract = Get-AgentContextContract -Path $implementerPrompt
        $contract | Should Not BeNullOrEmpty
        Count-Words $contract | Should BeLessThan 120
        $contract | Should Match "Markplane"
        $contract | Should Match "AGENTS.md|CLAUDE.md"
        $contract | Should Match "TDD"
        $contract | Should Match "telemetry"
        $contract | Should Match "user changes"
    }

    It "adds a compact read-only contract to reviewer subagents" {
        $contract = Get-AgentContextContract -Path $reviewerPrompt
        $contract | Should Not BeNullOrEmpty
        Count-Words $contract | Should BeLessThan 120
        $contract | Should Match "Markplane"
        $contract | Should Match "read-only"
        $contract | Should Match "AGENTS.md|CLAUDE.md"
        $contract | Should Match "telemetry"
    }

    It "teaches parallel dispatch prompts to include the same contract" {
        $content = Get-Content -Raw -LiteralPath $dispatchSkill
        $content | Should Match "Agent Context Contract"
        $content | Should Match "Markplane"
        $content | Should Match "token"
    }

    It "requires implementer reports to identify subagent and model" {
        $content = Get-Content -Raw -LiteralPath $implementerPrompt
        $content | Should Match "\*\*Subagent:\*\* implementer"
        $content | Should Match "\*\*Model:\*\* \[MODEL\]"
    }

    It "requires reviewer reports to identify subagent and model" {
        $content = Get-Content -Raw -LiteralPath $reviewerPrompt
        $content | Should Match "\*\*Subagent:\*\* reviewer"
        $content | Should Match "\*\*Model:\*\* \[MODEL\]"
    }

    It "teaches parallel dispatch reports to identify subagent and model" {
        $content = Get-Content -Raw -LiteralPath $dispatchSkill
        $content | Should Match "Return includes Subagent \+ Model"
    }

    It "defines agent-agnostic model tiers for planning and implementation" {
        $content = Get-Content -Raw -LiteralPath (Join-Path $root "skills\subagent-driven-development\SKILL.md")
        $content | Should Match "high-reasoning"
        $content | Should Match "standard-implementation"
        $content | Should Match "cheap-mechanical"
        $content | Should Match "reasoning effort is capped at high"
        $content | Should Match "Do not hard-code provider-specific model names"
    }

    It "requires dispatch templates to include tier and concrete model" {
        $implementer = Get-Content -Raw -LiteralPath $implementerPrompt
        $reviewer = Get-Content -Raw -LiteralPath $reviewerPrompt
        $implementer | Should Match "model_tier: \[MODEL_TIER\]"
        $reviewer | Should Match "model_tier: \[MODEL_TIER\]"
        $implementer | Should Match "\*\*Model tier:\*\* \[MODEL_TIER\]"
        $reviewer | Should Match "\*\*Model tier:\*\* \[MODEL_TIER\]"
    }

    It "teaches parallel dispatch reports to include model tier metadata" {
        $content = Get-Content -Raw -LiteralPath $dispatchSkill
        $content | Should Match "Model tier"
        $content | Should Match "model_tier"
    }

    It "caps brainstorming and plan writing reasoning without model names" {
        $brainstorming = Get-Content -Raw -LiteralPath (Join-Path $root "skills\brainstorming\SKILL.md")
        $writingPlans = Get-Content -Raw -LiteralPath (Join-Path $root "skills\writing-plans\SKILL.md")
        foreach ($content in @($brainstorming, $writingPlans)) {
            $content | Should Match "reasoning effort is capped at high"
            $content | Should Match "standard model"
            $content | Should Not Match "gpt-[0-9]"
            $content | Should Not Match "claude-[0-9]"
        }
    }

    It "makes implementer subagent commits opt-in" {
        $content = Get-Content -Raw -LiteralPath $implementerPrompt
        $content | Should Match "subagent_commit_mode: per-task"
        $content | Should Match "Do not stage or commit unless"
        $content | Should Match "Commit action"
        $content | Should Not Match "Commit your work"
        $content | Should Not Match "Commits created"
    }

    It "documents controller-owned commits as the SDD default" {
        $content = Get-Content -Raw -LiteralPath (Join-Path $root "skills\subagent-driven-development\SKILL.md")
        $content | Should Match "Controller owns commits by default"
        $content | Should Match "Subagents do not stage or commit by default"
        $content | Should Match "subagent_commit_mode: per-task"
        $content | Should Match "research-checkpoint-commits"
    }

    It "keeps research checkpoint commits as the scientific commit owner" {
        $content = Get-Content -Raw -LiteralPath (Join-Path $root "skills\research-checkpoint-commits\SKILL.md")
        $content | Should Match "One primary Markplane TASK owns each scientific Git commit"
    }
}
