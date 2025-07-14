FROM caddy:2-alpine

RUN apk add --no-cache openssl dos2unix

COPY entrypoint.sh /entrypoint.sh

# Convertimos a formato Unix por si viene de Windows
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
