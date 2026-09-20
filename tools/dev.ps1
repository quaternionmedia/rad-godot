<#
.SYNOPSIS
  The local loop for rad-godot, on the pinned engine and nothing else.

.DESCRIPTION
  tools/dev.ps1 check          headless import, the engine's own parser on every
                               script, then the main scene run headless for a few
                               frames with stderr read for script errors
  tools/dev.ps1 play           run the main scene, windowed; -Frames N quits after N frames
  tools/dev.ps1 editor         open the editor on this project

  The binary is $env:GODOT_BIN if set, otherwise the first Godot found in the
  places this org keeps one. Whatever is found is asked its version and REFUSED
  unless it matches .godot-version. A measurement against the wrong engine is
  the failure this script exists to prevent, so a mismatch is an error and not
  a warning.

  This script binds no port. The editor listens on its own debug and
  language-server ports, which are user-level editor settings and not this
  project's; `editor` prints what they are set to before launching, so a second
  editor on this workstation is visible rather than assumed.

.EXAMPLE
  tools/dev.ps1 check
  tools/dev.ps1 play -Frames 60
  $env:GODOT_BIN = 'D:\godot\Godot_v4.7.2-stable_win64.exe'; tools/dev.ps1 check
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('check', 'play', 'editor')]
    [string]$Mode = 'check',

    # play only: quit after this many frames. 0 runs until the window closes.
    [int]$Frames = 0,

    # check only: how many frames the headless smoke run lasts.
    [int]$SmokeFrames = 30
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Find-Godot {
    if ($env:GODOT_BIN) {
        if (-not (Test-Path $env:GODOT_BIN)) { throw "GODOT_BIN is set to '$($env:GODOT_BIN)', which does not exist." }
        return (Resolve-Path $env:GODOT_BIN).Path
    }
    $candidates = @()
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root)) {
        $candidates += Join-Path $drive 'SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe'
        $candidates += Join-Path $drive 'Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe'
    }
    $onPath = Get-Command godot -ErrorAction SilentlyContinue
    if ($onPath) { $candidates += $onPath.Source }
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    throw "No Godot binary found. Set GODOT_BIN to the $((Get-Content .godot-version).Trim()) engine."
}

function Assert-Pin([string]$bin) {
    # .godot-version uses the release's download form (4.7.2-stable); the
    # engine reports its own form (4.7.2.stable.steam.<hash>). Compare on
    # major.minor.patch.status; the build tag after that is who compiled it.
    $pin = (Get-Content .godot-version -ErrorAction Stop).Trim().Replace('-', '.')
    $reported = (& $bin --version 2>$null | Select-Object -First 1).Trim()
    if (-not $reported) { throw "'$bin' printed nothing for --version." }
    $parts = $reported.Split('.')
    if ($parts.Count -lt 4) { throw "'$bin' reported '$reported', which is not major.minor.patch.status." }
    $running = ($parts[0..3] -join '.')
    if ($running -ne $pin) {
        throw "Refusing to run: '$bin' is Godot $reported but .godot-version pins $pin. Set GODOT_BIN to a $pin build, or make the upgrade a decision first."
    }
    Write-Host "engine  $reported" -ForegroundColor DarkGray
    Write-Host "binary  $bin" -ForegroundColor DarkGray
}

function Invoke-Godot([string]$bin, [string[]]$arguments) {
    # The engine is a GUI-subsystem executable (PE subsystem 2), so the call
    # operator returns before it exits unless its output happens to be piped,
    # and $LASTEXITCODE is then whatever it was before. Start-Process -Wait
    # waits regardless of where the output goes and reports the real code.
    $p = Start-Process -FilePath $bin -ArgumentList $arguments -Wait -PassThru -NoNewWindow
    return $p.ExitCode
}

