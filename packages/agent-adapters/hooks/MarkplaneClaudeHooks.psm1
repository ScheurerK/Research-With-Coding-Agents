Set-StrictMode -Version 2.0

$script:MutatingMcpTools = @(
    "markplane_add",
    "markplane_archive",
    "markplane_link",
    "markplane_move",
    "markplane_plan",
    "markplane_promote",
    "markplane_sync",
    "markplane_unarchive",
    "markplane_update"
)

function Find-MarkplaneProjectRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$StartPath
    )

    if ([string]::IsNullOrWhiteSpace($StartPath)) {
        return $null
    }

    try {
        $candidate = $StartPath
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $candidate = Split-Path -Parent $candidate
        }
        if (-not (Test-Path -LiteralPath $candidate -PathType Container)) {
            return $null
        }

        $directory = (Resolve-Path -LiteralPath $candidate).Path
        while ($directory) {
            if (Test-Path -LiteralPath (Join-Path $directory ".markplane") -PathType Container) {
                return $directory
            }
            $parent = Split-Path -Parent $directory
            if ($parent -eq $directory) {
                break
            }
            $directory = $parent
        }
    } catch {
        return $null
    }

    return $null
}

function ConvertTo-MarkplaneHookJson {
    param([Parameter(Mandatory = $true)]$Value)
    return ($Value | ConvertTo-Json -Depth 30 -Compress)
}

function Get-MarkplaneProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Resolve-MarkplaneToolPath {
    param(
        [Parameter(Mandatory = $true)]$InputObject,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $toolInput = Get-MarkplaneProperty -Object $InputObject -Name "tool_input"
    if ($null -eq $toolInput) {
        return $null
    }

    foreach ($name in @("file_path", "path", "notebook_path", "TargetFile", "targetFile", "AbsolutePath", "absolutePath")) {
        $value = Get-MarkplaneProperty -Object $toolInput -Name $name
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            if ([System.IO.Path]::IsPathRooted($value)) {
                return [System.IO.Path]::GetFullPath($value)
            }
            return [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $value))
        }
    }

    return $null
}

function Test-MarkplanePathInside {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Container
    )

    try {
        $fullPath = [System.IO.Path]::GetFullPath($Path).TrimEnd("\", "/")
        $fullContainer = [System.IO.Path]::GetFullPath($Container).TrimEnd("\", "/")
        return ($fullPath -ieq $fullContainer) -or $fullPath.StartsWith($fullContainer + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
    } catch {
        return $false
    }
}

function Test-MarkplaneRelevantPostToolUse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$InputObject,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $toolName = [string](Get-MarkplaneProperty -Object $InputObject -Name "tool_name")
    if ([string]::IsNullOrWhiteSpace($toolName)) {
        return $false
    }

    if ($toolName -match '^mcp__markplane__(.+)$') {
        return ($script:MutatingMcpTools -icontains $Matches[1])
    }

    if ($toolName -in @("Edit", "Write", "MultiEdit", "write_to_file", "replace_file_content", "multi_replace_file_content")) {
        $path = Resolve-MarkplaneToolPath -InputObject $InputObject -ProjectRoot $ProjectRoot
        if ($path) {
            return (Test-MarkplanePathInside -Path $path -Container (Join-Path $ProjectRoot ".markplane")) -or
                (Test-MarkplanePathInside -Path $path -Container (Join-Path $ProjectRoot "docs\superpowers\plans"))
        }
    }

    if ($toolName -in @("Bash", "Shell", "PowerShell", "shell_command", "exec_command", "run_command")) {
        $toolInput = Get-MarkplaneProperty -Object $InputObject -Name "tool_input"
        $command = [string](Get-MarkplaneProperty -Object $toolInput -Name "command")
        if ([string]::IsNullOrWhiteSpace($command)) {
            $command = [string](Get-MarkplaneProperty -Object $toolInput -Name "CommandLine")
        }
        if ($command -match '(?i)(^|\s|\\|/|")markplane(\.exe)?(\s|")') {
            return ($command -match '(?i)\s(add|archive|link|move|plan|promote|sync|unarchive|update|init)\b')
        }
        return ($command -match '(?i)(^|[\\/])\.markplane([\\/]|$)')
    }

    if ($toolName -eq "apply_patch") {
        $toolInput = Get-MarkplaneProperty -Object $InputObject -Name "tool_input"
        $patch = [string](Get-MarkplaneProperty -Object $toolInput -Name "patch")
        if ([string]::IsNullOrWhiteSpace($patch)) {
            $patch = [string](Get-MarkplaneProperty -Object $toolInput -Name "input")
        }
        $normalizedPatch = $patch -replace "\\", "/"
        return ($normalizedPatch -match '(?i)(^|\s)(\.markplane/|docs/superpowers/plans/)')
    }

    return $false
}

function Limit-MarkplaneContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [int]$MaxCharacters = 6000
    )

    if ($MaxCharacters -lt 64 -or $Text.Length -le $MaxCharacters) {
        return $Text
    }

    $suffix = "`n`n[Markplane context truncated to $MaxCharacters characters.]"
    $take = [Math]::Max(0, $MaxCharacters - $suffix.Length)
    if ($take -gt $Text.Length) {
        $take = $Text.Length
    }
    if ($take -gt 0 -and [char]::IsHighSurrogate($Text[$take - 1])) {
        $take--
    }

    return $Text.Substring(0, $take) + $suffix
}

