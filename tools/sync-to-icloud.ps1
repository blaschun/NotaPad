# Kopiert den Code aus dem Git-Repo nach iCloud Drive (Swift Playgrounds-Projekt).
# Richtung: nur Repo -> iCloud. Package.swift und .swiftpm-Metadaten bleiben unberührt.
param(
    [string]$Ziel = "$env:USERPROFILE\iCloudDrive\iCloud~com~apple~Playgrounds\Notepad.swiftpm"
)
$ErrorActionPreference = "Stop"
$quelle = Join-Path $PSScriptRoot "..\NotaPad.swiftpm" | Resolve-Path

if (-not (Test-Path $Ziel)) {
    Write-Host "Zielprojekt nicht gefunden: $Ziel" -ForegroundColor Red
    Write-Host "Lege es zuerst auf dem iPad an (Ticket T0.1) und warte auf den iCloud-Sync."
    exit 1
}

# Nur diese Ordner werden gespiegelt (alte Dateien darin werden entfernt, damit nichts veraltet).
$ordner = "App","Models","Storage","Library","Editor","Services","Ink","Handwriting","Formats","Settings","Design","Debug","Resources","Core"
foreach ($o in $ordner) {
    $q = Join-Path $quelle $o
    if (-not (Test-Path $q)) { continue }
    $z = Join-Path $Ziel $o
    robocopy $q $z /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy-Fehler bei $o (Code $LASTEXITCODE)" }
}
Write-Host "Sync fertig -> $Ziel" -ForegroundColor Green
