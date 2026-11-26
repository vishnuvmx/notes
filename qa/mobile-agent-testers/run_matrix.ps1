<#
.SYNOPSIS
  Local multi-device QA capture harness (mobile-agent-testers persona matrix).
  Cycles through Android device personas on a connected emulator/device,
  captures Tack screens + UIAutomator XML + accessibility audit + crash logs
  into `.ui-diff/<RunName>/<persona>/`, and cleanly resets display settings.

.EXAMPLE
  .\qa\mobile-agent-testers\run_matrix.ps1 -RunName baseline
  .\qa\mobile-agent-testers\run_matrix.ps1 -RunName current -Personas pixel_default_light,pixel_default_dark,compact_large_text
#>
param(
    [string]$RunName = "current",
    [string]$Personas = "pixel_default_light,pixel_default_dark,compact_large_text,accessibility_200,tablet_landscape,small_phone_dark",
    [string]$PackageId = "com.notes.tacknotes",
    [string]$Serial = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$personasPath = Join-Path $PSScriptRoot "personas.json"
$screenPy = Join-Path $PSScriptRoot "screen.py"
$outBase = Join-Path $repoRoot ".ui-diff\$RunName"

function Invoke-Adb {
    param([string[]]$AdbArgs)
    if ($Serial) {
        & adb -s $Serial @AdbArgs
    } else {
        & adb @AdbArgs
    }
}

$devices = (adb devices) -match "\tdevice$"
if (-not $devices) {
    throw "No online Android device/emulator detected by 'adb devices'. Start Pixel_API_36 or connect a phone first."
}

$allPersonas = Get-Content $personasPath -Raw | ConvertFrom-Json
$selectedIds = $Personas.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
$runList = $allPersonas | Where-Object { $selectedIds -contains $_.id }

if (-not $runList) {
    throw "No matching personas found for: $Personas"
}

Write-Host "==> Starting Tack multi-device QA run '$RunName' across $($runList.Count) device personas..."

try {
    foreach ($p in $runList) {
        $pidName = $p.id
        $dev = $p.device
        $pOut = Join-Path $outBase $pidName
        New-Item -ItemType Directory -Force -Path $pOut | Out-Null

        Write-Host ""
        Write-Host "=== Persona: $pidName ($($dev.name)) ==="
        Invoke-Adb @("shell", "wm", "size", "$($dev.width)x$($dev.height)") | Out-Null
        Invoke-Adb @("shell", "wm", "density", "$($dev.density)") | Out-Null
        Invoke-Adb @("shell", "settings", "put", "system", "font_scale", "$($dev.font_scale)") | Out-Null
        $nightArg = if ($dev.theme -eq "dark") { "yes" } else { "no" }
        Invoke-Adb @("shell", "cmd", "uimode", "night", $nightArg) | Out-Null
        Invoke-Adb @("logcat", "-c") | Out-Null

        # Relaunch Tack cleanly under this device profile
        Invoke-Adb @("shell", "am", "force-stop", $PackageId) | Out-Null
        Start-Sleep -Milliseconds 350
        Invoke-Adb @("shell", "monkey", "-p", $PackageId, "-c", "android.intent.category.LAUNCHER", "1") | Out-Null
        Start-Sleep -Seconds 3

        $pyArgsBase = @($screenPy, $pOut)
        if ($Serial) { $pyArgsBase += @("--serial", $Serial) }

        # 01: Today screen
        & python $screenPy $pOut "01_today" $(if ($Serial) { "--serial"; $Serial })

        # Tap bottom nav tabs relative to current device dimensions
        $navY = [int]($dev.height * 0.925)
        $libX = [int]($dev.width * 0.30)
        $brdX = [int]($dev.width * 0.49)
        $srcX = [int]($dev.width * 0.68)

        # 02: Library tab
        Invoke-Adb @("shell", "input", "tap", "$libX", "$navY") | Out-Null
        Start-Sleep -Milliseconds 600
        & python $screenPy $pOut "02_library" $(if ($Serial) { "--serial"; $Serial })

        # 03: Boards tab
        Invoke-Adb @("shell", "input", "tap", "$brdX", "$navY") | Out-Null
        Start-Sleep -Milliseconds 600
        & python $screenPy $pOut "03_boards" $(if ($Serial) { "--serial"; $Serial })

        # 04: Search tab
        Invoke-Adb @("shell", "input", "tap", "$srcX", "$navY") | Out-Null
        Start-Sleep -Milliseconds 600
        & python $screenPy $pOut "04_search" $(if ($Serial) { "--serial"; $Serial })
    }
} finally {
    Write-Host ""
    Write-Host "==> Restoring device display, density, font_scale, and light mode..."
    Invoke-Adb @("shell", "wm", "size", "reset") | Out-Null
    Invoke-Adb @("shell", "wm", "density", "reset") | Out-Null
    Invoke-Adb @("shell", "settings", "put", "system", "font_scale", "1.0") | Out-Null
    Invoke-Adb @("shell", "cmd", "uimode", "night", "no") | Out-Null
}

Write-Host "==> Capture complete: $outBase"
