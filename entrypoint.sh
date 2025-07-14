#!/bin/ash

CERT_PATH="/certs/local-dev.crt"
KEY_PATH="/certs/local-dev.key"
DAYS_VALID=365

# Parse domain list from DOMAINS
DOMAINS_ARRAY=$(echo "$DOMAINS" | tr ',' ' ')

# Extract first domain for CN
FIRST_DOMAIN=$(echo "$DOMAINS" | cut -d',' -f1 | cut -d':' -f1)

# Generate self-signed certificates if they do not exist
if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
  echo "Generating self-signed certificate for development..."

  OPENSSL_CONF=$(mktemp)
  cat > "$OPENSSL_CONF" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = req_distinguished_name
req_extensions = req_ext

[req_distinguished_name]
CN = $FIRST_DOMAIN

[req_ext]
subjectAltName = @alt_names

[alt_names]
EOF

  I=1
  for ENTRY in $DOMAINS_ARRAY; do
    DOMAIN=$(echo "$ENTRY" | cut -d':' -f1)
    echo "DNS.${I} = ${DOMAIN}" >> "$OPENSSL_CONF"
    I=$((I + 1))
  done

  echo "IP.1 = 127.0.0.1" >> "$OPENSSL_CONF"

  openssl req -x509 -nodes -days "$DAYS_VALID" \
    -newkey rsa:2048 \
    -keyout "$KEY_PATH" \
    -out "$CERT_PATH" \
    -config "$OPENSSL_CONF" \
    -extensions req_ext

  rm "$OPENSSL_CONF"
else
  echo "Certificate already exists."
fi

# Generate Caddyfile dynamically
CADDYFILE="/etc/caddy/Caddyfile"
echo "localhost {" > "$CADDYFILE"
echo "  tls /certs/local-dev.crt /certs/local-dev.key" >> "$CADDYFILE"

for ENTRY in $DOMAINS_ARRAY; do
  DOMAIN=$(echo "$ENTRY" | cut -d':' -f1)
  PORT=$(echo "$ENTRY" | cut -d':' -f2)

  echo "" >> "$CADDYFILE"
  echo "  @${DOMAIN%%.*} {" >> "$CADDYFILE"
  echo "    host $DOMAIN" >> "$CADDYFILE"
  echo "  }" >> "$CADDYFILE"
  echo "  reverse_proxy @${DOMAIN%%.*} host.docker.internal:$PORT" >> "$CADDYFILE"
done

echo "}" >> "$CADDYFILE"

cat "$CADDYFILE"

exec caddy run --config "$CADDYFILE" --adapter caddyfile