function Get-MarkplaneStableHash {
    param([Parameter(Mandatory = $true)][string]$Text)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text.ToLowerInvariant())
        $hash = $sha.ComputeHash($bytes)
        return ([BitConverter]::ToString($hash) -replace "-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Get-MarkplaneSessionStatePath {
    param(
        [Parameter(Mandatory = $true)][string]$SessionId,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$StateRoot
    )

    $safeSession = ($SessionId -replace '[^A-Za-z0-9_.-]', '_')
    if ([string]::IsNullOrWhiteSpace($safeSession)) {
        $safeSession = "unknown"
    }
    $hash = Get-MarkplaneStableHash -Text $ProjectRoot
    return (Join-Path $StateRoot "$safeSession-$hash.json")
}

function Read-MarkplaneUtf8NoBom {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
}

function Write-MarkplaneUtf8NoBomAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }
    $temp = Join-Path $directory ([System.IO.Path]::GetRandomFileName())
    [System.IO.File]::WriteAllText($temp, $Text, [System.Text.UTF8Encoding]::new($false))
    if (Test-Path -LiteralPath $Path) {
        Move-Item -LiteralPath $temp -Destination $Path -Force
    } else {
        Move-Item -LiteralPath $temp -Destination $Path
    }
}

function Get-MarkplaneHookState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SessionId,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$StateRoot
    )

    $path = Get-MarkplaneSessionStatePath -SessionId $SessionId -ProjectRoot $ProjectRoot -StateRoot $StateRoot
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return [pscustomobject]@{ dirty = $false; retryUsed = $false; projectRoot = $ProjectRoot }
    }

    try {
        return (Read-MarkplaneUtf8NoBom -Path $path | ConvertFrom-Json)
    } catch {
        return [pscustomobject]@{ dirty = $false; retryUsed = $false; projectRoot = $ProjectRoot }
    }
}

function Set-MarkplaneHookState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SessionId,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$StateRoot,
        [bool]$Dirty,
        [bool]$RetryUsed
    )

    $path = Get-MarkplaneSessionStatePath -SessionId $SessionId -ProjectRoot $ProjectRoot -StateRoot $StateRoot
    $state = [ordered]@{
        dirty = $Dirty
        retryUsed = $RetryUsed
        projectRoot = $ProjectRoot
        updatedAt = [DateTimeOffset]::UtcNow.ToString("o")
    }
    Write-MarkplaneUtf8NoBomAtomic -Path $path -Text ($state | ConvertTo-Json -Depth 10)
}

