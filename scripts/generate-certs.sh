#!/usr/bin/env bash
# generate-certs.sh - Generate a local Root CA and wildcard *.lab certificate
# Extracted from docs/03-security.md
# Run on the Ubuntu server. Output files go to ~/certs.

set -euo pipefail

CERTS_DIR="$HOME/certs"

echo "=== Local SSL Certificate Generator ==="
echo "Output directory: $CERTS_DIR"
echo ""

mkdir -p "$CERTS_DIR"
cd "$CERTS_DIR"

# ---------------------------------------------------------------------------
# Step 1: Create the Root CA
# ---------------------------------------------------------------------------
echo "[1/4] Generating Root CA private key..."
echo "You will be prompted to set a passphrase. Keep this safe!"
openssl genrsa -des3 -out rootCA.key 2048

echo ""
echo "[2/4] Generating Root CA certificate (valid 10 years)..."
echo "When prompted for Common Name (CN), enter something like: Omar Lab Root CA"
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem

# ---------------------------------------------------------------------------
# Step 2: Create the Wildcard *.lab Certificate
# ---------------------------------------------------------------------------
echo ""
echo "[3/4] Generating wildcard *.lab private key and CSR..."
echo "When prompted for Common Name (CN), enter: *.lab"
openssl genrsa -out star_lab.key 2048
openssl req -new -key star_lab.key -out star_lab.csr

# Create the SAN extension file required by modern browsers
cat > v3.ext <<'EOF'
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.lab
DNS.2 = lab
EOF

# ---------------------------------------------------------------------------
# Step 3: Sign the Certificate with the Root CA
# ---------------------------------------------------------------------------
echo ""
echo "[4/4] Signing the wildcard certificate with the Root CA..."
openssl x509 -req \
    -in star_lab.csr \
    -CA rootCA.pem \
    -CAkey rootCA.key \
    -CAcreateserial \
    -out star_lab.crt \
    -days 3650 \
    -sha256 \
    -extfile v3.ext

echo ""
echo "=== Certificate generation complete! ==="
echo ""
echo "Files created in $CERTS_DIR:"
ls -lh "$CERTS_DIR"
echo ""
echo "Next steps:"
echo "  1. Copy rootCA.pem to your client machines and install as a Trusted Root CA."
echo "     - Windows: rename to rootCA.crt, double-click > Install Certificate"
echo "       > Local Machine > Trusted Root Certification Authorities"
echo "  2. Copy star_lab.crt and star_lab.key to infrastructure/traefik/certs/"
echo "     cp $CERTS_DIR/star_lab.crt /path/to/infrastructure/traefik/certs/"
echo "     cp $CERTS_DIR/star_lab.key /path/to/infrastructure/traefik/certs/"
