FROM caddy:2-alpine

# Instala openssl en Alpine
RUN apk add --no-cache openssl

# Copia los archivos necesarios
COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