function Remove-MarkplaneHookState {
    param(
        [Parameter(Mandatory = $true)][string]$SessionId,
        [Parameter(Mandatory = $true)][string]$StateRoot
    )

    if (-not (Test-Path -LiteralPath $StateRoot -PathType Container)) {
        return
    }

    $safeSession = ($SessionId -replace '[^A-Za-z0-9_.-]', '_')
    if ([string]::IsNullOrWhiteSpace($safeSession)) {
        $safeSession = "unknown"
    }
    Get-ChildItem -LiteralPath $StateRoot -Filter "$safeSession-*.json" -File -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
    }
}

function ConvertTo-MarkplaneProcessArgument {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Argument)

    if ($Argument -notmatch '[\s"]') {
        return $Argument
    }

    return '"' + (($Argument -replace '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"'
}

function Invoke-MarkplaneCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory
    )

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $Executable
    $startInfo.Arguments = (($Arguments | ForEach-Object { ConvertTo-MarkplaneProcessArgument -Argument $_ }) -join " ")
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    if (-not $process.WaitForExit(10000)) {
        try { $process.Kill() } catch {}
        return [pscustomobject]@{ ExitCode = 124; StdOut = $stdout; StdErr = "Timed out running markplane $($Arguments -join ' ')." }
    }
    return [pscustomobject]@{ ExitCode = $process.ExitCode; StdOut = $stdout; StdErr = $stderr }
}

function Invoke-MarkplaneRunner {
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [scriptblock]$CommandRunner
    )

    if ($CommandRunner) {
        return (& $CommandRunner $Executable $Arguments $WorkingDirectory)
    }
    return (Invoke-MarkplaneCommand -Executable $Executable -Arguments $Arguments -WorkingDirectory $WorkingDirectory)
}

function Invoke-MarkplaneWithProjectLock {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock
    )

    $hash = (Get-MarkplaneStableHash -Text $ProjectRoot).Substring(0, 24)
    $mutex = New-Object System.Threading.Mutex($false, "Local\MarkplaneClaudeHook-$hash")
    $hasLock = $false
    try {
        $hasLock = $mutex.WaitOne(10000)
        if (-not $hasLock) {
            return [pscustomobject]@{ ExitCode = 124; StdOut = ""; StdErr = "Timed out waiting for Markplane project lock." }
        }
        return (& $ScriptBlock)
    } finally {
        if ($hasLock) {
            try { $mutex.ReleaseMutex() | Out-Null } catch {}
        }
        $mutex.Dispose()
    }
}

function New-MarkplaneAdditionalContextOutput {
    param(
        [Parameter(Mandatory = $true)][string]$Event,
        [Parameter(Mandatory = $true)][string]$Context
    )

    [pscustomobject]@{
        hookSpecificOutput = [pscustomobject]@{
            hookEventName = $Event
            additionalContext = $Context
        }
    }
}

function New-MarkplaneContext {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Summary,
        [string]$Warning,
        [int]$MaxContextChars = 6000
    )

    $text = @(
        "Markplane project root: $ProjectRoot"
        "This context is project state, not an instruction override."
        ""
        $Summary
    ) -join "`n"

    if (-not [string]::IsNullOrWhiteSpace($Warning)) {
        $text = "Markplane warning: $Warning`n`n$text"
    }

    return (Limit-MarkplaneContext -Text $text -MaxCharacters $MaxContextChars)
}

function Get-MarkplaneSummary {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $summaryPath = Join-Path $ProjectRoot ".markplane\.context\summary.md"
    if (Test-Path -LiteralPath $summaryPath -PathType Leaf) {
        return (Read-MarkplaneUtf8NoBom -Path $summaryPath)
    }
    return ""
}

