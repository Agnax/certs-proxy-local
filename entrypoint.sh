#!/bin/ash

CERT_PATH="/certs/local-dev.crt"
KEY_PATH="/certs/local-dev.key"
DAYS_VALID=365
CADDYFILE="/etc/caddy/Caddyfile"

# Obtener dominios del entorno
DOMAINS_ARRAY=$(echo "$DOMAINS" | tr ',' ' ')

# Obtener el primer dominio para CN
FIRST_DOMAIN=$(echo "$DOMAINS" | cut -d',' -f1 | cut -d':' -f1)

# Generar certificado autofirmado si no existe
if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
  echo "Generando certificado autofirmado para desarrollo..."

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
  echo "IP.2 = ::1" >> "$OPENSSL_CONF"

  openssl req -x509 -nodes -days "$DAYS_VALID" \
    -newkey rsa:2048 \
    -keyout "$KEY_PATH" \
    -out "$CERT_PATH" \
    -config "$OPENSSL_CONF" \
    -extensions req_ext

  rm "$OPENSSL_CONF"
else
  echo "Certificados ya existen. Usando los existentes."
fi

# Generar archivo Caddyfile limpio
echo "" > "$CADDYFILE"

for ENTRY in $DOMAINS_ARRAY; do
  DOMAIN=$(echo "$ENTRY" | cut -d':' -f1)
  PORT=$(echo "$ENTRY" | cut -d':' -f2)

  echo "$DOMAIN {" >> "$CADDYFILE"
  echo "  tls $CERT_PATH $KEY_PATH" >> "$CADDYFILE"
  echo "  reverse_proxy host.docker.internal:$PORT" >> "$CADDYFILE"
  echo "}" >> "$CADDYFILE"
  echo "" >> "$CADDYFILE"
done

# Mostrar el archivo generado para debug
echo "Archivo Caddyfile generado:"
cat "$CADDYFILE"

# Validar sintaxis del archivo
caddy validate --config "$CADDYFILE" --adapter caddyfile || exit 1

# Ejecutar Caddy
exec caddy run --config "$CADDYFILE" --adapter caddyfile
