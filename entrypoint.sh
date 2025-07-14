#!/bin/sh

CERT_PATH="/certs/localhost.crt"
KEY_PATH="/certs/localhost.key"
DAYS_VALID=365

# Generate self-signed certificates if they do not exist
if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
  echo "Generating self-signed certificates..."

  OPENSSL_CONF=$(mktemp)
  cat > "$OPENSSL_CONF" <<EOF
  [req]
  default_bits = 2048
  prompt = no
  default_md = sha256
  distinguished_name = req_distinguished_name
  req_extensions = req_ext

  [req_distinguished_name]
  CN = localhost

  [req_ext]
  subjectAltName = @alt_names

  [alt_names]
EOF

  I=1
  IFS=',' read -ra HOSTS <<< "$DOMAINS"
  for ENTRY in "${HOSTS[@]}"; do
    DOMAIN=$(echo "$ENTRY" | cut -d':' -f1)
    echo "DNS.${I} = ${DOMAIN}" >> "$OPENSSL_CONF"
    I=$((I+1))
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
  echo "Certificates already exist."
fi

# Generate Caddyfile dynamically
CADDYFILE="/etc/caddy/Caddyfile"
echo "localhost {" > "$CADDYFILE"
echo "  tls /certs/localhost.crt /certs/localhost.key" >> "$CADDYFILE"

IFS=',' read -ra DOMAINS_ARRAY <<< "$DOMAINS"
for ENTRY in "${DOMAINS_ARRAY[@]}"; do
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
