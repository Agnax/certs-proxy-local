# 🧪 Dev Reverse Proxy con Caddy + Certificados Locales

Este proyecto configura un **reverse proxy local escalable** usando [Caddy](https://caddyserver.com/) y certificados TLS autofirmados, ideal para entornos de desarrollo. Permite agregar múltiples dominios personalizados a través de un simple archivo `.env`.

---

## 🧱 Características

- 🔁 Reverse proxy para múltiples dominios locales.
- 🔐 Certificados TLS autofirmados generados automáticamente.
- 🌐 Soporte para cualquier número de dominios/backend.
- 🔧 Configuración desde `.env`.
- 🐳 Basado en Docker + Alpine (ligero).

---

## 📦 Estructura del proyecto

.
├── certs/ # Certificados TLS autofirmados (se generan al iniciar)
├── docker-compose.yml
├── Dockerfile
├── entrypoint.sh # Script de arranque: genera certificados y Caddyfile dinámico
├── Caddyfile # Archivo generado automáticamente (no editar manualmente)
├── .env # Configuración de dominios y puertos
└── README.md

---

## 🛠️ Requisitos

- Docker
- Docker Compose

---

## ⚙️ Configuración

### 1. Define tus dominios en `.env`

Crea un archivo `.env` en la raíz del proyecto con el siguiente formato:

```env
DOMAINS=frontend.lan.dev:5173,api.lan.dev:3000,socket.lan.dev:8081
```
Cada entrada tiene el formato: dominio:puerto

Puedes agregar tantos dominios como quieras, separados por comas.

Ejemplo extendido:

```.env
DOMAINS=app1.lan.dev:4000,app2.lan.dev:4001,admin.lan.dev:9000
```
2. Agrega tus dominios al archivo hosts
Para que tu máquina reconozca estos dominios localmente, agrega las entradas a tu archivo hosts.

Linux/macOS:
```
sudo nano /etc/hosts
```
Windows (Ejecutar como administrador):
```
C:\Windows\System32\drivers\etc\hosts
```
Agrega:
```
127.0.0.1 frontend.lan.dev
127.0.0.1 api.lan.dev
127.0.0.1 socket.lan.dev
```
# Agrega más según tu .env
🚀 Cómo iniciar
1. Construir y levantar el contenedor
```
docker-compose up --build
```
Este comando:

Generará certificados autofirmados si no existen.

Creará un Caddyfile basado en tu .env.

Iniciará Caddy con reverse proxy activo.

✅ Verificación
Abre tus dominios configurados en el navegador:

https://frontend.lan.dev

https://api.lan.dev

etc.

Es normal que el navegador marque el certificado como "no confiable". Puedes confiarlo manualmente en tu sistema si lo deseas.

🔄 Agregar nuevos dominios
Edita tu archivo .env y añade nuevas entradas.

Asegúrate de agregarlos al archivo hosts.

Reinicia el contenedor:
```
docker-compose down
docker-compose up --build
```
Los certificados y la configuración se regeneran automáticamente.

📌 Notas adicionales
Los certificados se almacenan en el volumen ./certs/. Puedes borrarlos para regenerarlos.

Este entorno está diseñado solo para desarrollo local, no producción.

Todos los proxys apuntan a host.docker.internal, que funciona para acceder a servicios corriendo en tu máquina desde dentro del contenedor.

📈 Futuras mejoras (opcional)
- Crear un dashboard web para editar dominios y reiniciar Caddy.

- Soporte para regeneración en caliente sin reiniciar el contenedor.

- Validación automática de puertos y dominios.

🧼 Limpieza
Si necesitas limpiar los certificados y la configuración generada:
```
docker-compose down
rm -rf certs/*
```
🧑‍💻 Créditos
Proyecto desarrollado por Agnax — inspirado en la facilidad de uso de herramientas como nginx-proxy-manager, pero adaptado a un entorno local con certificados autofirmados y alta flexibilidad.

---