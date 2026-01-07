#requires -Version 5.0
<#!
Provision Ubuntu / Debian WSL with installation and certificate copy.

This script:
- Installs Ubuntu WSL from a tarball/image
- Copies certificates from Windows to Ubuntu / Debian WSL
- Installs Nix package manager
- Applies home-manager configuration from the repo

Notes
- Requires WSL installed
- Reuses common functions from WSL-Common.ps1

Examples
  # Basic install using pre-made cert file
  .\Provision-UbuntuWSL.ps1 -Image "$env:USERPROFILE\Downloads\ubuntu-22.04.tar.gz" `
    -CertPath "C:\workspace\ca-certificates.crt" `
    -DistroName "Ubuntu-22.04"

  # Generate certs from Windows store for issuers/subjects containing strings
  .\Provision-UbuntuWSL.ps1 -Companies "Company1","Company2" `
    -Image "Ubuntu-22.04" `
    -DistroName "Ubuntu-22.04"

  # Skip installation if distro already exists
  .\Provision-UbuntuWSL.ps1 -Companies "Company1" -SkipInstall -DistroName "Ubuntu-22.04"
!#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter()] [string] $DistroName = "Ubuntu",
  [Parameter()] [string] $Image = "Ubuntu",
  [Parameter()] [string[]] $Companies,
  [Parameter()] [string] $CertGeneratorPath,
  [Parameter()] [string] $WslUser = "luoj",
  [Parameter()] [switch] $SkipInstall,
  [Parameter()] [switch] $SkipCerts,
  [Parameter()] [switch] $SkipNixInstall,
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
  $CertGeneratorPath = Join-Path $scriptDir 'get-all-certs.sh'
}

# Auto-detect repo path using common function
$RepoPathWindows = Get-RepoNixosPath -ScriptPath $PSCommandPath

if (-not (Test-WslInstalled)) {
  throw "wsl.exe not found. Please install Windows Subsystem for Linux and reboot."
}

# ============================================================================
# Installation Phase
# ============================================================================

if (-not $SkipInstall) {
  $installed = Install-WslDistro `
    -DistroName $DistroName `
    -Image $Image `
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

# ============================================================================
# Certificate Phase
# ============================================================================

$wslCertGeneratorPath = Convert-ToWslPath $CertGeneratorPath 

if (-not $SkipCerts) {
  Write-Step "Installing certificates to $DistroName"
    
  # Update CA certificates
    
  try {
    Invoke-Wsl -distro $DistroName -command "$wslCertGeneratorPath" -workingDirWsl '/' -user "root"
    Write-Info "CA certificates updated successfully"
  }
  catch {
    Write-Warn "Failed to run $wslCertGeneratorPath. You may need to run it manually."
  }
}
else {
  Write-Step "Skipping certificate installation"
}

$NixBuildEnv = "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"

# ============================================================================
# Nix setup phase
# ============================================================================

if (-not $SkipNixInstall) {  
  # Install nix
  # Invoke-Wsl -d $DistroName -command "apt-get update && apt-get install -y git" -workingDirWsl '/' -user 'root'
  Write-Step "Installing Nix package manager in $DistroName"
  Invoke-Wsl -d $DistroName -command "curl -L https://nixos.org/nix/install | $NixBuildEnv sh -s -- --daemon " -workingDirWsl '/' -user 'root'
  Invoke-Wsl -d $DistroName -command "echo experimental-features = nix-command flakes >> /etc/nix/nix.conf" -workingDirWsl '/' -user 'root'
}


if ($RepoPathWindows) {
  ThrowIf { -not (Test-Path -LiteralPath $RepoPathWindows) } "Repo path not found: $RepoPathWindows"

  $wslUserHome = "/home/$WslUser"
  $windowsUserHome = Convert-ToWindowsPath -WslPath $wslUserHome -DistroName $DistroName
  if (-not (Test-Path -LiteralPath $windowsUserHome)) {
    # Ensure user home exists by launching WSL as that user
    Write-Info "Launching WSL to initialize home directory for user $WslUser"
    wsl.exe -d "$DistroName"
  }
  else {
    Write-Info "User home directory should already exist at $wslUserHome"
  }

  # Copy repo to WSL temp directory
  $repoWslDest = "$wslUserHome/nixos-provisioning"
  Write-Step "Copying repo to WSL at $repoWslDest"
  
  # Convert Windows path to WSL path for source
  $repoWslSource = Convert-ToWslPath $RepoPathWindows
  
  # Remove existing directory if present and copy fresh
  Invoke-Wsl -d $DistroName -command "rm -rf '$repoWslDest' && cp -r '$repoWslSource' '$repoWslDest'" -workingDirWsl '/'
  Write-Info "Repo copied to WSL"
  
  # Run home-manager build from the WSL copy
  Write-Step "Running home-manager build from WSL repo for $WslUser"
  Invoke-Wsl -d $DistroName -command "$NixBuildEnv nix build '$repoWslDest#homeConfigurations.$WslUser.activationPackage'" -workingDirWsl $repoWslDest -user "$WslUser"
  Invoke-Wsl -d $DistroName -command "mv .bashrc .bashrc.dist; mv .profile .profile.dist" -workingDirWsl $wslUserHome -user "$WslUser"
  Invoke-Wsl -d $DistroName -command "$NixBuildEnv $repoWslDest/result/activate" -workingDirWsl $wslUserHome -user "$WslUser"
}

# ============================================================================
# Cleanup and Launch
# ============================================================================

Write-Step "Terminating distro to ensure a clean state"
Stop-WslDistro -DistroName $DistroName
Start-Sleep -Seconds 2

# Write-Step "Shutting down WSL to finalize changes"
# Stop-AllWsl
# Start-Sleep -Seconds 2

Write-Step "Done. WSL provisioning completed."

if ($LaunchAfterProvision) {
  Write-Info "Waiting 3 seconds before launching..."
  Start-Sleep -Seconds 3
  Write-Step "Launching WSL distro '$DistroName'..."
  & wsl -d "$DistroName"
}
