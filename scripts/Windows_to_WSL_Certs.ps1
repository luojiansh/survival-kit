<#
This script will export certificates based on your input from the Windows Certificate store and add it to your WSL Distro certificate store.
Requirements:
    1. You have an idea of the certificate issuer and name.
    2. You have WSL installed.
Usage:
    .\Windows_to_WSL_Certs.ps1 Company1 Company2 Company3
#>

param(
    [Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Companies
)

# Display the companies being searched
Write-Host "Searching for certificates matching: " -ForegroundColor Cyan -NoNewline
Write-Host ($Companies -join ", ") -ForegroundColor Yellow
try {
    # Get path in WSL env
    $wsl_path = wsl pwd
}
catch {
    Write-Host "WSL not found - Please install WSL and try again." -ForegroundColor Red
}

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
}
else {
    # Create a single combined certificate file
    $combined_file_name = "combined_certs.pem"
    $combined_file_path = "C:\workspace\$combined_file_name"
    
    # Remove existing combined file if it exists
    if (Test-Path $combined_file_path) {
        Remove-Item $combined_file_path
    }
    
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
    
    # Move the combined file to WSL certificate store
    if ($cert_count -gt 0) {
        wsl -d NixOS -u jian -e sh -c "mv $wsl_path/$combined_file_name ~/certs/"
        Write-Host "`nImported " -ForegroundColor Green -NoNewLine
        Write-Host $cert_count -ForegroundColor Cyan -NoNewLine
        Write-Host " certificates to " -ForegroundColor Green -NoNewLine
        Write-Host $combined_file_name -ForegroundColor Red -NoNewLine
        Write-Host " in WSL Certificate store" -ForegroundColor Green
    }
}
