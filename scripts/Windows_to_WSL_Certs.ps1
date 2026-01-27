<#
This script will export certificates based on your input from the Windows Certificate store and add it to your WSL Distro certificate store.
If a valid input certificate file is provided, it will use that instead of generating.
Requirements:
    1. You have an idea of the certificate issuer and name (when generating).
    2. You have WSL installed.
Usage:
    # Generate from Windows store
    .\Windows_to_WSL_Certs.ps1 -Distro NixOS -User jian -OutputPath "/etc/nixos/ca-certificates.crt" Company1 Company2
    
    # Use existing certificate file
    .\Windows_to_WSL_Certs.ps1 -Distro NixOS -User jian -InputPath "C:\certs\ca.crt" -OutputPath "/etc/nixos/ca-certificates.crt"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Distro,

    [Parameter(Mandatory = $true)]
    [string]$User,
    
    [Parameter()]
    [string]$InputPath,

    [Parameter()]
    [string]$OutputPath,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Companies
)

# Validate parameters
if (-not $OutputPath) {
    Write-Host "Error: -OutputPath parameter is required." -ForegroundColor Red
    exit 1
}

# Display the search parameters
Write-Host "WSL Distro: " -ForegroundColor Cyan -NoNewline
Write-Host $Distro -ForegroundColor Yellow -NoNewline
Write-Host " | User: " -ForegroundColor Cyan -NoNewline
Write-Host $User -ForegroundColor Yellow
Write-Host "Output Path: " -ForegroundColor Cyan -NoNewline
Write-Host $OutputPath -ForegroundColor Yellow

# Check if valid InputPath was provided
if ($InputPath -and (Test-Path $InputPath)) {
    Write-Host "Using provided certificate file: " -ForegroundColor Green -NoNewline
    Write-Host $InputPath -ForegroundColor Yellow
    
    try {
        # Convert Windows path to WSL path (Unix style) - need to escape backslashes
        $escapedInputPath = $InputPath -replace '\\', '\\'
        $inputWslPath = wsl wslpath -u "$escapedInputPath"
        
        # Get parent directory of output path
        $outputDir = Split-Path -Parent $OutputPath
        
        # Copy using WSL as the specified user (handles permissions correctly)
        wsl -d $Distro -u $User -e sh -c "mkdir -p '$outputDir' && sudo cp '$inputWslPath' '$OutputPath' && sudo chmod 644 '$OutputPath'"
        
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
if (-not $Companies -or $Companies.Count -eq 0) {
    Write-Host "No valid certificate file provided and no companies specified for generation." -ForegroundColor Red
    Write-Host "Usage: Provide -InputPath or specify company names to search" -ForegroundColor Yellow
    exit 1
}

Write-Host "Searching for certificates matching: " -ForegroundColor Cyan -NoNewline
Write-Host ($Companies -join ", ") -ForegroundColor Yellow

# Get a list of all Certificates in Local Machine store where either the Issuer or Subject contains any of the company names
$all_certs = @(Get-ChildItem -path Cert:\LocalMachine\* -Recurse | Where-Object {
        $cert = $_
        $match = $false
        foreach ($company in $Companies) {
            if ($cert.Issuer -like "*$company*" -or $cert.Subject -like "*$company*") {
                $match = $true
                break
            }
        }
        $match
    } | Select-Object -Property * )
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
            # Convert Windows temp path to WSL path (Unix style) - need to escape backslashes
            $escapedTempPath = $combined_file_path -replace '\\', '\\'
            $tempWslPath = wsl wslpath -u "$escapedTempPath"
            
            # Get parent directory of output path
            $outputDir = Split-Path -Parent $OutputPath
            
            # Copy using WSL as the specified user (handles permissions correctly)
            wsl -d $Distro -u $User -e sh -c "mkdir -p '$outputDir' && cp '$tempWslPath' '$OutputPath' && chmod 644 '$OutputPath'"
            
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
