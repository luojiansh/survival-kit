#requires -Version 5.0
<#!
Provision NixOS-WSL according to scripts/install.txt, with optional CA export
using scripts/Windows_to_WSL_Certs.ps1.

Notes
- Run from an elevated PowerShell (Administrator)
- Defaults mirror scripts/install.txt and this repo
- Supports optional flake boot once the base config builds
- Auto-detects repo path from script location (<repo>/scripts/ -> <repo>/nixos/)

Examples
  # Basic install using pre-made cert file
  .\Provision-NixOSWSL.ps1 -NixOSWslFile "$env:USERPROFILE\Downloads\nixos.wsl" `
    -CertPath "C:\\workspace\\ca-certificates.crt" `
    -DistroName "NixOS"

  # Generate certs from Windows store for issuers/subjects containing strings
  .\Provision-NixOSWSL.ps1 -Companies "Company1","Company2" `
    -NixOSWslFile "$env:USERPROFILE\Downloads\nixos.wsl" -DistroName "NixOS"

  # With flake boot from auto-detected repo
  .\Provision-NixOSWSL.ps1 -Companies "Company1" -NixOSHostname "AT-L-PF5S785B"
!#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter()] [string] $DistroName = "NixOS",
  [Parameter()] [string] $NixOSWslFile = "$env:USERPROFILE\Downloads\nixos.wsl",
  [Parameter()] [string] $CertPath = "C:\workspace\ca-certificates.crt",
  [Parameter()] [string[]] $Companies,
  [Parameter()] [string] $CertGeneratorPath,
  [Parameter()] [string] $GeneratorUser = "luoj",
  [Parameter()] [string] $NixOSHostname = "AT-L-PF5S785B",
  [Parameter()] [switch] $SkipInstall,
  [Parameter()] [switch] $ForceUnregister,
  [Parameter()] [switch] $LaunchAfterProvision = $true
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Step($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Info($m) { Write-Host "[i] $m" -ForegroundColor DarkCyan }
function Write-Warn($m) { Write-Warning $m }
function ThrowIf([scriptblock]$cond, [string]$msg) { if (& $cond) { throw $msg } }

function Test-WslInstalled {
  return [bool](Get-Command wsl.exe -ErrorAction SilentlyContinue)
}

function Get-RegisteredDistros {
  $lines = & wsl.exe -l -q 2>$null | ForEach-Object { $_.Trim() } | Where-Object { $_ }
  return $lines
}

function Convert-ToWslPath([string]$WindowsPath) {
  $escapedInputPath = $WindowsPath -replace '\\', '\\'
  return wsl wslpath -u "$escapedInputPath"
}

function Convert-ToWindowsPath([string]$WslPath) {
  return wsl -d $DistroName wslpath -w "$WslPath"
}

function Invoke-Wsl([string]$distro, [string]$command, [string]$workingDirWsl, [string]$user) {
  $wslArgs = @()
  if ($distro) { $wslArgs += @('-d', $distro) }
  if ($user) { $wslArgs += @('--user', $user) }
  if ($workingDirWsl) { $wslArgs += @('--cd', $workingDirWsl) }
  $wslArgs += '--'
  $wslArgs += 'sh'
  $wslArgs += '-lc'
  $wslArgs += $command
  Write-Info "wsl $($wslArgs -join ' ')"
  & wsl.exe @wslArgs
  if ($LASTEXITCODE -ne 0) {
    throw "WSL command failed with exit code ${LASTEXITCODE}: $command"
  }
}

function Copy-CertToRepo([string]$sourceCert, [string]$repoPath, [string]$hostname) {
  if ($repoPath) {
    $hostCertPath = Join-Path $repoPath "hosts\$hostname\ca-certificates.crt"
    $hostCertDir = Split-Path -Parent $hostCertPath
    if (-not (Test-Path $hostCertDir)) {
      New-Item -Path $hostCertDir -ItemType Directory -Force | Out-Null
    }
    Copy-Item -LiteralPath $sourceCert -Destination $hostCertPath -Force
    Write-Info "Copied certificate to repo at $hostCertPath"
  }
}

# Resolve default path to the cert generator
if (-not $CertGeneratorPath) {
  $scriptDir = Split-Path -Parent $PSCommandPath
  $CertGeneratorPath = Join-Path $scriptDir 'Windows_to_WSL_Certs.ps1'
}

# Auto-detect repo path (script is in <repo>/scripts/, nixos flake is in <repo>/nixos/)
$scriptDir = Split-Path -Parent $PSCommandPath
$repoRoot = Split-Path -Parent $scriptDir
$RepoPathWindows = Join-Path $repoRoot 'nixos'

if (-not (Test-Path $RepoPathWindows)) {
  Write-Warn "Repo nixos directory not found at $RepoPathWindows - repo cert copy and flake boot will be skipped"
  $RepoPathWindows = $null
}
else {
  Write-Info "Using repo path: $RepoPathWindows"
}

if (-not (Test-WslInstalled)) {
  throw "wsl.exe not found. Please install Windows Subsystem for Linux and reboot."
}

$distros = Get-RegisteredDistros
$exists = $distros -contains $DistroName

if (-not $SkipInstall) {
  if ($exists) {
    if ($ForceUnregister) {
      Write-Step "Unregistering existing distro '$DistroName'"
      & wsl.exe --unregister "$DistroName"
      $exists = $false
    }
    else {
      Write-Warn "Distro '$DistroName' already exists. Use -ForceUnregister to recreate or -SkipInstall to keep."
    }
  }

  if (-not $exists) {
    ThrowIf { -not (Test-Path -LiteralPath $NixOSWslFile) } "NixOS WSL file not found: $NixOSWslFile"
    Write-Step "Installing NixOS-WSL from file"
    try {
      & wsl.exe --install --no-launch --from-file "$NixOSWslFile" --name "$DistroName" | Write-Output
    }
    catch {
      Write-Warn "'wsl --install --from-file' failed. If your WSL doesn't support it, manually import the distro and rerun with -SkipInstall."
      throw
    }
    # Refresh distro list
    Start-Sleep -Seconds 2
    $distros = Get-RegisteredDistros
    $exists = $distros -contains $DistroName
    ThrowIf { -not $exists } "Expected distro '$DistroName' to be installed, but it is not registered."
  }
}

# Generate or locate CA certificate bundle
$nixosOutputPath = "/etc/nixos/ca-certificates.crt"
$etcNixosCertWindows = Convert-ToWindowsPath $nixosOutputPath

ThrowIf { -not (Test-Path -LiteralPath $CertGeneratorPath) } "Cert generator not found: $CertGeneratorPath"

# Use Windows_to_WSL_Certs to generate and copy certificates
& powershell.exe -ExecutionPolicy Bypass -File $CertGeneratorPath `
  -Distro $DistroName -User root -InputPath "$CertPath" `
  -OutputPath $nixosOutputPath @Companies

# Copy to repo if available (read from WSL filesystem)
if (Test-Path $etcNixosCertWindows) {
    Copy-CertToRepo -sourceCert $etcNixosCertWindows -repoPath $RepoPathWindows -hostname $NixOSHostname
}
else {
  throw "Certificate file not found at $CertPath and no -Companies specified. Provide a valid -CertPath or specify -Companies to generate certificates."
}

Write-Step "Verifying CA bundle in /etc/nixos"
Invoke-Wsl -d $DistroName -command "ls -lh /etc/nixos/ca-certificates.crt" -workingDirWsl '/'

Write-Step "Writing minimal /etc/nixos/configuration.nix"

# Check if configuration.nix already contains ca-certificates.crt reference
$configHasCert = $false
try {
  Invoke-Wsl -d $DistroName -command "grep -q 'ca-certificates.crt' /etc/nixos/configuration.nix" -workingDirWsl '/' -user 'root'
  $configHasCert = $true
  Write-Info "Configuration already contains ca-certificates.crt reference, skipping append"
}
catch {
  # grep returns non-zero if not found, which is expected
  Write-Info "Ca-certificates.crt not found in configuration, will append"
}

if (-not $configHasCert) {
  $cfg = @'
//
{
  security.pki.certificateFiles = [ ./ca-certificates.crt ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [ git neovim gh ];
}
'@
  # Use temp file to avoid shell quoting issues
  $tempFile = [System.IO.Path]::GetTempFileName()
  try {
    Set-Content -LiteralPath $tempFile -Value $cfg -Encoding ASCII -NoNewline
    $tempWsl = Convert-ToWslPath $tempFile
    Invoke-Wsl -d $DistroName -command "tee -a /etc/nixos/configuration.nix < '$tempWsl' >/dev/null" -workingDirWsl '/' -user 'root'
  }
  finally {
    if (Test-Path -LiteralPath $tempFile) {
      Remove-Item -LiteralPath $tempFile -Force
    }
  }
}

Write-Step "Running initial nixos-rebuild switch with NIX_SSL_CERT_FILE"
Invoke-Wsl -d $DistroName -command "NIX_SSL_CERT_FILE=/etc/nixos/ca-certificates.crt nixos-rebuild switch" -workingDirWsl '/' -user 'root'

if ($RepoPathWindows) {
  ThrowIf { -not (Test-Path -LiteralPath $RepoPathWindows) } "Repo path not found: $RepoPathWindows"
  
  # Copy repo to WSL temp directory
  $repoWslDest = "/tmp/nixos-provision"
  Write-Step "Copying repo to WSL at $repoWslDest"
  
  # Convert Windows path to WSL path for source
  $repoWslSource = Convert-ToWslPath $RepoPathWindows
  
  # Remove existing directory if present and copy fresh
  Invoke-Wsl -d $DistroName -command "rm -rf '$repoWslDest' && cp -r '$repoWslSource' '$repoWslDest'" -workingDirWsl '/'
  Write-Info "Repo copied to WSL"
  
  # Run flake boot from the WSL copy
  Write-Step "Running flake boot from WSL repo for host '$NixOSHostname'"
  Invoke-Wsl -d $DistroName -command "NIX_SSL_CERT_FILE=/etc/nixos/ca-certificates.crt nixos-rebuild boot --flake '$repoWslDest#$NixOSHostname'" -workingDirWsl $repoWslDest -user 'root'
}

Write-Step "Terminating distro to ensure a clean state"
Write-Info "Waiting 10 seconds before terminating..."
Start-Sleep -Seconds 10

& wsl.exe -t "$DistroName" 2>$null | Out-Null
Start-Sleep -Seconds 5

# Try to start and exit as root - ignore failures as systemd may not be ready
try {
  & wsl -d "$DistroName" --user root exit 2>$null | Out-Null
}
catch {
  Write-Info "Ignoring systemd session error (expected)"
}

& wsl.exe -t "$DistroName" 2>$null | Out-Null
Write-Info "Waiting 5 seconds after final termination..."
Start-Sleep -Seconds 5

Write-Step "Shutting down WSL to finalize changes"
& wsl.exe --shutdown

Write-Step "Done. NixOS-WSL base provisioning completed."

if ($LaunchAfterProvision) {
  Write-Info "Waiting 5 seconds before launching..."
  Start-Sleep -Seconds 5
  Write-Step "Launching WSL distro '$DistroName'..."
  &wsl -d "$DistroName" 
}