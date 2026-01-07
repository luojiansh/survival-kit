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
  [Parameter()] [switch] $SkipCerts,
  [Parameter()] [switch] $ForceUnregister,
  [Parameter()] [bool] $LaunchAfterProvision = $true
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Import common functions
$scriptDir = Split-Path -Parent $PSCommandPath
$commonModule = Join-Path $scriptDir 'WSL-Common.ps1'
if (-not (Test-Path $commonModule)) {
    throw "Required module not found: $commonModule"
}
. $commonModule

# Resolve default path to the cert generator
if (-not $CertGeneratorPath) {
  $CertGeneratorPath = Join-Path $scriptDir 'Windows_to_WSL_Certs.ps1'
}

# Auto-detect repo path using common function
$RepoPathWindows = Get-RepoNixosPath -ScriptPath $PSCommandPath

if (-not (Test-WslInstalled)) {
  throw "wsl.exe not found. Please install Windows Subsystem for Linux and reboot."
}

if (-not $SkipInstall) {
  $installed = Install-WslDistro `
    -DistroName $DistroName `
    -ImagePath $NixOSWslFile `
    -ForceUnregister $ForceUnregister
  
  if (-not $installed) {
    Write-Step "Skipping installation (distro already exists)"
  }
}
else {
  # Verify distro exists when skipping install
  $exists = Test-DistroExists -DistroName $DistroName
  ThrowIf { -not $exists } "Distro '$DistroName' does not exist. Remove -SkipInstall to create it."
}


$NixBuildEnv = ""

if (-not $SkipCerts) {
  # Generate or locate CA certificate bundle
  $nixosOutputPath = "/etc/nixos/ca-certificates.crt"
  $etcNixosCertWindows = Convert-ToWindowsPath -WslPath $nixosOutputPath -DistroName $DistroName

  Write-Step "Installing certificates to NixOS"
  
  Install-CertsToWSL `
    -DistroName $DistroName `
    -CertGeneratorPath $CertGeneratorPath `
    -CertPath $CertPath `
    -OutputPath $nixosOutputPath `
    -Companies $Companies `
    -User 'root'

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
  $NixBuildEnv = "NIX_SSL_CERT_FILE=/etc/nixos/ca-certificates.crt"
}

Write-Step "Running initial nixos-rebuild switch with NIX_SSL_CERT_FILE"
Invoke-Wsl -d $DistroName -command "$NixBuildEnv nixos-rebuild switch" -workingDirWsl '/' -user 'root'

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
  Invoke-Wsl -d $DistroName -command "$NixBuildEnv nixos-rebuild boot --flake '$repoWslDest#$NixOSHostname'" -workingDirWsl $repoWslDest -user 'root'
}

Write-Step "Terminating distro to ensure a clean state"
Write-Info "Waiting 10 seconds before terminating..."
Start-Sleep -Seconds 10

Stop-WslDistro -DistroName $DistroName
Start-Sleep -Seconds 5

# Try to start and exit as root - ignore failures as systemd may not be ready
try {
  & wsl -d "$DistroName" --user root exit 2>$null | Out-Null
}
catch {
  Write-Info "Ignoring systemd session error (expected)"
}

Stop-WslDistro -DistroName $DistroName
Write-Info "Waiting 5 seconds after final termination..."
Start-Sleep -Seconds 5

Write-Step "Shutting down WSL to finalize changes"
Stop-AllWsl

Write-Step "Done. NixOS-WSL base provisioning completed."

if ($LaunchAfterProvision) {
  Write-Info "Waiting 5 seconds before launching..."
  Start-Sleep -Seconds 5
  Write-Step "Launching WSL distro '$DistroName'..."
  &wsl -d "$DistroName" 
}
