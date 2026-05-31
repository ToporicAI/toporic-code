#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

$App = "toporic"
$Repo = "ToporicAI/toporic-code"

# ── Platform detection ────────────────────────────────────────────────────────
# Use PROCESSOR_ARCHITECTURE from 64-bit PowerShell (WOW64 adds PROCESSOR_ARCHITEW6432)
$Arch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
$Arch = $Arch.ToLower()
$Target = switch ($Arch) {
  "amd64"   { "x86_64-pc-windows-msvc" }
  "arm64"   { "aarch64-pc-windows-msvc" }
  default   { throw "Unsupported architecture: $Arch" }
}

# ── Resolve install directory ─────────────────────────────────────────────────
# Prefer user-local path (no admin required), fall back to ProgramFiles
$LocalDir = Join-Path $env:LOCALAPPDATA $App
$ProgramDir = Join-Path $env:ProgramFiles $App

$InstallDir = if (Test-Path $ProgramDir) { $ProgramDir } else { $LocalDir }
$NeedAdmin = $InstallDir -eq $ProgramDir

# ── Fetch latest version ──────────────────────────────────────────────────────
$VersionJsonUrl = "https://raw.githubusercontent.com/${Repo}/main/version.json"
$VersionJson = Invoke-RestMethod -Uri $VersionJsonUrl -UseBasicParsing
$Version = $VersionJson.version

if (-not $Version) {
  throw "Failed to determine latest version."
}

Write-Output "Toporic ${Version} (${Target})"

# ── Download binary ───────────────────────────────────────────────────────────
$ReleaseUrl = "https://github.com/${Repo}/releases/download/v${Version}"
$Archive = "${App}-v${Version}-${Target}.zip"
$DownloadUrl = "${ReleaseUrl}/${Archive}"

$TmpDir = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null

try {
  $ArchivePath = Join-Path $TmpDir $Archive
  Write-Output "Downloading ${DownloadUrl} ..."
  Invoke-WebRequest -Uri $DownloadUrl -OutFile $ArchivePath -UseBasicParsing

  # ── Verify checksum ─────────────────────────────────────────────────────────
  $CheckUrl = "${DownloadUrl}.sha256"
  try {
    $CheckContent = Invoke-RestMethod -Uri $CheckUrl -UseBasicParsing
    $Expected = ($CheckContent -split '\s+')[0]
    $Actual = (Get-FileHash $ArchivePath -Algorithm SHA256).Hash.ToLower()
    if ($Expected -ne $Actual) {
      throw "Checksum mismatch!`n  Expected: ${Expected}`n  Actual:   ${Actual}"
    }
    Write-Output "Checksum verified."
  } catch {
    Write-Warning "Checksum file not available, skipping verification."
  }

  # ── Extract and install ─────────────────────────────────────────────────────
  Expand-Archive -Path $ArchivePath -DestinationPath $TmpDir
  $BinaryPath = Join-Path $TmpDir "${App}.exe"

  if (-not (Test-Path $BinaryPath)) {
    throw "Binary not found after extraction."
  }

  if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
  }

  $DestPath = Join-Path $InstallDir "${App}.exe"
  Copy-Item -Path $BinaryPath -Destination $DestPath -Force

  # Add to PATH for current user
  $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($UserPath -notlike "*${InstallDir}*") {
    [Environment]::SetEnvironmentVariable("Path", "${UserPath};${InstallDir}", "User")
    Write-Output "Added ${InstallDir} to user PATH"
  }

  Write-Output ""
  Write-Output "Installed ${App} ${Version} to ${DestPath}"
  Write-Output "Run '${App} --help' to get started."

  if ($NeedAdmin) {
    Write-Warning "Installed to ${InstallDir} (system directory)."
    Write-Warning "Re-run the script from a non-admin shell to install to ${LocalDir} (no admin required)."
  }
} finally {
  Remove-Item -Path $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
