$root = Split-Path -Parent $PSScriptRoot
$markplane = Join-Path $root "markplane.exe"

function Start-MarkplaneServe {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][int]$Port
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $markplane
    $psi.Arguments = "serve --port $Port"
    $psi.WorkingDirectory = $ProjectRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $process = [System.Diagnostics.Process]::Start($psi)

    $deadline = (Get-Date).AddSeconds(15)
    $ready = $false
    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/" -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode) {
                $ready = $true
                break
            }
        } catch [System.Net.WebException] {
            if ($_.Exception.Response) {
                $ready = $true
                break
            }
        } catch {
        }
        Start-Sleep -Milliseconds 300
    }

    if (-not $ready) {
        Stop-MarkplaneServe -Process $process
        throw "markplane serve did not become reachable on port $Port within 15s"
    }

    return $process
}

function Stop-MarkplaneServe {
    param([Parameter(Mandatory = $true)]$Process)

    if (-not $Process.HasExited) {
        $Process.Kill()
        $Process.WaitForExit(5000) | Out-Null
    }
}

function Get-StatusCode {
    param([Parameter(Mandatory = $true)][string]$Uri)

    try {
        $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 5
        return [int]$response.StatusCode
    } catch [System.Net.WebException] {
        if ($_.Exception.Response) {
            return [int]$_.Exception.Response.StatusCode
        }
        throw
    }
}

Describe "Markplane web UI embedding" {
    It "ships markplane.exe" {
        (Test-Path -LiteralPath $markplane -PathType Leaf) | Should Be $true
    }

    It "serves the embedded web UI instead of 404 on / and /graph" {
        $project = Join-Path $TestDrive "web-ui-project"
        New-Item -ItemType Directory -Force -Path $project | Out-Null
        Push-Location $project
        try {
            & $markplane init --name WebUiTest --empty | Out-Null
        } finally {
            Pop-Location
        }

        $port = Get-Random -Minimum 20000 -Maximum 40000
        $process = Start-MarkplaneServe -ProjectRoot $project -Port $port
        try {
            $rootStatus = Get-StatusCode -Uri "http://127.0.0.1:$port/"
            $graphStatus = Get-StatusCode -Uri "http://127.0.0.1:$port/graph"

            $rootStatus | Should Be 200
            $graphStatus | Should Be 200
        } finally {
            Stop-MarkplaneServe -Process $process
        }
    }
}
