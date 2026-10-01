<#
.SYNOPSIS
    playpause.ps1 — play an audio file on Windows with interactive
    pause/resume/quit. Native PowerShell port of playpause.ksh / .sh.

.NOTES
    Usage:
        .\playpause.ps1 file.wav

    While playing:
        space   pause / resume
        q       quit (stops playback)

    Uses the Windows Media Player COM control (WMPlayer.OCX), which ships
    with Windows and supports real pause/resume natively — no process-
    suspend tricks needed, unlike the Unix versions of this tool.
#>

param(
    [Parameter(Position=0)]
    [string]$File
)

if (-not $File) {
    Write-Host "Usage: playpause.ps1 <audiofile>"
    exit 1
}

if (-not (Test-Path $File)) {
    Write-Host "Error: file not found: $File"
    exit 1
}

$FullPath = (Resolve-Path $File).Path

try {
    $wmp = New-Object -ComObject WMPlayer.OCX
} catch {
    Write-Host "Error: couldn't create the Windows Media Player control."
    Write-Host "This usually means Windows Media Player's components aren't"
    Write-Host "available on this machine (rare, but possible on some Windows"
    Write-Host "Server/N editions). No simple fallback for this script — sorry."
    exit 1
}

$wmp.URL = $FullPath
$wmp.controls.play()

Write-Host "Playing: $FullPath"
Write-Host "space = pause/resume   q = quit"
Write-Host ""

# WMP playState values: 1=Stopped, 2=Paused, 3=Playing, 8=MediaEnded (varies
# slightly by WMP version, but these four are consistently used in practice).
$Paused = $false

# Labeled so 'break PlayLoop' below unambiguously exits THIS loop, not just
# the switch block it's nested in (PowerShell's bare 'break' inside a
# switch-inside-a-loop is otherwise ambiguous about which one it exits).
:PlayLoop while ($true) {
    if ($wmp.playState -eq 1 -or $wmp.playState -eq 8) {
        # Stopped on its own, or reached the end of the file.
        break PlayLoop
    }

    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        switch ($key.KeyChar) {
            ' ' {
                if (-not $Paused) {
                    $wmp.controls.pause()
                    $Paused = $true
                    Write-Host "Paused. (space = resume, q = quit)"
                } else {
                    $wmp.controls.play()
                    $Paused = $false
                    Write-Host "Resumed."
                }
            }
            'q' {
                $wmp.controls.stop()
                Write-Host "Stopped."
                break PlayLoop
            }
            'Q' {
                $wmp.controls.stop()
                Write-Host "Stopped."
                break PlayLoop
            }
        }
    }

    Start-Sleep -Milliseconds 100
}

Write-Host "Done."