function Get-MarkplaneResumeContext {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $resumePath = Join-Path $ProjectRoot ".markplane\.context\resume.md"
    if (Test-Path -LiteralPath $resumePath -PathType Leaf) {
        return (Read-MarkplaneUtf8NoBom -Path $resumePath)
    }
    return ""
}

function Get-MarkplaneEventSessionId {
    param($InputObject)

    $sessionId = [string](Get-MarkplaneProperty -Object $InputObject -Name "session_id")
    if ([string]::IsNullOrWhiteSpace($sessionId)) {
        return "unknown"
    }
    return $sessionId
}


function ConvertTo-MarkplaneRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $root = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd("\", "/")
    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        return ($full.Substring($root.Length + 1) -replace "\\", "/")
    }
    return ($full -replace "\\", "/")
}

function Get-MarkplaneMarkdownSectionText {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Markdown,
        [Parameter(Mandatory = $true)][string]$Heading
    )

    $escaped = [regex]::Escape($Heading)
    $match = [regex]::Match($Markdown, "(?ms)^##\s+$escaped\s*\r?\n(.*?)(?=^##\s+|\z)")
    if (-not $match.Success) {
        return $null
    }
    return $match.Groups[1].Value.Trim()
}

function Test-MarkplanePlaceholderText {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $true
    }

    return ($Text -match '(?im)\[(what|source|observable|reference|detailed|content|key|recommended|measurable|strategic|environment|implementation|how|why|which|placeholder|tbd|todo|fill|criterion|step)[^\]]*\]' -or
        $Text -match '(?im)^\s*- \[ \]\s*Criterion \d+\s*$' -or
        $Text -match '(?im)^\s*\d+\.\s*Step \d+\s*$' -or
        $Text -match '(?im)\b(TBD|TODO|fill in|Content goes here)\b')
}

function Test-MarkplaneChecklistHasConcreteItem {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    foreach ($line in ($Text -split "\r?\n")) {
        if ($line -match '^\s*- \[[ xX]\]\s+(.+?)\s*$') {
            $label = $Matches[1]
            if (-not (Test-MarkplanePlaceholderText -Text $label)) {
                return $true
            }
        }
    }
    return $false
}