function Invoke-GodotCaptured([string]$bin, [string[]]$arguments) {
    # Same as Invoke-Godot, with stderr kept. A script error at runtime does not
    # change the engine's exit code (it prints SCRIPT ERROR: and carries on), so
    # for the smoke run stderr is the verdict and the exit code is not.
    $out = New-TemporaryFile
    $err = New-TemporaryFile
    try {
        $p = Start-Process -FilePath $bin -ArgumentList $arguments -Wait -PassThru -NoNewWindow `
            -RedirectStandardOutput $out.FullName -RedirectStandardError $err.FullName
        return @{
            ExitCode = $p.ExitCode
            Stdout   = (Get-Content $out.FullName -Raw)
            Stderr   = (Get-Content $err.FullName -Raw)
        }
    } finally {
        Remove-Item $out.FullName, $err.FullName -ErrorAction SilentlyContinue
    }
}

try {
$godot = Find-Godot
Assert-Pin $godot

switch ($Mode) {
    'check' {
        Write-Host '== import' -ForegroundColor Cyan
        $rc = Invoke-Godot $godot @('--headless', '--path', '.', '--import')
        if ($rc -ne 0) { throw "import exited $rc" }
        # --import exits 0 whether or not it imported anything; ask the disk.
        python tools/check_imports.py
        if ($LASTEXITCODE -ne 0) { throw "the import left declared artefacts missing" }

        Write-Host '== vector pin' -ForegroundColor Cyan
        python tools/check_vector_pin.py
        if ($LASTEXITCODE -ne 0) { throw "conformance/vectors.json is not the copy the lock pins" }

        Write-Host '== check-only, every tracked script outside addons/' -ForegroundColor Cyan
        $scripts = git ls-files '*.gd' | Where-Object { $_ -notlike 'addons/*' }
        if (-not $scripts) { throw 'git ls-files found no scripts; is this the repository root?' }
        $failed = @()
        foreach ($s in $scripts) {
            $rc = Invoke-Godot $godot @('--headless', '--path', '.', '--check-only', '-s', "res://$s")
            if ($rc -ne 0) { $failed += $s } else { Write-Host "ok      $s" -ForegroundColor DarkGray }
        }
        if ($failed) { throw "check-only failed for: $($failed -join ', ')" }
        Write-Host "OK: $($scripts.Count) scripts pass the engine's parser." -ForegroundColor Green

        Write-Host "== smoke, main scene headless for $SmokeFrames frames" -ForegroundColor Cyan
        $run = Invoke-GodotCaptured $godot @('--headless', '--path', '.', '--quit-after', "$SmokeFrames")
        if ($run.ExitCode -ne 0) { throw "the smoke run exited $($run.ExitCode)" }
        $errors = @($run.Stderr -split "`r?`n" | Where-Object { $_ -match '^(SCRIPT ERROR|ERROR):' })
        if ($errors) {
            $run.Stderr.TrimEnd() | Write-Host -ForegroundColor Red
            throw "the smoke run printed $($errors.Count) error line(s) to stderr"
        }
        Write-Host "OK: $SmokeFrames frames, nothing on stderr." -ForegroundColor Green
    }
    'play' {
        $arguments = @('--path', '.')
        if ($Frames -gt 0) { $arguments += @('--quit-after', "$Frames") }
        Write-Host "== play$(if ($Frames -gt 0) { " ($Frames frames)" })" -ForegroundColor Cyan
        $rc = Invoke-Godot $godot $arguments
        if ($rc -ne 0) { throw "the game exited $rc" }
    }
    'editor' {
        $settings = Join-Path $env:APPDATA 'Godot\editor_settings-4.7.tres'
        $steamSettings = Join-Path (Split-Path -Parent $godot) 'editor_data\editor_settings-4.7.tres'
        foreach ($f in @($steamSettings, $settings)) {
            if (Test-Path $f) {
                Write-Host "== editor ports, from $f" -ForegroundColor Cyan
                $ports = Select-String -Path $f -Pattern 'remote_port|remote_host' | ForEach-Object { $_.Line.Trim() }
                if ($ports) { $ports | ForEach-Object { Write-Host "        $_" -ForegroundColor DarkGray } }
                else { Write-Host '        (defaults: debugger 6007, language server 6005, DAP 6006 -- none overridden)' -ForegroundColor DarkGray }
                break
            }
        }
        $running = Get-Process | Where-Object { $_.MainWindowTitle -like '*rad-godot - Godot Engine*' }
        if ($running) {
            throw "An editor already has this project open (pid $($running.Id -join ', ')): '$($running.MainWindowTitle -join '; ')'. Two editors on one project.godot overwrite each other. Use that one."
        }
        Write-Host '== editor' -ForegroundColor Cyan
        Start-Process -FilePath $godot -ArgumentList @('--path', "`"$root`"", '--editor') | Out-Null
        Write-Host "launched; project.godot is now the editor's to write. Do not edit it from a terminal until the editor is closed." -ForegroundColor Yellow
    }
}
} catch {
    # A .ps1 sets no exit status unless it says so, and a caller reading
    # $LASTEXITCODE after a throw sees whatever was there before.
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
exit 0
