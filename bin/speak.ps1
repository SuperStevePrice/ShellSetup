<#
.SYNOPSIS
    speak.ps1 — read text aloud on Windows using the built-in System.Speech
    engine, or save it as a .wav file. Native PowerShell port of speak.ksh
    / speak.sh (macOS / Linux) — same concept, same flags, Windows-native
    mechanics underneath.

.NOTES
    Requires: Windows with .NET's System.Speech assembly (built in, no
    install needed). Run from a normal PowerShell window:
        powershell -ExecutionPolicy Bypass -File speak.ps1 <args>
    or, if your execution policy already allows local scripts:
        .\speak.ps1 <args>

    IMPORTANT — things that are genuinely different from the Mac/Linux
    versions, not bugs:
      - Rate (-r) uses Windows' own -10..10 integer scale, NOT words-per-
        minute. 0 is the voice's normal speed; negative is slower,
        positive is faster.
      - Voices depend entirely on what's installed on THIS Windows
        machine. Windows always ships at least one English voice, but a
        German voice is only present if the German language/speech pack
        has been added (Settings > Time & Language > Language & region >
        Add a language > German > make sure "Text-to-speech" is included
        under Language options). If no German voice is found, this
        script warns and falls back to whatever voice is already active.
      - -o only saves .wav (System.Speech only writes WAV).
      - Pause/resume here uses the synthesizer's own native Pause()/
        Resume() methods — not a process-suspend hack like on Unix —
        so it's actually cleaner on this platform.
#>

Add-Type -AssemblyName System.Speech

$Synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
$UsageFile = Join-Path $env:USERPROFILE "Documents\speak.usage"

$TestEN = "This is the speak command, reading text aloud with your Mac's built-in voices at whatever rate and voice you choose."
$TestDE = "Dies ist das Sprachprogramm, das Texte mit den eingebauten Stimmen Ihres Mac in beliebiger Geschwindigkeit und Stimme vorliest."
$TestES = "Este es el comando speak, que lee texto en voz alta con las voces integradas de su Mac a la velocidad y con la voz que usted elija."
$TestFR = "Ceci est la commande speak, qui lit le texte à voix haute avec les voix intégrées de votre Mac, à la vitesse et avec la voix de votre choix."

function Find-VoiceByCulturePrefix {
    param([string]$Prefix)
    $match = $Synth.GetInstalledVoices() | Where-Object {
        $_.Enabled -and $_.VoiceInfo.Culture.Name.ToLower().StartsWith($Prefix.ToLower())
    } | Select-Object -First 1
    if ($match) { return $match.VoiceInfo.Name }
    return $null
}

$GermanDefaultVoice  = Find-VoiceByCulturePrefix "de"
$EnglishDefaultVoice = Find-VoiceByCulturePrefix "en"
$SpanishDefaultVoice = Find-VoiceByCulturePrefix "es"
$FrenchDefaultVoice  = Find-VoiceByCulturePrefix "fr"
if (-not $EnglishDefaultVoice) {
    # Should essentially never happen — Windows always ships an English
    # voice — but fall back to whatever's currently selected just in case.
    $EnglishDefaultVoice = $Synth.Voice.Name
}

# ---------------------------------------------------------------------------
# Usage / help
# ---------------------------------------------------------------------------
function Show-Usage {
    Write-Host "Usage: speak.ps1 <textfile|-> [-v voice] [-g [voice]] [-e [voice]] [-s [voice]] [-f [voice]] [-r rate] [-o outfile.wav] [-p] [-n]"
    Write-Host "       speak.ps1 -l            (list available voices)"
    Write-Host "       speak.ps1 -t            (speak English/German/Spanish/French test sentences)"
    Write-Host "       speak.ps1 -h            (full help)"
    Write-Host "See $UsageFile"
    exit 1
}

