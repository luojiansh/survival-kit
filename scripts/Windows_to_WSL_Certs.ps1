#requires -Version 5.0
<#!
Export certificates from Windows Certificate store and add to WSL distro.
If a valid input certificate file is provided, use that instead of generating.

Notes
- Run from an elevated PowerShell (Administrator) recommended
- Can generate from Windows store by company name filter
- Can copy existing certificate file to WSL

Requirements
- WSL installed and configured
- Certificate issuer/subject knowledge (when generating)

Examples
  # Generate from Windows store (all Root and CA certs)
  .\Windows_to_WSL_Certs.ps1 -Distro NixOS -User jian `
    -OutputPath "/etc/nixos/ca-certificates.crt"

  # Use existing certificate file
  .\Windows_to_WSL_Certs.ps1 -Distro NixOS -User jian `
    -InputPath "C:\certs\ca.crt" -OutputPath "/etc/nixos/ca-certificates.crt"
!#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string] $Distro,
  [Parameter(Mandatory)] [string] $User,
  [Parameter()] [string] $InputPath,
  [Parameter()] [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Import common functions (only if not already loaded)
if (-not (Get-Variable -Name WSL_COMMON_LOADED -Scope Global -ErrorAction SilentlyContinue)) {
  $scriptDir = Split-Path -Parent $PSCommandPath
  $commonModule = Join-Path $scriptDir 'WSL-Common.ps1'
  if (Test-Path $commonModule) {
    . $commonModule
  }
}

# Define minimal helper functions if not available from common module
if (-not (Get-Command Write-Info -ErrorAction SilentlyContinue)) {
  function Write-Info($m) { Write-Host "[i] $m" -ForegroundColor DarkCyan }
}
if (-not (Get-Command Convert-ToWslPath -ErrorAction SilentlyContinue)) {
  function Convert-ToWslPath([string]$WindowsPath) {
    $escapedInputPath = $WindowsPath -replace '\\', '\\'
    return wsl wslpath -u "$escapedInputPath"
  }
}

# Validate parameters
if (-not $OutputPath) {
  Write-Host "Error: -OutputPath parameter is required." -ForegroundColor Red
  exit 1
}

# Display the search parameters
Write-Info "WSL Distro: $Distro | User: $User"
Write-Info "Output Path: $OutputPath"

# Check if valid InputPath was provided
if ($InputPath -and (Test-Path $InputPath)) {
  Write-Info "Using provided certificate file: $InputPath"
  
  try {
    # Convert Windows path to WSL path using common function
    $inputWslPath = Convert-ToWslPath -WindowsPath $InputPath
    
    # Copy using WSL as the specified user (handles permissions correctly)
    wsl -d $Distro -u $User -e sh -c "sudo install -D -m 0644 '$inputWslPath' '$OutputPath'"
    
    Write-Host "Certificate copied to " -ForegroundColor Green -NoNewline
    Write-Host $OutputPath -ForegroundColor Yellow -NoNewline
    Write-Host " in WSL" -ForegroundColor Green
    exit 0
  }
  catch {
    Write-Host "Failed to copy certificate to WSL" -ForegroundColor Red
    exit 1
  }
}

# No valid cert provided, generate from Windows store
Write-Info "Exporting all Root and CA certificates from LocalMachine"

# Get all certificates from Root and CA stores in LocalMachine
$all_certs = @(
  Get-ChildItem -Path Cert:\LocalMachine\Root -ErrorAction SilentlyContinue
  Get-ChildItem -Path Cert:\LocalMachine\CA -ErrorAction SilentlyContinue
) | Select-Object -Property *

if ($all_certs.Length -eq 0) {
  Write-Host "No certificates found for your input, try again." -ForegroundColor Yellow
  exit 1
}
else {
  # Create temporary file for combining certificates
  $tempFile = [System.IO.Path]::GetTempFileName()
  $combined_file_path = $tempFile

  $cert_count = 0
  # Iterate through the certificates
  $all_certs | ForEach-Object {
    try {
      $cert = Get-Item $_.PSPath

      # Add a comment header for each certificate
      $cert_info = "# Certificate: $($_.Subject)"
      $cert_info | Out-File -FilePath $combined_file_path -Encoding ascii -Append

      # Export the certificate content in Base64
      $cert_content = @(
        '-----BEGIN CERTIFICATE-----'
        [System.Convert]::ToBase64String($cert.RawData, 'InsertLineBreaks')
        '-----END CERTIFICATE-----'
        ''  # Empty line between certificates
      )
      # Append content to combined file
      $cert_content | Out-File -FilePath $combined_file_path -Encoding ascii -Append

      $cert_count++
      Write-Host "Added certificate: " -ForegroundColor Green -NoNewLine
      Write-Host $_.Subject -ForegroundColor Yellow
    }
    catch {
      Write-Host "Could not process certificate with thumbprint: $($_.Thumbprint)" -ForegroundColor Red
    }
  }

  # Copy to WSL using WSL commands
  if ($cert_count -gt 0) {
    try {
      # Convert Windows temp path to WSL path using common function
      $tempWslPath = Convert-ToWslPath -WindowsPath $combined_file_path
      
      # Copy using WSL as the specified user (handles permissions correctly)
      wsl -d $Distro -u $User -e sh -c "sudo install -D -m 0644 '$tempWslPath' '$OutputPath'"
      
      Write-Host "`nImported " -ForegroundColor Green -NoNewLine
      Write-Host $cert_count -ForegroundColor Cyan -NoNewLine
      Write-Host " certificates to " -ForegroundColor Green -NoNewLine
      Write-Host $OutputPath -ForegroundColor Yellow -NoNewline
      Write-Host " in WSL" -ForegroundColor Green
    }
    catch {
      Write-Host "`nFailed to copy certificates to WSL" -ForegroundColor Red
      exit 1
    }
    finally {
      # Clean up temporary file
      if (Test-Path $combined_file_path) {
        Remove-Item $combined_file_path -Force
        Write-Host "Cleaned up temporary file" -ForegroundColor Gray
      }
    }
  }
}
