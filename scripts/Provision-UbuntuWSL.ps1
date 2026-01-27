#requires -Version 5.0
<#!
Provision Ubuntu WSL with installation and certificate copy.

This script:
- Installs Ubuntu WSL from a tarball/image
- Copies certificates from Windows to Ubuntu
- Does NOT perform any NixOS-specific rebuild steps

Notes
- Run from an elevated PowerShell (Administrator)
- Requires WSL installed
- Reuses common functions from WSL-Common.ps1

Examples
  # Basic install using pre-made cert file
  .\Provision-UbuntuWSL.ps1 -UbuntuImagePath "$env:USERPROFILE\Downloads\ubuntu-22.04.tar.gz" `
    -CertPath "C:\workspace\ca-certificates.crt" `
    -DistroName "Ubuntu-22.04"

  # Generate certs from Windows store for issuers/subjects containing strings
  .\Provision-UbuntuWSL.ps1 -Companies "Company1","Company2" `
    -UbuntuImagePath "$env:USERPROFILE\Downloads\ubuntu-22.04.tar.gz" `
    -DistroName "Ubuntu-22.04"

  # Skip installation if distro already exists
  .\Provision-UbuntuWSL.ps1 -Companies "Company1" -SkipInstall -DistroName "Ubuntu-22.04"
!#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter()] [string] $DistroName = "Ubuntu-22.04",
  [Parameter()] [string] $UbuntuImagePath = "$env:USERPROFILE\Downloads\ubuntu-22.04.tar.gz",
  [Parameter()] [string] $CertPath = "C:\workspace\ca-certificates.crt",
  [Parameter()] [string] $CertOutputPath = "/usr/local/share/ca-certificates/corp-ca-certificates.crt",
  [Parameter()] [string[]] $Companies,
  [Parameter()] [string] $CertGeneratorPath,
  [Parameter()] [string] $UbuntuUser = "root",
  [Parameter()] [switch] $SkipInstall,
  [Parameter()] [switch] $SkipCerts,
  [Parameter()] [switch] $UpdateCaCertificates,
  [Parameter()] [switch] $ForceUnregister,
  [Parameter()] [bool] $LaunchAfterProvision = $true
)

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

# Validate WSL
if (-not (Test-WslInstalled)) {
    throw "wsl.exe not found. Please install Windows Subsystem for Linux and reboot."
}

# ============================================================================
# Installation Phase
# ============================================================================

if (-not $SkipInstall) {
    $installed = Install-WslDistro `
        -DistroName $DistroName `
        -ImagePath $UbuntuImagePath `
        -ForceUnregister $ForceUnregister
    
    if (-not $installed) {
        Write-Step "Skipping installation (distro already exists)"
    }
}
else {
    # Verify distro exists when skipping install
    $exists = Test-DistroExists -DistroName $DistroName
    ThrowIf { -not $exists } "Distro '$DistroName' does not exist. Remove -SkipInstall to create it."
    Write-Step "Skipping installation phase (distro already exists)"
}

# ============================================================================
# Certificate Phase
# ============================================================================

if (-not $SkipCerts) {
    Write-Step "Installing certificates to Ubuntu"
    
    Install-CertsToWSL `
        -DistroName $DistroName `
        -CertGeneratorPath $CertGeneratorPath `
        -CertPath $CertPath `
        -OutputPath $CertOutputPath `
        -Companies $Companies `
        -User $UbuntuUser
    
    Write-Step "Verifying certificate in $CertOutputPath"
    Invoke-Wsl -distro $DistroName -command "ls -lh '$CertOutputPath'" -workingDirWsl '/' -user $UbuntuUser
    
    # Update CA certificates if requested (Ubuntu-specific)
    if ($UpdateCaCertificates) {
        Write-Step "Updating CA certificates in Ubuntu"
        try {
            Invoke-Wsl -distro $DistroName -command "update-ca-certificates" -workingDirWsl '/' -user 'root'
            Write-Info "CA certificates updated successfully"
        }
        catch {
            Write-Warn "Failed to run update-ca-certificates. You may need to run it manually."
        }
    }
}
else {
    Write-Step "Skipping certificate installation"
}

# ============================================================================
# Cleanup and Launch
# ============================================================================

Write-Step "Terminating distro to ensure a clean state"
Stop-WslDistro -DistroName $DistroName
Start-Sleep -Seconds 2

Write-Step "Shutting down WSL to finalize changes"
Stop-AllWsl
Start-Sleep -Seconds 2

Write-Step "Done. Ubuntu WSL provisioning completed."

if ($LaunchAfterProvision) {
    Write-Info "Waiting 3 seconds before launching..."
    Start-Sleep -Seconds 3
    Write-Step "Launching WSL distro '$DistroName'..."
    & wsl -d "$DistroName"
}
