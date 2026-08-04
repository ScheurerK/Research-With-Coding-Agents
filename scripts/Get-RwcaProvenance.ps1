function Get-RwcaProvenance {
    [CmdletBinding()]
    param(
        [string]$RepoRoot = (Get-Location).Path
    )

    $noticesPath = Join-Path $RepoRoot "THIRD_PARTY_NOTICES.md"
    if (-not (Test-Path -LiteralPath $noticesPath -PathType Leaf)) {
        throw "Third-party notices file not found: $noticesPath"
    }

    $rows = Get-Content -LiteralPath $noticesPath | Where-Object {
        $_ -match '^\|' -and $_ -notmatch '^\|\s*---'
    } | Select-Object -Skip 1

    foreach ($row in $rows) {
        $cells = @($row.Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
        if ($cells.Count -ne 7) {
            throw "Invalid THIRD_PARTY_NOTICES.md row: $row"
        }

        [pscustomobject]@{
            Name = $cells[0]
            LocalPath = $cells[1].Trim('`')
            UpstreamUrl = $cells[2].Trim('`')
            License = $cells[3]
            LicenseFile = $cells[4].Trim('`')
            Modified = $cells[5]
            PinnedCommit = $cells[6]
        }
    }
}
