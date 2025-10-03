<#
.SYNOPSIS
  Generate a self-signed root CA and issue a server certificate for the WAF (Windows / PowerShell).

.DESCRIPTION
  Creates a development certificate chain:
    - Root CA (if not already exists)
    - Server key + certificate signed by that CA
  Supports SAN entries for domain, wildcard, localhost, and 127.0.0.1.

.PARAMETER Domain
  Primary domain name (default: localhost)

.PARAMETER Days
  Validity period in days (default: 825)

.EXAMPLE
  ./scripts/generate_cert.ps1 -Domain localhost -Days 825
#>
param(
  [string]$Domain = "localhost",
  [int]$Days = 825,
  [string]$OutDir = "certs",
  [int]$Bits = 4096,
  [string]$Country = "TH",
  [string]$Org = "PingoraWAF"
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command openssl -ErrorAction SilentlyContinue)) {
  Write-Error "OpenSSL not found in PATH. Please install OpenSSL first."
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Set-Location $OutDir

$caKey = Join-Path (Get-Location) 'rootCA.key'
$caCrt = Join-Path (Get-Location) 'rootCA.pem'
$serialFile = Join-Path (Get-Location) 'rootCA.srl'
$serverKey = Join-Path (Get-Location) 'server.key'
$serverCsr = Join-Path (Get-Location) 'server.csr'
$serverCrt = Join-Path (Get-Location) 'server.crt'

if (-not (Test-Path $caKey)) {
  Write-Host "[+] Generating root CA key ($Bits bits)"
  openssl genrsa -out $caKey $Bits | Out-Null
}

if (-not (Test-Path $caCrt)) {
  Write-Host "[+] Generating root CA certificate"
  $caCfg = @"
[ req ]
prompt = no
default_md = sha256
distinguished_name = dn

[ dn ]
C = $Country
O = $Org
OU = DevCA
CN = $Org Root CA
"@
  $caCfgPath = Join-Path (Get-Location) 'ca.cnf'
  $caCfg | Out-File -FilePath $caCfgPath -Encoding ascii
  openssl req -x509 -new -nodes -key $caKey -sha256 -days $Days -config $caCfgPath -out $caCrt | Out-Null
}

Write-Host "[+] Generating server key"
openssl genrsa -out $serverKey $Bits | Out-Null

$csrCnf = @"
[req]
default_bits = $Bits
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
C=$Country
O=$Org
OU=Dev
CN=$Domain

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $Domain
DNS.2 = *.$Domain
DNS.3 = localhost
IP.1 = 127.0.0.1
"@

$csrCnfPath = Join-Path (Get-Location) 'server.csr.cnf'
$csrCnf | Out-File -FilePath $csrCnfPath -Encoding ascii

$extFile = @"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName=@alt_names

[alt_names]
DNS.1 = $Domain
DNS.2 = *.$Domain
DNS.3 = localhost
IP.1 = 127.0.0.1
"@
$extPath = Join-Path (Get-Location) 'server.ext'
$extFile | Out-File -FilePath $extPath -Encoding ascii

Write-Host "[+] Creating CSR"
openssl req -new -key $serverKey -out $serverCsr -config $csrCnfPath | Out-Null

Write-Host "[+] Signing server certificate with root CA"
openssl x509 -req -in $serverCsr -CA $caCrt -CAkey $caKey -CAcreateserial -out $serverCrt -days $Days -sha256 -extfile $extPath | Out-Null

Write-Host "[+] Done. Generated files:"
Get-ChildItem $serverKey, $serverCrt, $caCrt | Select-Object Name, Length

Write-Host "`n[i] Configure your config.yaml tls section, e.g.:"
$pwdPath = (Get-Location).Path -replace '\\','/'
Write-Host "tls:`n  cert_path: $pwdPath/server.crt`n  key_path: $pwdPath/server.key"