function Show-Help {
    $helpText = @"
speak — read text aloud on Windows (System.Speech), or save it as a .wav file.

USAGE
    speak.ps1 <textfile|-> [options]
    speak.ps1 -l
    speak.ps1 -t
    speak.ps1 -h

ARGUMENTS
    <textfile>         Path to a text file to read aloud.
    -                   Read from stdin instead of a file (pipe text in).
                        Example: "hello" | .\speak.ps1 -

OPTIONS (any order, mixed freely)
    -v <voice>          Use this exact voice by name — run -l to see what's
                        actually installed on THIS machine (names vary by
                        Windows install and language packs added).

    -g [voice]          German shortcut.
                          speak.ps1 file.txt -g          uses the German
                                                          default voice,
                                                          if one is
                                                          installed
                          speak.ps1 file.txt -g "Name"   uses the named
                                                          voice
                        If no German voice is installed at all, this
                        warns and falls back to the current voice rather
                        than failing outright.

    -e [voice]          English shortcut. Same pattern as -g; Windows
                        ships at least one English voice by default.

    -s [voice]          Spanish shortcut. Same pattern as -g — needs a
                        Spanish language/speech pack installed, or it
                        warns and falls back to the current voice.

    -f [voice]          French shortcut. Same pattern as -g — needs a
                        French language/speech pack installed, or it
                        warns and falls back to the current voice.

    -r <rate>           Speech rate on WINDOWS' OWN SCALE: -10 (slowest)
                        to 10 (fastest), 0 = normal. This is NOT the same
                        scale as the words-per-minute rate used on macOS/
                        Linux versions of this tool — don't reuse those
                        numbers here. Example: -r 3

    -o <outfile>        Save audio to a .wav file instead of speaking it
                        aloud. (System.Speech only writes WAV.)
                        Example: -o out.wav

    -p                  Print the text to the screen in sync with the
                        voice: each line is printed, then spoken, then
                        the next line — so what's on screen stays in
                        step with what you're hearing.
                        Note: combined with -o, line-by-line sync doesn't
                        apply — the whole text prints up front instead,
                        since the output is one continuous audio file.

    -n                  Natural reading: only meaningful together with -p.
                        Prints the whole text up front, then speaks it in
                        one continuous pass instead of pausing between
                        lines. Use -p alone for memorization (paced);
                        add -n when you just want to listen naturally
                        while reading along.

    -l                  List every voice installed on this machine (name
                        and culture/language code) — the name is what you
                        pass to -v, -g, or -e.

    -t                  Speak a short English test sentence, then German,
                        Spanish, and French ones (for whichever of those
                        voices are actually installed), using the default
                        voice for each on this machine.

    -h                  Show this full help text.

    (no arguments)      Same as -t.

WHILE SPEAKING
    space               Pause / resume (uses the synthesizer's own native
                        pause — not a workaround, a real supported
                        feature on this platform).
    q                   Stop speaking entirely.

NOTES
    - Voice availability depends on what's installed on this Windows
      machine. Add a German voice via Settings > Time & Language >
      Language & region > Add a language > German > ensure
      "Text-to-speech" is checked under that language's options.
    - space/q controls need a real console window; if run with input/
      output fully redirected (e.g. from certain automation contexts),
      these are skipped and it just speaks straight through.
"@
    Write-Host $helpText

    try {
        $docsDir = Join-Path $env:USERPROFILE "Documents"
        if (-not (Test-Path $docsDir)) { New-Item -ItemType Directory -Path $docsDir | Out-Null }
        $helpText | Out-File -FilePath $UsageFile -Encoding utf8
    } catch { }

    Write-Host ""
    $answer = Read-Host "Open $UsageFile in Notepad? y or n"
    if ($answer -match '^(y|yes)$') {
        Start-Process notepad.exe $UsageFile
    }
    exit 0
}

function Show-Voices {
    foreach ($v in $Synth.GetInstalledVoices()) {
        $info = $v.VoiceInfo
        Write-Host "$($info.Name)  $($info.Culture)  $($info.Gender)"
    }
    exit 0
}

# ---------------------------------------------------------------------------
# Universal stop/restart control — space = pause/resume, q = stop.
# Uses the synthesizer's own Pause()/Resume(), and polls the console for a
# keypress without blocking, the same way the Mac/Linux versions poll
# /dev/tty. If there's no real console (input/output redirected), controls
# are skipped and the call just runs to completion normally.
# ---------------------------------------------------------------------------
$Script:Quit = $false
$HaveConsole = -not [Console]::IsInputRedirected

function Speak-WithControls {
    param([string]$Text)

    if (-not $HaveConsole) {
        $Synth.Speak($Text)   # synchronous, no controls possible anyway
        return
    }

    $Synth.SpeakAsync($Text) | Out-Null
    $paused = $false

    while ($Synth.State -eq [System.Speech.Synthesis.SynthesizerState]::Speaking -or
           $Synth.State -eq [System.Speech.Synthesis.SynthesizerState]::Paused) {

        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            switch ($key.KeyChar) {
                ' ' {
                    if (-not $paused) {
                        $Synth.Pause()
                        $paused = $true
                        Write-Host ""
                        Write-Host "Paused. (space = resume, q = stop)"
                    } else {
                        $Synth.Resume()
                        $paused = $false
                        Write-Host "Resumed."
                    }
                }
                'q' {
                    $Synth.SpeakAsyncCancelAll()
                    $Script:Quit = $true
                    Write-Host "Stopped."
                }
                'Q' {
                    $Synth.SpeakAsyncCancelAll()
                    $Script:Quit = $true
                    Write-Host "Stopped."
                }
            }
        }
        Start-Sleep -Milliseconds 100
    }
}

