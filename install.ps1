#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

$App = "toporic"
$Repo = "ToporicAI/toporic-code"
$InstallDir = Join-Path $env:ProgramFiles $App

# ── Platform detection ────────────────────────────────────────────────────────
$Arch = $env:PROCESSOR_ARCHITECTURE.ToLower()
$Target = switch ($Arch) {
  "amd64"   { "x86_64-pc-windows-msvc" }
  "arm64"   { "aarch64-pc-windows-msvc" }
  default   { Write-Error "Unsupported architecture: $Arch"; exit 1 }
}

# ── Fetch latest version ──────────────────────────────────────────────────────
$VersionJsonUrl = "https://toporic.com/code/tui/version.json"
$VersionJson = Invoke-RestMethod -Uri $VersionJsonUrl -UseBasicParsing
$Version = $VersionJson.version

if (-not $Version) {
  Write-Error "Failed to determine latest version"
  exit 1
}

Write-Output "Toporic ${Version} (${Target})"

# ── Download binary ───────────────────────────────────────────────────────────
$ReleaseUrl = "https://github.com/${Repo}/releases/download/v${Version}"
$Archive = "toporic-code-v${Version}-${Target}.zip"
$DownloadUrl = "${ReleaseUrl}/${Archive}"

$TmpDir = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $TmpDir | Out-Null

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
      Write-Error "Checksum mismatch!`n  Expected: ${Expected}`n  Actual:   ${Actual}"
      exit 1
    }
    Write-Output "Checksum verified."
  } catch {
    Write-Warning "Checksum file not available, skipping verification."
  }

  # ── Extract and install ─────────────────────────────────────────────────────
  Expand-Archive -Path $ArchivePath -DestinationPath $TmpDir
  $BinaryPath = Join-Path $TmpDir "${App}.exe"

  if (-not (Test-Path $BinaryPath)) {
    Write-Error "Binary not found after extraction"
    exit 1
  }

  if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
  }

  $DestPath = Join-Path $InstallDir "${App}.exe"
  Copy-Item -Path $BinaryPath -Destination $DestPath -Force

  # Add to PATH for current user if not already there
  $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($UserPath -notlike "*${InstallDir}*") {
    [Environment]::SetEnvironmentVariable("Path", "${UserPath};${InstallDir}", "User")
    Write-Output "Added ${InstallDir} to user PATH"
  }

  Write-Output "Installed ${App} ${Version} to ${DestPath}"
  Write-Output "Run '${App} --help' to get started."
} finally {
  Remove-Item -Path $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
