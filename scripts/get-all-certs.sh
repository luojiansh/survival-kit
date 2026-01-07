#!/usr/bin/env bash

set -eu

function main() {
	if [ "$(id -u)" != "0" ]
	then
		echo "Must be running as root."
		exit 1
	fi

	POWERSHELL="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
	WIN_USER="$("${POWERSHELL}" "\$env:UserName" | tr -d '\n\r')"
	CERTS_DIR="/mnt/c/tmp"
	OUTPUT_CERTS_DIR="/usr/local/share/ca-certificates"

	"${POWERSHELL}" "Set-ExecutionPolicy Bypass -Scope CurrentUser"

	tempdir=$(mktemp -d -p "${CERTS_DIR}")
	trap "rm -rf ${tempdir}" EXIT

	echo "Running as UID $(id -u) in directory ${tempdir}"

	cd "${tempdir}"
	"${POWERSHELL}" "${SCRIPT_CONTENT}"

	rm -rf ${OUTPUT_CERTS_DIR}
	cp -r "${tempdir}/all-certificates" "${OUTPUT_CERTS_DIR}"

	update-ca-certificates
}

SCRIPT_CONTENT=$'# Fetches all certificates into a directory called "all-certificates"

$StoreToDir = "all-certificates"
$InsertLineBreaks=1

If (Test-Path $StoreToDir) {
    $path = "{0}\\*" -f $StoreToDir
    Remove-Item $StoreToDir -Recurse -Force
}
New-Item $StoreToDir -ItemType directory

Get-ChildItem -Recurse cert: `
  | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509Certificate2] } `
  | ForEach-Object {
    $name = $_.Subject -replace \'[\\W]\', \'_\'
    $oPem=new-object System.Text.StringBuilder
    [void]$oPem.AppendLine("-----BEGIN CERTIFICATE-----")
    [void]$oPem.AppendLine([System.Convert]::ToBase64String($_.RawData,$InsertLineBreaks))
    [void]$oPem.AppendLine("-----END CERTIFICATE-----")

    $path = "{0}\\{1}.crt" -f $StoreToDir,$name

    # the exported list of certificates contains certificates with similar subject
    # let\'s put them in separate indexed files
    $idx = 0
    While (Test-Path $path) {
      $idx++
      $path = "{0}\\{1}--{2}.crt" -f $StoreToDir,$name,$idx
    }
    If ($idx -gt 0) {
      $path
    }

    # TODO unfortunately same certificates duplicates each other
    # it\'s better to add a check for duplicates just here

    $oPem.toString() | add-content $path
    #Exit(0)
  }

# The End'

main