function Get-MarkplaneFrontmatterValue {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Markdown,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $match = [regex]::Match($Markdown, "(?m)^$([regex]::Escape($Name)):\s*['\""""']?([^'\""""\r\n]+)")
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }
    return ""
}

function Test-MarkplaneItemQuality {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Kind,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $issues = @()
    $content = Read-MarkplaneUtf8NoBom -Path $Path
    $id = Get-MarkplaneFrontmatterValue -Markdown $content -Name "id"
    if ([string]::IsNullOrWhiteSpace($id)) {
        $id = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    }
    $status = (Get-MarkplaneFrontmatterValue -Markdown $content -Name "status").ToLowerInvariant()
    $relative = ConvertTo-MarkplaneRelativePath -ProjectRoot $ProjectRoot -Path $Path

    if (Test-MarkplanePlaceholderText -Text $content) {
        $issues += "$id ($relative): contains placeholder text."
    }

    if ($Kind -eq "task") {
        if ($status -in @("planned", "in-progress")) {
            $description = Get-MarkplaneMarkdownSectionText -Markdown $content -Heading "Description"
            if (Test-MarkplanePlaceholderText -Text $description) {
                $issues += "$id ($relative): planned/in-progress task needs a concrete Description."
            }
            $criteria = Get-MarkplaneMarkdownSectionText -Markdown $content -Heading "Acceptance Criteria"
            if (-not (Test-MarkplaneChecklistHasConcreteItem -Text $criteria)) {
                $issues += "$id ($relative): planned/in-progress task needs concrete Acceptance Criteria."
            }
            $validation = Get-MarkplaneMarkdownSectionText -Markdown $content -Heading "Validation Plan"
            if ($null -ne $validation -and (Test-MarkplanePlaceholderText -Text $validation)) {
                $issues += "$id ($relative): Validation Plan exists but is still empty or placeholder text."
            }
        }
    }

    if ($Kind -eq "plan") {
        if ($status -notin @("draft", "")) {
            foreach ($heading in @("Ground Truth", "Testing Strategy")) {
                $section = Get-MarkplaneMarkdownSectionText -Markdown $content -Heading $heading
                if (Test-MarkplanePlaceholderText -Text $section) {
                    $issues += "$id ($relative): plan needs a concrete $heading section."
                }
            }
            $approach = Get-MarkplaneMarkdownSectionText -Markdown $content -Heading "Approach"
            $target = Get-MarkplaneMarkdownSectionText -Markdown $content -Heading "Target State"
            if ((Test-MarkplanePlaceholderText -Text $approach) -and (Test-MarkplanePlaceholderText -Text $target)) {
                $issues += "$id ($relative): plan needs a concrete Approach or Target State."
            }
            $implementsValue = Get-MarkplaneFrontmatterValue -Markdown $content -Name "implements"
            if ([string]::IsNullOrWhiteSpace($implementsValue) -or $implementsValue -eq "[]") {
                $issues += "$id ($relative): plan does not implement any task - orphaned from the graph."
            }
        }
    }

    return @($issues)
}

function Test-MarkplaneGraphConnectivity {
    <#
    .SYNOPSIS
    Cross-references Epics against the tasks that link to them, so Epics
    that exist but were never wired to any task's `epic:` field (islands
    in the graph view) are caught before Stop, alongside a non-blocking
    nudge for tasks that could be linked to an existing Epic but aren't.
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $issues = @()
    $warnings = @()

    $taskDir = Join-Path $ProjectRoot ".markplane\backlog\items"
    $referencedEpics = @{}
    $orphanTasks = @()
    if (Test-Path -LiteralPath $taskDir -PathType Container) {
        foreach ($file in Get-ChildItem -LiteralPath $taskDir -Filter "TASK-*.md" -File -ErrorAction SilentlyContinue) {
            $content = Read-MarkplaneUtf8NoBom -Path $file.FullName
            $id = Get-MarkplaneFrontmatterValue -Markdown $content -Name "id"
            if ([string]::IsNullOrWhiteSpace($id)) {
                $id = [System.IO.Path]::GetFileNameWithoutExtension($file.FullName)
            }
            $epicId = Get-MarkplaneFrontmatterValue -Markdown $content -Name "epic"
            if (-not [string]::IsNullOrWhiteSpace($epicId) -and $epicId -ne "null") {
                $referencedEpics[$epicId] = $true
            }
            else {
                $orphanTasks += $id
            }
        }
    }

    $epicDir = Join-Path $ProjectRoot "roadmap\items"
    $anyEpicExists = $false
    if (Test-Path -LiteralPath $epicDir -PathType Container) {
        $epicFiles = @(Get-ChildItem -LiteralPath $epicDir -Filter "EPIC-*.md" -File -ErrorAction SilentlyContinue)
        $anyEpicExists = $epicFiles.Count -gt 0
        foreach ($file in $epicFiles) {
            $content = Read-MarkplaneUtf8NoBom -Path $file.FullName
            $id = Get-MarkplaneFrontmatterValue -Markdown $content -Name "id"
            if ([string]::IsNullOrWhiteSpace($id)) {
                $id = [System.IO.Path]::GetFileNameWithoutExtension($file.FullName)
            }
            $relative = ConvertTo-MarkplaneRelativePath -ProjectRoot $ProjectRoot -Path $file.FullName
            if (-not $referencedEpics.ContainsKey($id)) {
                $issues += "$id ($relative): epic has no tasks linked via 'epic:' - orphaned from the graph."
            }
        }
    }

    if ($anyEpicExists -and $orphanTasks.Count -gt 0) {
        $warnings += "$($orphanTasks.Count) task(s) not linked to any Epic via 'epic:' ($($orphanTasks -join ', ')) - consider linking for graph visibility."
    }

    return [pscustomobject]@{ Issues = @($issues); Warnings = @($warnings) }
}

function Test-MarkplaneSuperpowersPlanLinks {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $issues = @()
    $superpowersDir = Join-Path $ProjectRoot "docs\superpowers\plans"
    if (-not (Test-Path -LiteralPath $superpowersDir -PathType Container)) {
        return @()
    }

    $markplanePlansDir = Join-Path $ProjectRoot ".markplane\plans\items"
    $planText = ""
    if (Test-Path -LiteralPath $markplanePlansDir -PathType Container) {
        foreach ($plan in Get-ChildItem -LiteralPath $markplanePlansDir -Filter "PLAN-*.md" -File -ErrorAction SilentlyContinue) {
            $planText += "`n" + (Read-MarkplaneUtf8NoBom -Path $plan.FullName)
        }
    }

    foreach ($file in Get-ChildItem -LiteralPath $superpowersDir -Filter "*.md" -File -ErrorAction SilentlyContinue) {
        $relative = ConvertTo-MarkplaneRelativePath -ProjectRoot $ProjectRoot -Path $file.FullName
        $normalizedPlanText = $planText -replace "\\", "/"
        if ($normalizedPlanText -notmatch [regex]::Escape($relative) -and $normalizedPlanText -notmatch [regex]::Escape($file.Name)) {
            $issues += "Superpowers plan is not linked from any Markplane PLAN: $relative"
        }
    }

    return @($issues)
}

function Test-MarkplaneProjectQuality {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $issues = @()
    $taskDir = Join-Path $ProjectRoot ".markplane\backlog\items"
    if (Test-Path -LiteralPath $taskDir -PathType Container) {
        foreach ($file in Get-ChildItem -LiteralPath $taskDir -Filter "TASK-*.md" -File -ErrorAction SilentlyContinue) {
            $issues += @(Test-MarkplaneItemQuality -Path $file.FullName -Kind "task" -ProjectRoot $ProjectRoot)
        }
    }

    $planDir = Join-Path $ProjectRoot ".markplane\plans\items"
    if (Test-Path -LiteralPath $planDir -PathType Container) {
        foreach ($file in Get-ChildItem -LiteralPath $planDir -Filter "PLAN-*.md" -File -ErrorAction SilentlyContinue) {
            $issues += @(Test-MarkplaneItemQuality -Path $file.FullName -Kind "plan" -ProjectRoot $ProjectRoot)
        }
    }

    $issues += @(Test-MarkplaneSuperpowersPlanLinks -ProjectRoot $ProjectRoot)

    $warnings = @()
    $connectivity = Test-MarkplaneGraphConnectivity -ProjectRoot $ProjectRoot
    $issues += @($connectivity.Issues)
    $warnings += @($connectivity.Warnings)

    if ($issues.Count -eq 0) {
        $stdout = "Markplane quality check passed."
        if ($warnings.Count -gt 0) {
            $stdout += "`nMarkplane quality warnings (non-blocking):`n- " + ($warnings -join "`n- ")
        }
        return [pscustomobject]@{ ExitCode = 0; StdOut = $stdout; StdErr = "" }
    }

    $stdout = "Markplane quality check failed:`n- " + ($issues -join "`n- ")
    if ($warnings.Count -gt 0) {
        $stdout += "`nMarkplane quality warnings (non-blocking):`n- " + ($warnings -join "`n- ")
    }
    return [pscustomobject]@{ ExitCode = 1; StdOut = $stdout; StdErr = "" }
}

function Merge-MarkplaneCheckResults {
    param([Parameter(Mandatory = $true)]$Results)

    $failures = @($Results | Where-Object { $_.ExitCode -ne 0 })
    if ($failures.Count -eq 0) {
        return [pscustomobject]@{ ExitCode = 0; StdOut = (($Results | ForEach-Object { $_.StdOut } | Where-Object { $_ }) -join "`n"); StdErr = "" }
    }

    return [pscustomobject]@{
        ExitCode = 1
        StdOut = (($failures | ForEach-Object { $_.StdOut } | Where-Object { $_ }) -join "`n")
        StdErr = (($failures | ForEach-Object { $_.StdErr } | Where-Object { $_ }) -join "`n")
    }
}
function Invoke-MarkplaneClaudeHookEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("SessionStart", "PostToolUse", "SubagentStart", "Stop", "SessionEnd")]
        [string]$Event,

        [Parameter(Mandatory = $true)]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [string]$MarkplaneExe,

        [int]$MaxContextChars = 6000,

        [string]$StateRoot = (Join-Path $env:LOCALAPPDATA "Markplane\claude-hooks\sessions"),

        [scriptblock]$CommandRunner
    )

    $sessionId = Get-MarkplaneEventSessionId -InputObject $InputObject
    if ($Event -eq "SessionEnd") {
        Remove-MarkplaneHookState -SessionId $sessionId -StateRoot $StateRoot
        return $null
    }

    $cwd = [string](Get-MarkplaneProperty -Object $InputObject -Name "cwd")
    if ([string]::IsNullOrWhiteSpace($cwd)) {
        $cwd = (Get-Location).Path
    }

    $projectRoot = Find-MarkplaneProjectRoot -StartPath $cwd
    if (-not $projectRoot) {
        return $null
    }

    if ($Event -eq "SessionStart") {
        $sync = Invoke-MarkplaneWithProjectLock -ProjectRoot $projectRoot -ScriptBlock {
            Invoke-MarkplaneRunner -Executable $MarkplaneExe -Arguments @("sync") -WorkingDirectory $projectRoot -CommandRunner $CommandRunner
        }
        Set-MarkplaneHookState -SessionId $sessionId -ProjectRoot $projectRoot -StateRoot $StateRoot -Dirty $false -RetryUsed $false
        $warning = $null
        if ($sync.ExitCode -ne 0) {
            $warning = (($sync.StdErr, $sync.StdOut | Where-Object { $_ }) -join "`n")
        }

        $source = [string](Get-MarkplaneProperty -Object $InputObject -Name "source")
        if ($source -eq "compact") {
            $context = New-MarkplaneContext -ProjectRoot $projectRoot -Summary (Get-MarkplaneResumeContext -ProjectRoot $projectRoot) -Warning $warning -MaxContextChars ([Math]::Min($MaxContextChars, 2000))
        } else {
            $context = New-MarkplaneContext -ProjectRoot $projectRoot -Summary (Get-MarkplaneSummary -ProjectRoot $projectRoot) -Warning $warning -MaxContextChars $MaxContextChars
        }
        return (New-MarkplaneAdditionalContextOutput -Event "SessionStart" -Context $context)
    }

    if ($Event -eq "SubagentStart") {
        $context = @(
            "Markplane project root: $projectRoot"
            "Read order: .markplane/.context/summary.md, then relevant task/plan/note files."
            "Superpowers plans in docs/superpowers/plans must be linked or summarized in Markplane PLAN items."
            "Graph contract: group related tasks under an Epic ('epic:' field), give multi-task work a PLAN ('implements:'), and record decisions/research as a NOTE ('related:') - Stop blocks on orphaned Epics/Plans."
            "Governance: preserve raw data, generated results, notebooks, and scoped AGENTS/CLAUDE rules."
        ) -join "`n"
        $context = Limit-MarkplaneContext -Text $context -MaxCharacters ([Math]::Min($MaxContextChars, 800))
        return (New-MarkplaneAdditionalContextOutput -Event "SubagentStart" -Context $context)
    }

    if ($Event -eq "PostToolUse") {
        if (-not (Test-MarkplaneRelevantPostToolUse -InputObject $InputObject -ProjectRoot $projectRoot)) {
            return $null
        }

        $sync = Invoke-MarkplaneWithProjectLock -ProjectRoot $projectRoot -ScriptBlock {
            Invoke-MarkplaneRunner -Executable $MarkplaneExe -Arguments @("sync") -WorkingDirectory $projectRoot -CommandRunner $CommandRunner
        }
        Set-MarkplaneHookState -SessionId $sessionId -ProjectRoot $projectRoot -StateRoot $StateRoot -Dirty $true -RetryUsed $false
        if ($sync.ExitCode -ne 0) {
            $message = Limit-MarkplaneContext -Text (($sync.StdErr, $sync.StdOut | Where-Object { $_ }) -join "`n") -MaxCharacters 1600
            return (New-MarkplaneAdditionalContextOutput -Event "PostToolUse" -Context "Markplane sync failed after a Markplane change.`n$message")
        }
        return $null
    }

    if ($Event -eq "Stop") {
        $state = Get-MarkplaneHookState -SessionId $sessionId -ProjectRoot $projectRoot -StateRoot $StateRoot
        if (-not [bool]$state.dirty) {
            return $null
        }

        $backgroundTasks = Get-MarkplaneProperty -Object $InputObject -Name "background_tasks"
        if ($backgroundTasks -and @($backgroundTasks).Count -gt 0) {
            return $null
        }

        $sync = Invoke-MarkplaneWithProjectLock -ProjectRoot $projectRoot -ScriptBlock {
            Invoke-MarkplaneRunner -Executable $MarkplaneExe -Arguments @("sync") -WorkingDirectory $projectRoot -CommandRunner $CommandRunner
        }
        if ($sync.ExitCode -eq 0) {
            $check = Invoke-MarkplaneWithProjectLock -ProjectRoot $projectRoot -ScriptBlock {
                $consistency = Invoke-MarkplaneRunner -Executable $MarkplaneExe -Arguments @("check") -WorkingDirectory $projectRoot -CommandRunner $CommandRunner
                $quality = Test-MarkplaneProjectQuality -ProjectRoot $projectRoot
                Merge-MarkplaneCheckResults -Results @($consistency, $quality)
            }
        } else {
            $check = $sync
        }

        if ($check.ExitCode -eq 0) {
            Set-MarkplaneHookState -SessionId $sessionId -ProjectRoot $projectRoot -StateRoot $StateRoot -Dirty $false -RetryUsed $false
            return $null
        }

        $diagnostic = Limit-MarkplaneContext -Text (($check.StdErr, $check.StdOut | Where-Object { $_ }) -join "`n") -MaxCharacters 2200
        if (-not [bool]$state.retryUsed) {
            Set-MarkplaneHookState -SessionId $sessionId -ProjectRoot $projectRoot -StateRoot $StateRoot -Dirty $true -RetryUsed $true
            return (New-MarkplaneAdditionalContextOutput -Event "Stop" -Context "Markplane consistency check failed. Fix the issue once, then stop again.`n$diagnostic")
        }

        Set-MarkplaneHookState -SessionId $sessionId -ProjectRoot $projectRoot -StateRoot $StateRoot -Dirty $false -RetryUsed $true
        return [pscustomobject]@{
            systemMessage = "Markplane consistency check still failed after one correction attempt.`n$diagnostic"
        }
    }

    return $null
}

Export-ModuleMember -Function Find-MarkplaneProjectRoot, Test-MarkplaneRelevantPostToolUse, Limit-MarkplaneContext, Invoke-MarkplaneClaudeHookEvent, Get-MarkplaneHookState, Set-MarkplaneHookState, Test-MarkplaneProjectQuality, Test-MarkplaneGraphConnectivity
