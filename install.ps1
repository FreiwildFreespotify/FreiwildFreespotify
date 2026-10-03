<#
.SYNOPSIS
    Freiwild Spotify modded - Installer & Auto-Updater

.DESCRIPTION
    Lädt das neueste Freiwild-Paket von GitHub herunter, installiert es
    nach %LOCALAPPDATA%\FreiwildSpotify, richtet Spicetify ein und wendet
    Theme + Extension an. Wird erneut ausgeführt, aktualisiert es sich
    automatisch auf die neueste Version.

    Einzeiler (PowerShell):
      irm https://raw.githubusercontent.com/FreiwildFreespotify/Freiwild-Spotify/main/install.ps1 | iex

.PARAMETER Uninstall
    Entfernt Freiwild (Theme + Extension + lokale Dateien).
    Spicetify selbst bleibt erhalten.

.NOTES
    Built on Spicetify CLI (https://spicetify.app) - LGPL-2.1.
    This script does not redistribute Spicetify binaries from this repo;
    it fetches the official release from spicetify/cli when needed.
#>

[CmdletBinding()]
param(
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

# --- Konfiguration ---------------------------------------------------------
$RepoOwner = 'FreiwildFreespotify'
$RepoName  = 'Freiwild-Spotify'
$Branch    = 'main'
$RawBase   = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"
$Releases  = "https://github.com/$RepoOwner/$RepoName/releases/download"

$InstallDir = Join-Path $env:LOCALAPPDATA 'FreiwildSpotify'
$SpiceDir   = Join-Path $env:APPDATA 'spicetify'
$ThemeDir   = Join-Path $SpiceDir 'Themes\Freiwild'
$ExtDir     = Join-Path $SpiceDir 'Extensions'
$ExtFile    = Join-Path $ExtDir 'Freiwild.js'
$LocalVer   = Join-Path $InstallDir 'version.json'

$SpicetifyExe = Join-Path $InstallDir 'spicetify.exe'

# --- Helfer ---------------------------------------------------------------
function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Magenta }
function Write-Ok($msg)   { Write-Host "    OK  $msg" -ForegroundColor Green }
function Write-Warn2($msg){ Write-Host "    !   $msg" -ForegroundColor Yellow }

function Get-RemoteFile([string]$RelativePath) {
    $url = "$RawBase/$RelativePath"
    try {
        return (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30).Content
    } catch {
        throw "Download fehlgeschlagen: $url ($($_.Exception.Message))"
    }
}

function Get-LocalVersion {
    if (Test-Path $LocalVer) {
        try { return (Get-Content $LocalVer -Raw | ConvertFrom-Json).version } catch { return $null }
    }
    return $null
}

# --- Banner ----------------------------------------------------------------
function Show-Banner {
    Write-Host ''
    Write-Host '  ==============================================' -ForegroundColor Magenta
    Write-Host '   FREEWILD SPOTIFY MODDED - Installer' -ForegroundColor White
    Write-Host '   powered by Spicetify (LGPL-2.1)' -ForegroundColor DarkGray
    Write-Host '  ==============================================' -ForegroundColor Magenta
    Write-Host ''
}

# --- Deinstallation --------------------------------------------------------
function Invoke-Uninstall {
    Write-Step 'Deinstallation'

    if (Test-Path $ThemeDir) {
        Remove-Item $ThemeDir -Recurse -Force
        Write-Ok "Theme entfernt: $ThemeDir"
    }
    if (Test-Path $ExtFile) {
        Remove-Item $ExtFile -Force
        Write-Ok "Extension entfernt: $ExtFile"
    }
    if (Test-Path $InstallDir) {
        Remove-Item $InstallDir -Recurse -Force
        Write-Ok "Lokale Dateien entfernt: $InstallDir"
    }

    # Theme aus Config loeschen, damit Spicetify sauber weiterlaeuft
    $spice = Get-Command 'spicetify' -ErrorAction SilentlyContinue
    if (-not $spice -and (Test-Path $SpicetifyExe)) { $spice = $SpicetifyExe }
    if ($spice) {
        & $spice config current_theme '' 2>$null | Out-Null
        & $spice config color_scheme '' 2>$null | Out-Null
        & $spice config extensions 'Freiwild.js-' 2>$null | Out-Null
        & $spice apply 2>$null | Out-Null
    }

    Write-Host ''
    Write-Ok 'Freiwild wurde entfernt. Spotify ist wieder im Originalzustand.'
    Write-Host ''
}

# --- Spotify-Pfade ermitteln ----------------------------------------------
function Get-SpotifyPaths {
    $result = @{ SpotifyPath = ''; PrefsPath = '' }

    $candidates = @(
        (Join-Path $env:APPDATA 'Spotify'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\Spotify') ,
        (Join-Path $env:ProgramFiles 'Spotify'),
        (Join-Path ${env:ProgramFiles(x86)} 'Spotify')
    ) | Where-Object { $_ -and (Test-Path $_) }

    foreach ($c in $candidates) {
        if (Test-Path (Join-Path $c 'prefs')) {
            $result.SpotifyPath = $c
            $result.PrefsPath   = Join-Path $c 'prefs'
            break
        }
    }
    return $result
}

# --- Spicetify besorgen -----------------------------------------------------
function Install-Spicetify {
    if (Get-Command 'spicetify' -ErrorAction SilentlyContinue) {
        Write-Ok 'Spicetify ist bereits im PATH'
        return
    }
    if (Test-Path $SpicetifyExe) {
        Write-Ok 'Spicetify bereits lokal vorhanden'
        return
    }

    Write-Step 'Lade Spicetify CLI (offizielles Release)'

    # Offizielles Windows-Release von spicetify/cli
    $apiUrl = 'https://api.github.com/repos/spicetify/cli/releases/latest'
    $rel = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing -TimeoutSec 30
    $asset = $rel.assets | Where-Object { $_.name -match 'windows.*x64.*\.zip$' } | Select-Object -First 1
    if (-not $asset) { $asset = $rel.assets | Where-Object { $_.name -match 'win.*\.zip$' } | Select-Object -First 1 }
    if (-not $asset) { throw 'Kein passendes Spicetify-Windows-Release gefunden.' }

    $tmp = Join-Path $env:TEMP ("spicetify-" + [guid]::NewGuid().ToString() + '.zip')
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tmp -UseBasicParsing

    $extract = Join-Path $env:TEMP ("spicetify-x-" + [guid]::NewGuid().ToString())
    Expand-Archive -Path $tmp -DestinationPath $extract -Force

    $exe = Get-ChildItem $extract -Recurse -Filter 'spicetify.exe' | Select-Object -First 1
    if (-not $exe) { throw 'spicetify.exe im Archiv nicht gefunden.' }

    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    Copy-Item $exe.FullName $SpicetifyExe -Force
    Remove-Item $tmp, $extract -Recurse -Force -ErrorAction SilentlyContinue

    Write-Ok "Spicetify $($rel.tag_name) installiert: $SpicetifyExe"
}

# --- Paket von GitHub holen -------------------------------------------------
function Install-FreiwildPackage {
    Write-Step 'Prüfe auf Updates'

    $remoteJson = Get-RemoteFile 'version.json'
    $remote = $remoteJson | ConvertFrom-Json
    $remoteVer = $remote.version
    $localVer  = Get-LocalVersion

    if ($localVer -and $localVer -eq $remoteVer) {
        Write-Ok "Bereits aktuell (v$remoteVer) - Dateien werden neu synchronisiert"
    } elseif ($localVer) {
        Write-Ok "Update: v$localVer -> v$remoteVer"
    } else {
        Write-Ok "Erstinstallation: v$remoteVer"
    }

    New-Item -ItemType Directory -Force -Path $InstallDir, $ThemeDir, $ExtDir | Out-Null

    # Version lokal speichern
    Set-Content -Path $LocalVer -Value $remoteJson -Encoding UTF8

    # Theme-Dateien
    foreach ($f in 'color.ini', 'user.css') {
        $content = Get-RemoteFile "themes/Freiwild/$f"
        Set-Content -Path (Join-Path $ThemeDir $f) -Value $content -Encoding UTF8
        Write-Ok "themes/Freiwild/$f"
    }

    # Extension
    $ext = Get-RemoteFile 'extensions/Freiwild.js'
    Set-Content -Path $ExtFile -Value $ext -Encoding UTF8
    Write-Ok 'extensions/Freiwild.js'

    # Optional: weiteres Repo-File (z.B. README) fuer lokale Referenz
    try {
        Set-Content -Path (Join-Path $InstallDir 'README.md') -Value (Get-RemoteFile 'README.md') -Encoding UTF8
    } catch { }

    return $remote
}

# --- Spicetify konfigurieren & anwenden -------------------------------------
function Invoke-Apply([string]$SpiceCmd, $SpotifyPath, $PrefsPath) {
    Write-Step 'Konfiguriere Spicetify'

    & $SpiceCmd config current_theme 'Freiwild' | Out-Null
    & $SpiceCmd config color_scheme  'freiwild' | Out-Null
    & $SpiceCmd config inject_css    '1' | Out-Null
    & $SpiceCmd config replace_colors '1' | Out-Null
    & $SpiceCmd config overwrite_assets '1' | Out-Null
    & $SpiceCmd config inject_theme_js '1' | Out-Null

    # Extension zur Liste hinzufuegen (idempotent)
    & $SpiceCmd config extensions 'Freiwild.js' | Out-Null

    if ($SpotifyPath) { & $SpiceCmd config spotify_path $SpotifyPath | Out-Null }
    if ($PrefsPath)   { & $SpiceCmd config prefs_path    $PrefsPath   | Out-Null }

    Write-Ok 'Config gesetzt: current_theme=Freiwild, color_scheme=freiwild'

    Write-Step 'Wende Änderungen an (Backup + Apply)'

    $spotify = Get-Process 'Spotify' -ErrorAction SilentlyContinue
    if ($spotify) {
        Write-Warn2 'Spotify läuft – bitte schließen, damit die Änderungen greifen.'
        Write-Warn2 'Drücke eine Taste, nachdem du Spotify geschlossen hast.'
        [void]$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }

    & $SpiceCmd backup
    & $SpiceCmd apply

    if ($LASTEXITCODE -ne 0) {
        Write-Warn2 'apply meldete einen Fehler – versuche es mit restore + apply'
        & $SpiceCmd restore
        & $SpiceCmd apply
    }
}

# --- Hauptprogramm ----------------------------------------------------------
function Main {
    Show-Banner

    if ($Uninstall) {
        Invoke-Uninstall
        return
    }

    try {
        Install-Spicetify
        $info = Install-FreiwildPackage

        $spiceCmd = $null
        if (Get-Command 'spicetify' -ErrorAction SilentlyContinue) { $spiceCmd = 'spicetify' }
        elseif (Test-Path $SpicetifyExe) { $spiceCmd = $SpicetifyExe }

        if (-not $spiceCmd) { throw 'Spicetify nicht gefunden.' }

        $paths = Get-SpotifyPaths
        if (-not $paths.SpotifyPath) {
            Write-Warn2 'Spotify-Ordner nicht gefunden – Spicetify wird die Pfade selbst versuchen zu ermitteln.'
        }

        Invoke-Apply $spiceCmd $paths.SpotifyPath $paths.PrefsPath

        Write-Host ''
        Write-Host '  ==============================================' -ForegroundColor Magenta
        Write-Host "   FERTIG - Freiwild Spotify modded v$($info.version)" -ForegroundColor Green
        Write-Host '   Theme: Freiwild  |  Scheme: freiwild' -ForegroundColor White
        Write-Host '  ==============================================' -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Erneutes Ausführen des Einzeilers = Update auf neue Version' -ForegroundColor DarkGray
        Write-Host '  Deinstallieren:  install.ps1 -Uninstall' -ForegroundColor DarkGray
        Write-Host ''
    } catch {
        Write-Host ''
        Write-Host "  FEHLER: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ''
        exit 1
    }
}

Main
