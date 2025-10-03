#!/usr/bin/env bash
# Simple certificate generation script for development/testing.
# Generates a self-signed root CA and issues a server certificate usable by the WAF.
# Usage: ./scripts/generate_cert.sh [domain] [days]
# Example: ./scripts/generate_cert.sh localhost 825
set -euo pipefail
# Enable debug tracing if DEBUG=1 is set
if [[ "${DEBUG:-0}" == "1" ]]; then
  set -x
fi

DOMAIN=${1:-localhost}
DAYS=${2:-825}
OUT_DIR=${OUT_DIR:-certs}
BITS=${BITS:-4096}
COUNTRY=${COUNTRY:-TH}
ORG=${ORG:-PingoraWAF}
CA_SUBJECT="/C=${COUNTRY}/O=${ORG}/OU=DevCA/CN=${ORG} Root CA" # Kept for reference
SERVER_SUBJECT="/C=${COUNTRY}/O=${ORG}/OU=Dev/CN=${DOMAIN}"    # Kept for reference

mkdir -p "$OUT_DIR"
cd "$OUT_DIR"

if [[ ! -f rootCA.key ]]; then
  echo "[+] Generating root CA key (${BITS} bits)"
  openssl genrsa -out rootCA.key ${BITS} || { echo "[!] Failed to generate root CA key" >&2; exit 1; }
fi

if [[ ! -f rootCA.pem ]]; then
  echo "[+] Generating root CA certificate (using config to avoid MSYS path conversion issues)"
  cat > ca.cnf <<EOF
[ req ]
prompt = no
default_md = sha256
distinguished_name = dn

[ dn ]
C = ${COUNTRY}
O = ${ORG}
OU = DevCA
CN = ${ORG} Root CA
EOF
  openssl req -x509 -new -nodes -key rootCA.key -sha256 -days ${DAYS} \
    -config ca.cnf -out rootCA.pem || { echo "[!] Failed to create root CA certificate" >&2; exit 1; }
fi

echo "[+] Generating server key"
openssl genrsa -out server.key ${BITS} || { echo "[!] Failed to generate server key" >&2; exit 1; }

cat > server.csr.cnf <<EOF
[req]
default_bits = ${BITS}
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C=${COUNTRY}
O=${ORG}
OU=Dev
CN=${DOMAIN}

[SAN]
subjectAltName=DNS:${DOMAIN},DNS:*.${DOMAIN},IP:127.0.0.1
EOF

cat > server.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN}
DNS.3 = localhost
IP.1 = 127.0.0.1
EOF

echo "[+] Creating CSR"
openssl req -new -key server.key -out server.csr -config server.csr.cnf || { echo "[!] Failed to create server CSR" >&2; exit 1; }

echo "[+] Signing server certificate with root CA"
openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial \
  -out server.crt -days ${DAYS} -sha256 -extfile server.ext || { echo "[!] Failed to sign server certificate" >&2; exit 1; }

if [[ ! -s server.crt ]]; then
  echo "[!] server.crt not created. Enable DEBUG=1 and re-run to see details." >&2
  exit 1
fi

echo "[+] Done. Artifacts in $(pwd):"
ls -1 server.key server.crt rootCA.pem || true

echo "[i] Configure your config.yaml tls.cert_path and tls.key_path, e.g.:"
echo "tls:\n  cert_path: $(pwd | sed 's|\\|/|g')/server.crt\n  key_path: $(pwd | sed 's|\\|/|g')/server.key"
