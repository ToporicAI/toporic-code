# Toporic installer — Windows PowerShell
# Usage:
#   irm https://raw.githubusercontent.com/ToporicAI/toporic-code/main/install.ps1 | iex
#   or with a specific version:
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/ToporicAI/toporic-code/main/install.ps1))) -Version 1.2.3

param(
    [string]$Version = "",
    [string]$InstallDir = ""
)

$ErrorActionPreference = "Stop"

$Repo   = "ToporicAI/toporic-code"
$Binary = "toporic"
$Target = "x86_64-pc-windows-msvc"

# ── Helpers ───────────────────────────────────────────────────────────────────

function Write-Step  { param($msg) Write-Host "  > $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "  ! $msg" -ForegroundColor Yellow }
function Write-Fatal { param($msg) Write-Host "  x $msg" -ForegroundColor Red; exit 1 }

# ── Resolve install directory ─────────────────────────────────────────────────

if (-not $InstallDir) {
    $InstallDir = "$env:LOCALAPPDATA\toporic\bin"
}

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# ── Resolve version ───────────────────────────────────────────────────────────

if (-not $Version) {
    Write-Step "Fetching latest release version..."
    try {
        $release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"
        $Version = $release.tag_name -replace '^v', ''
    } catch {
        Write-Fatal "Could not determine latest version: $_`nUse -Version to specify one."
    }
}

$Tag      = "v$Version"
$Archive  = "$Binary-$Tag-$Target.zip"
$BaseUrl  = "https://github.com/$Repo/releases/download/$Tag"

Write-Step "Installing $Binary $Tag for $Target..."

# ── Download ──────────────────────────────────────────────────────────────────

$TmpDir = Join-Path $env:TEMP "toporic-install-$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null

$ArchivePath  = Join-Path $TmpDir $Archive
$Sha256Path   = Join-Path $TmpDir "sha256sums.txt"

Write-Step "Downloading $Archive..."
try {
    Invoke-WebRequest "$BaseUrl/$Archive"     -OutFile $ArchivePath  -UseBasicParsing
    Invoke-WebRequest "$BaseUrl/sha256sums.txt" -OutFile $Sha256Path -UseBasicParsing
} catch {
    Write-Fatal "Download failed: $_"
}

# ── Verify checksum ───────────────────────────────────────────────────────────

Write-Step "Verifying checksum..."
$actualHash = (Get-FileHash $ArchivePath -Algorithm SHA256).Hash.ToLower()
$expectedLine = Get-Content $Sha256Path | Where-Object { $_ -match [regex]::Escape($Archive) }

if (-not $expectedLine) {
    Write-Fatal "Could not find checksum entry for $Archive in sha256sums.txt"
}

$expectedHash = ($expectedLine -split '\s+')[0].ToLower()

if ($actualHash -ne $expectedHash) {
    Write-Fatal "Checksum mismatch!`n  Expected: $expectedHash`n  Got:      $actualHash"
}

# ── Extract and install ───────────────────────────────────────────────────────

Write-Step "Extracting..."
Expand-Archive -Path $ArchivePath -DestinationPath $TmpDir -Force

$ExeSrc  = Join-Path $TmpDir "$Binary.exe"
$ExeDest = Join-Path $InstallDir "$Binary.exe"

Move-Item -Path $ExeSrc -Destination $ExeDest -Force

# ── PATH registration ─────────────────────────────────────────────────────────

$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$InstallDir*") {
    Write-Step "Adding $InstallDir to user PATH..."
    [System.Environment]::SetEnvironmentVariable(
        "PATH",
        "$InstallDir;$userPath",
        "User"
    )
    $env:PATH = "$InstallDir;$env:PATH"
    Write-Warn "Restart your terminal (or open a new shell) for PATH changes to take effect."
}

# ── Cleanup ───────────────────────────────────────────────────────────────────

Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Step "Installed to $ExeDest"
Write-Step "Done! Run: $Binary --version"