# ---------------------------------------------------------------------------
# -t / no-arguments: run the English/German self-test
# ---------------------------------------------------------------------------
function Run-Test {
    $Synth.SelectVoice($EnglishDefaultVoice)
    Write-Host ""
    Write-Host "English ($EnglishDefaultVoice): "
    Write-Host ""
    Write-Host $TestEN
    Write-Host ""
    Speak-WithControls $TestEN

    if ($GermanDefaultVoice) {
        $Synth.SelectVoice($GermanDefaultVoice)
        Write-Host ""
        Write-Host "German ($GermanDefaultVoice): "
        Write-Host ""
        Write-Host $TestDE
        Write-Host ""
        Speak-WithControls $TestDE
    } else {
        Write-Host ""
        Write-Host "No German voice installed — skipping the German test sentence."
        Write-Host "(Settings > Time & Language > Language & region > Add a language > German,"
        Write-Host " with Text-to-speech included under that language's options.)"
    }

    if ($SpanishDefaultVoice) {
        $Synth.SelectVoice($SpanishDefaultVoice)
        Write-Host ""
        Write-Host "Spanish ($SpanishDefaultVoice): "
        Write-Host ""
        Write-Host $TestES
        Write-Host ""
        Speak-WithControls $TestES
    } else {
        Write-Host ""
        Write-Host "No Spanish voice installed — skipping the Spanish test sentence."
        Write-Host "(Settings > Time & Language > Language & region > Add a language > Spanish,"
        Write-Host " with Text-to-speech included under that language's options.)"
    }

    if ($FrenchDefaultVoice) {
        $Synth.SelectVoice($FrenchDefaultVoice)
        Write-Host ""
        Write-Host "French ($FrenchDefaultVoice): "
        Write-Host ""
        Write-Host $TestFR
        Write-Host ""
        Speak-WithControls $TestFR
    } else {
        Write-Host ""
        Write-Host "No French voice installed — skipping the French test sentence."
        Write-Host "(Settings > Time & Language > Language & region > Add a language > French,"
        Write-Host " with Text-to-speech included under that language's options.)"
    }

    Write-Host ""
    Write-Host "speak.ps1 -h will show the usage message."
    Write-Host ""
    exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing — same "any order" approach as the Mac/Linux versions.
# ---------------------------------------------------------------------------
if ($args.Count -eq 0) { Run-Test }
if ($args.Count -eq 1 -and $args[0] -eq '-t') { Run-Test }
if ($args.Count -eq 1 -and ($args[0] -eq '-h' -or $args[0] -eq '--help')) { Show-Help }
if ($args.Count -eq 1 -and $args[0] -eq '-l') { Show-Voices }

$Voice   = $null
$LangFlag = $null
$Rate    = $null
$OutFile = $null
$Input_  = $null
$PFlag   = $false
$NFlag   = $false

$i = 0
while ($i -lt $args.Count) {
    $a = $args[$i]
    switch -regex ($a) {
        '^-v$' { $Voice = $args[$i+1]; $i += 2; continue }
        '^-r$' { $Rate  = $args[$i+1]; $i += 2; continue }
        '^-o$' { $OutFile = $args[$i+1]; $i += 2; continue }
        '^-g$' {
            if (($i+1) -lt $args.Count -and $args[$i+1] -notmatch '^-' -and -not (Test-Path $args[$i+1])) {
                $Voice = $args[$i+1]; $LangFlag = 'g'; $i += 2
            } else {
                if ($GermanDefaultVoice) {
                    $Voice = $GermanDefaultVoice
                } else {
                    Write-Host "Note: no German voice installed — using the current voice instead."
                    $Voice = $null
                }
                $LangFlag = 'g'; $i += 1
            }
            continue
        }
        '^-e$' {
            if (($i+1) -lt $args.Count -and $args[$i+1] -notmatch '^-' -and -not (Test-Path $args[$i+1])) {
                $Voice = $args[$i+1]; $LangFlag = 'e'; $i += 2
            } else {
                $Voice = $EnglishDefaultVoice; $LangFlag = 'e'; $i += 1
            }
            continue
        }
        '^-s$' {
            if (($i+1) -lt $args.Count -and $args[$i+1] -notmatch '^-' -and -not (Test-Path $args[$i+1])) {
                $Voice = $args[$i+1]; $LangFlag = 's'; $i += 2
            } else {
                if ($SpanishDefaultVoice) {
                    $Voice = $SpanishDefaultVoice
                } else {
                    Write-Host "Note: no Spanish voice installed — using the current voice instead."
                    $Voice = $null
                }
                $LangFlag = 's'; $i += 1
            }
            continue
        }
        '^-f$' {
            if (($i+1) -lt $args.Count -and $args[$i+1] -notmatch '^-' -and -not (Test-Path $args[$i+1])) {
                $Voice = $args[$i+1]; $LangFlag = 'f'; $i += 2
            } else {
                if ($FrenchDefaultVoice) {
                    $Voice = $FrenchDefaultVoice
                } else {
                    Write-Host "Note: no French voice installed — using the current voice instead."
                    $Voice = $null
                }
                $LangFlag = 'f'; $i += 1
            }
            continue
        }
        '^-l$' { Show-Voices }
        '^(-h|--help)$' { Show-Help }
        '^-p$' { $PFlag = $true; $i += 1; continue }
        '^-n$' { $NFlag = $true; $i += 1; continue }
        '^-t$' { Show-Usage }
        '^-' { Show-Usage }
        default { $Input_ = $a; $i += 1; continue }
    }
}

if (-not $Input_) { Show-Usage }

if ($Voice) {
    try {
        $Synth.SelectVoice($Voice)
    } catch {
        Write-Host "Error: voice '$Voice' not found. Run -l to see installed voices."
        exit 1
    }
    if ($LangFlag -eq 'g') {
        $culture = $Synth.Voice.Culture.Name
        if (-not $culture.ToLower().StartsWith('de')) {
            Write-Host "Note: '$Voice' is a $culture voice, not German — using it anyway."
        }
    }
    if ($LangFlag -eq 'e') {
        $culture = $Synth.Voice.Culture.Name
        if (-not $culture.ToLower().StartsWith('en')) {
            Write-Host "Note: '$Voice' is a $culture voice, not English — using it anyway."
        }
    }
    if ($LangFlag -eq 's') {
        $culture = $Synth.Voice.Culture.Name
        if (-not $culture.ToLower().StartsWith('es')) {
            Write-Host "Note: '$Voice' is a $culture voice, not Spanish — using it anyway."
        }
    }
    if ($LangFlag -eq 'f') {
        $culture = $Synth.Voice.Culture.Name
        if (-not $culture.ToLower().StartsWith('fr')) {
            Write-Host "Note: '$Voice' is a $culture voice, not French — using it anyway."
        }
    }
}

if ($Rate) {
    $r = [int]$Rate
    if ($r -lt -10) { $r = -10 }
    if ($r -gt 10)  { $r = 10 }
    $Synth.Rate = $r
}

if ($Input_ -ne '-' -and -not (Test-Path $Input_)) {
    Write-Host "Error: file not found: $Input_"
    exit 1
}

function Get-InputText {
    if ($Input_ -eq '-') {
        return [Console]::In.ReadToEnd()
    } else {
        return Get-Content -Raw -Path $Input_
    }
}

if ($OutFile) {
    # Saving to file: no live pause/resume needed — synthesis-to-disk is
    # effectively instant, so just do it as one synchronous call.
    if ($OutFile -notmatch '\.wav$') {
        Write-Host "Note: speak.ps1 only saves .wav files — saving as $OutFile.wav instead."
        $OutFile = "$OutFile.wav"
    }
    $text = Get-InputText
    if ($PFlag) { Write-Host ""; Write-Host $text; Write-Host "" }
    $Synth.SetOutputToWaveFile($OutFile)
    $Synth.Speak($text)
    $Synth.SetOutputToDefaultAudioDevice()
    Write-Host "Saved audio to: $OutFile"
    exit 0
}

if ($PFlag -and -not $NFlag) {
    # Line-by-line sync: print each line right before speaking it.
    $lines = if ($Input_ -eq '-') { (Get-InputText) -split "`n" } else { Get-Content -Path $Input_ }
    foreach ($line in $lines) {
        Write-Host $line
        if ($line.Trim() -ne '') { Speak-WithControls $line }
        if ($Script:Quit) { break }
    }
} elseif ($PFlag -and $NFlag) {
    $text = Get-InputText
    Write-Host ""
    Write-Host $text
    Write-Host ""
    Speak-WithControls $text
} else {
    $text = Get-InputText
    Speak-WithControls $text
}
