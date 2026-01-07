#requires -Version 5.0
<#
.SYNOPSIS
Common functions for WSL provisioning scripts.

.DESCRIPTION
Provides reusable helper functions for installing and managing WSL distros,
copying certificates, and running commands in WSL environments.
#>

# Guard against recursive imports
# Check if functions are already loaded in the current scope
if (Get-Command -Name Get-RepoNixosPath -ErrorAction SilentlyContinue) {
  return
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ============================================================================
# Output Helpers
# ============================================================================

function Write-Step($m) {
  Write-Host "==> $m" -ForegroundColor Cyan
}

function Write-Info($m) {
  Write-Host "[i] $m" -ForegroundColor DarkCyan
}

function Write-Warn($m) {
  Write-Warning $m
}

function ThrowIf([scriptblock]$cond, [string]$msg) {
  if (& $cond) { throw $msg }
}

# ============================================================================
# WSL Detection and Management
# ============================================================================

function Test-WslInstalled {
  <#
  .SYNOPSIS
  Checks if WSL is installed and available.
  #>
  return [bool](Get-Command wsl.exe -ErrorAction SilentlyContinue)
}

function Get-RegisteredDistros {
  <#
  .SYNOPSIS
  Returns list of currently registered WSL distros.
  #>
  $lines = & wsl.exe -l -q 2>$null | ForEach-Object { $_.Trim() } | Where-Object { $_ }
  return $lines
}

function Test-DistroExists([string]$DistroName) {
  <#
  .SYNOPSIS
  Checks if a specific WSL distro is registered.
  #>
  $distros = Get-RegisteredDistros
  return $distros -contains $DistroName
}

# ============================================================================
# Path Conversion
# ============================================================================

function Convert-ToWslPath([string]$WindowsPath) {
  <#
  .SYNOPSIS
  Converts a Windows path to WSL Unix-style path.
  #>
  $escapedInputPath = $WindowsPath -replace '\\', '\\'
  return wsl wslpath -u "$escapedInputPath"
}

function Convert-ToWindowsPath([string]$WslPath, [string]$DistroName) {
  <#
  .SYNOPSIS
  Converts a WSL Unix path to Windows path.
  #>
  return wsl -d $DistroName wslpath -w "$WslPath"
}

# ============================================================================
# WSL Command Execution
# ============================================================================

function Invoke-Wsl {
  <#
  .SYNOPSIS
  Executes a shell command in WSL with proper error handling.
  
  .PARAMETER distro
  The WSL distro name to run command in.
  
  .PARAMETER command
  The shell command to execute.
  
  .PARAMETER workingDirWsl
  The working directory (WSL path) for the command.
  
  .PARAMETER user
  The user to run the command as.
  #>
  param(
    [string]$distro,
    [string]$command,
    [string]$workingDirWsl,
    [string]$user
  )
  
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

# ============================================================================
# Certificate Management
# ============================================================================

function Copy-CertToRepo {
  <#
  .SYNOPSIS
  Copies a certificate to the repository's host-specific directory.
  
  .PARAMETER sourceCert
  The source certificate file path (Windows).
  
  .PARAMETER repoPath
  The repository nixos directory path (Windows).
  
  .PARAMETER hostname
  The hostname subdirectory under hosts/.
  #>
  param(
    [string]$sourceCert,
    [string]$repoPath,
    [string]$hostname
  )
  
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

function Install-CertsToWSL {
  <#
  .SYNOPSIS
  Installs certificates to WSL distro using Windows_to_WSL_Certs.ps1.
  
  .PARAMETER DistroName
  The WSL distro name.
  
  .PARAMETER CertGeneratorPath
  Path to Windows_to_WSL_Certs.ps1.
  
  .PARAMETER CertPath
  Path to existing certificate file (optional).
  
  .PARAMETER OutputPath
  Target path in WSL for certificates.
  
  .PARAMETER Companies
  Array of company name filters for cert generation.
  
  .PARAMETER User
  WSL user for cert operations (default: root).
  #>
  param(
    [Parameter(Mandatory)]
    [string]$DistroName,
    
    [Parameter(Mandatory)]
    [string]$CertGeneratorPath,
    
    [string]$CertPath,
    
    [Parameter(Mandatory)]
    [string]$OutputPath,
    
    [string[]]$Companies,
    
    [string]$User = "root"
  )
  
  ThrowIf { -not (Test-Path -LiteralPath $CertGeneratorPath) } "Cert generator not found: $CertGeneratorPath"
  
  $certArgs = @(
    '-Distro', $DistroName,
    '-User', $User,
    '-OutputPath', $OutputPath
  )
  
  if ($CertPath -and (Test-Path $CertPath)) {
    $certArgs += @('-InputPath', $CertPath)
  }
  
  if ($Companies) {
    $certArgs += $Companies
  }
  
  & powershell.exe -ExecutionPolicy Bypass -File $CertGeneratorPath @certArgs
  
  if ($LASTEXITCODE -ne 0) {
    throw "Certificate installation failed"
  }
}

# ============================================================================
# WSL Distro Installation
# ============================================================================

function Install-WslDistro {
  <#
  .SYNOPSIS
  Installs a WSL distro from a tarball/image file or by standard distro name.
  
  .PARAMETER DistroName
  The name to register the distro as.
  
  .PARAMETER Image
  Path to the WSL tarball or image file, or a standard distro name (e.g., Ubuntu, Debian).
  
  .PARAMETER ForceUnregister
  If true, unregister existing distro before installing.
  #>
  param(
    [Parameter(Mandatory)]
    [string]$DistroName,
    
    [Parameter(Mandatory)]
    [string]$Image,
    
    [bool]$ForceUnregister = $false
  )
  
  $exists = Test-DistroExists -DistroName $DistroName
  
  if ($exists) {
    if ($ForceUnregister) {
      Write-Step "Unregistering existing distro '$DistroName'"
      & wsl.exe --unregister "$DistroName"
      if ($LASTEXITCODE -ne 0) {
        throw "Failed to unregister distro '$DistroName'"
      }
      $exists = $false
      Start-Sleep -Seconds 2
    }
    else {
      Write-Warn "Distro '$DistroName' already exists. Use -ForceUnregister to recreate."
      return $false
    }
  }
  
  # Check if Image is an actual file (tarball/image) or a distro name
  $isFile = Test-Path -LiteralPath $Image -PathType Leaf
  
  if ($isFile) {
    Write-Step "Installing WSL distro from file"
    try {
      & wsl.exe --install --no-launch --from-file "$Image" --name "$DistroName" | Write-Output
      if ($LASTEXITCODE -ne 0) {
        throw "WSL install command returned exit code $LASTEXITCODE"
      }
    }
    catch {
      Write-Warn "'wsl --install --from-file' failed. If your WSL doesn't support it, manually import the distro."
      throw
    }
  }
  else {
    Write-Step "Installing WSL distro '$Image' as standard distribution"
    try {
      & wsl.exe --install --no-launch -d "$Image" --name "$DistroName" # | Write-Output
      if ($LASTEXITCODE -ne 0) {
        throw "WSL install command returned exit code $LASTEXITCODE"
      }
    }
    catch {
     Write-Warn "Failed to install distro '$Image'. Verify the distro name is valid."
     throw
    }
  }
  
  # Verify installation
  Start-Sleep -Seconds 2
  $exists = Test-DistroExists -DistroName $DistroName
  ThrowIf { -not $exists } "Expected distro '$DistroName' to be installed, but it is not registered."
  
  return $true
}

function Stop-WslDistro {
  <#
  .SYNOPSIS
  Terminates a running WSL distro.
  #>
  param(
    [Parameter(Mandatory)]
    [string]$DistroName
  )
  
  Write-Info "Terminating distro '$DistroName'"
  & wsl.exe -t "$DistroName" 2>$null | Out-Null
}

function Stop-AllWsl {
  <#
  .SYNOPSIS
  Shuts down all WSL instances.
  #>
  Write-Info "Shutting down all WSL instances"
  & wsl.exe --shutdown
}

# ============================================================================
# Repo Path Detection
# ============================================================================

function Get-RepoNixosPath {
  <#
  .SYNOPSIS
  Auto-detects the nixos/ subdirectory from script location.
  Assumes script is in <repo>/scripts/ and nixos flake is in <repo>/nixos/.
  #>
  param(
    [Parameter(Mandatory)]
    [string]$ScriptPath
  )
  
  $scriptDir = Split-Path -Parent $ScriptPath
  $repoRoot = Split-Path -Parent $scriptDir
  $nixosPath = Join-Path $repoRoot 'nixos'
  
  if (Test-Path $nixosPath) {
    Write-Info "Using repo path: $nixosPath"
    return $nixosPath
  }
  else {
    Write-Warn "Repo nixos directory not found at $nixosPath"
    return $null
  }
}

