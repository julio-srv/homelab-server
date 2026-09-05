# 📘 Manual de Configuración del Servidor Doméstico - Netbook Conectar Igualdad

*Última actualización: 26 de agosto de 2026*

## Índice

1. [Introducción y Objetivo](#1-introducción-y-objetivo)
2. [Hardware Utilizado](#2-hardware-utilizado)
3. [Instalación del Sistema Operativo (Debian 12 "Bookworm")](#3-instalación-del-sistema-operativo-debian-12-bookworm)
4. [Acceso Remoto por SSH](#4-acceso-remoto-por-ssh)
5. [Instalación de Docker y Portainer](#5-instalación-de-docker-y-portainer)
6. [Configuración de Dominio Gratuito y Cloudflare](#6-configuración-de-dominio-gratuito-y-cloudflare)
7. [Estado del Proyecto (primera fase)](#7-estado-del-proyecto-primera-fase)
8. [Próximos Pasos (en ese momento)](#8-próximos-pasos-en-ese-momento)
9. [Comandos y Archivos Clave](#9-comandos-y-archivos-clave)
10. [Registro de Errores y Soluciones](#10-registro-de-errores-y-soluciones)
11. [Configuración de Cloudflare Tunnel (Continuación)](#11-configuración-de-cloudflare-tunnel-continuación-y-resolución-de-errores)
12. [Estado Final del Proyecto (Actualizado)](#12-estado-final-del-proyecto-actualizado)
13. [Accesos y Credenciales](#13-accesos-y-credenciales)
14. [Comandos Útiles para el Día a Día](#14-comandos-útiles-para-el-día-a-día)
15. [Próximos Pasos (Ampliaciones Futuras)](#15-próximos-pasos-ampliaciones-futuras)
16. [Seguridad y Buenas Prácticas](#16-seguridad-y-buenas-prácticas)
17. [Conclusión](#17-conclusión)

---

## 1. Introducción y Objetivo

Este proyecto consiste en convertir una netbook del gobierno (modelo Gen 4/5) en un servidor local accesible desde Internet, utilizando herramientas libres y gratuitas. El objetivo es desplegar servicios en contenedores Docker y exponerlos de forma segura usando Cloudflare Tunnel.

**Objetivos específicos:**

- Tener un servidor estable 24/7 con bajo consumo eléctrico.
- Acceder a los servicios desde cualquier lugar sin necesidad de VPN.
- Aprender y documentar el proceso para futuras referencias.

---

## 2. Hardware Utilizado

| Componente | Especificación |
|---|---|
| Modelo | Netbook Conectar Igualdad (Gen 4 o 5) |
| Procesador | Intel Celeron / Atom (64 bits) |
| RAM | 4 GB DDR3 |
| Almacenamiento | Disco duro HDD de 500 GB (o eMMC) |
| Batería | Retirada físicamente para evitar sobrecalentamiento y riesgos (se usa solo con cargador) |
| Conexión | WiFi y Ethernet (se usa cable para mayor estabilidad) |

> **Decisión clave:** Se retiró la batería para evitar inflado, reducir temperatura interna y alargar la vida útil del hardware.

---

## 3. Instalación del Sistema Operativo (Debian 12 "Bookworm")

Versión instalada: Debian 12.9.0 (netinst) para arquitectura amd64.

### 3.1. Descarga del ISO

Se descargó la imagen `debian-12.9.0-amd64-netinst.iso` desde el enlace oficial:

```
https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.9.0-amd64-netinst.iso
```

### 3.2. Creación del USB booteable

Se utilizó Rufus 4.x en Windows:

- Seleccionar el pendrive (mínimo 2 GB).
- Elegir el archivo ISO descargado.
- Modo de escritura: DD (recomendado para Debian).

### 3.3. Pasos de instalación

- Arranque desde el USB (tecla F12 al encender).
- Seleccionar "Graphical install".
- Configuración regional: Español, Argentina, Latinoamericano.
- Hostname: `servidor-netbook` (o el que elijas).
- Contraseña de root: se dejó vacía (se usará sudo con el usuario normal).
- Creación de usuario: `tuusuario` con su contraseña.
- Particionado: "Guiado - usar todo el disco" y "Todos los archivos en una sola partición".
- Selección de software: solo marcar "Servidor SSH" (desmarcar entorno de escritorio y otros).
- Instalación del bootloader GRUB en `/dev/sda`.

### 3.4. Primera configuración post-instalación

Actualización del sistema:

```bash
sudo apt update && sudo apt upgrade -y
```

Instalación de herramientas útiles:

```bash
sudo apt install -y ufw vim curl wget git htop
```

Configuración de IP fija (editar `/etc/network/interfaces`):

```
auto enp0s3
iface enp0s3 inet static
address 192.168.1.100  # (ajustar a tu red)
netmask 255.255.255.0
gateway 192.168.1.1
dns-nameservers 8.8.8.8 8.8.4.4
```

Firewall (UFW):

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable
```

### 3.5. Evitar suspensión al cerrar la tapa

Se editó `/etc/systemd/logind.conf` y se cambiaron:

```
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
```

Luego se reinició el servicio:

```bash
sudo systemctl restart systemd-logind
```

---

## 4. Acceso Remoto por SSH

Desde otra PC en la misma red, se conectó con:

```bash
ssh tuusuario@192.168.1.100
```

El acceso funciona correctamente. La netbook ya no se duerme al cerrar la tapa.

### 4.1. Instalación de ZeroTier (Acceso SSH desde cualquier lugar)

ZeroTier crea una red privada virtual (VPN) que permite acceder al servidor desde cualquier lugar sin necesidad de abrir puertos en el router. Es una alternativa segura y gratuita para tener acceso SSH incluso si el dominio de Cloudflare falla.

```bash
curl -s https://install.zerotier.com | sudo bash
```

### 4.2. Unirse a la red ZeroTier

1. Crear una red en [my.zerotier.com](https://my.zerotier.com) (gratis para hasta 25 dispositivos).
2. Anotar el Network ID (ej: `a1b2c3d4e5f6g7h8`).
3. En el servidor, unirse a la red:

   ```bash
   sudo zerotier-cli join a1b2c3d4e5f6g7h8
   ```

4. Autorizar el dispositivo desde el panel web de ZeroTier (marcar como "Authorized").
5. Verificar la IP asignada:

   ```bash
   sudo zerotier-cli listnetworks
   ```

   Aparecerá una IP como `192.168.192.xxx`.

### 4.3. Conectarse por SSH vía ZeroTier

Desde cualquier dispositivo con ZeroTier instalado (y en la misma red), conectarse con:

```bash
ssh julio@192.168.192.xxx
```

**Ventaja:** No depende de DNS ni de puertos abiertos. Funciona incluso si el dominio de Cloudflare falla.

### 4.4. Configurar ZeroTier para que inicie automáticamente

ZeroTier se instala como servicio systemd. Verificar su estado:

```bash
sudo systemctl status zerotier-one
```

Si no está activo, habilitarlo:

```bash
sudo systemctl enable zerotier-one
sudo systemctl start zerotier-one
```

---

## 5. Instalación de Docker y Portainer

### 5.1. Instalación de Docker

Se siguió la guía oficial para Debian:

```bash
# Agregar clave GPG
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Agregar repositorio
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Instalar Docker
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Se agregó el usuario al grupo docker para evitar usar sudo en cada comando:

```bash
sudo usermod -aG docker tuusuario
```

### 5.2. Instalación de Portainer

Se desplegó Portainer con el siguiente comando:

```bash
docker volume create portainer_data
docker run -d -p 9000:9000 -p 9443:9443 \
  --name portainer \
  --restart=unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

Portainer está accesible localmente en `http://192.168.1.100:9000`.

---

## 6. Configuración de Dominio Gratuito y Cloudflare

### 6.1. Obtención del dominio en DNSHE

- Se creó cuenta en [dnshe.com](https://www.dnshe.com).
- Se registró el dominio gratuito: `miservidor.de5.net` (elegir uno disponible).
- (En tu caso, el dominio elegido será el que hayas seleccionado).

### 6.2. Configuración en Cloudflare

- Se agregó el dominio a Cloudflare (plan gratuito).
- Cloudflare asignó dos servidores DNS (ej: `anna.ns.cloudflare.com` y `hank.ns.cloudflare.com`).

### 6.3. Configuración en DNSHE

- Se modificaron los servidores DNS del dominio, reemplazando los predeterminados por los de Cloudflare.
- Se esperó la propagación (5-10 minutos).

### 6.4. Verificación

El dominio aparece como "Activo" en el panel de Cloudflare. Está listo para ser usado con Cloudflare Tunnel.

---

## 7. Estado del Proyecto (primera fase)

| Componente | Estado |
|---|---|
| Hardware | Funcionando sin batería, con cargador. |
| Sistema Operativo | Debian 12 instalado y actualizado. |
| Red | IP fija configurada, firewall activo. |
| Acceso SSH | Funcionando correctamente. |
| Docker | Instalado y funcionando. |
| Portainer | Accesible en `http://IP_LOCAL:9000`. |
| Dominio | `miservidor.de5.net` (o tu dominio) registrado y apuntando a Cloudflare. |
| Cloudflare Tunnel | Pendiente de instalar y configurar. |

---

## 8. Próximos Pasos (en ese momento)

A partir de este punto, la próxima fase consistió en:

1. Instalar `cloudflared` en el servidor.
2. Autenticar el túnel con Cloudflare (solución al error de `cert.pem`).
3. Crear el túnel y enrutar un subdominio (ej. `portainer.miservidor.de5.net`) hacia Portainer.
4. Desplegar servicios adicionales en Docker (Nginx, Nextcloud, etc.) y exponerlos mediante el mismo túnel.
5. Configurar SSL automático (Cloudflare lo maneja).

---

## 9. Comandos y Archivos Clave

📌 Para futura referencia:

- Archivo de configuración de red: `/etc/network/interfaces`
- Configuración de energía: `/etc/systemd/logind.conf`
- Docker instalado y funcionando.
- Volumen de Portainer: `portainer_data`
- Contenedor de Portainer: `portainer` (puerto 9000)

---

## 10. Registro de Errores y Soluciones

🗂️

| Error | Solución |
|---|---|
| `Failed to write the certificate` al hacer `cloudflared tunnel login` | Se descargará manualmente el `cert.pem` usando el enlace proporcionado y se copiará a `~/.cloudflared/cert.pem` (pendiente de ejecutar). |

> ✅ **Conclusión parcial:** El servidor está sólidamente instalado y configurado. Todas las herramientas base están listas. La documentación refleja fielmente el proceso seguido. El siguiente paso es completar la instalación de Cloudflare Tunnel para habilitar el acceso público.

---

## 11. Configuración de Cloudflare Tunnel (Continuación y Resolución de Errores)

**Objetivo:** Exponer de forma segura el panel de Portainer (y futuros servicios) a internet sin abrir puertos en el router.

### 11.1. Instalación de cloudflared

Se optó por la instalación mediante Docker, por su facilidad de gestión y actualización. Se utilizó el siguiente comando base (con el token proporcionado por Cloudflare):

```bash
docker run -d \
  --name cloudflared \
  --restart unless-stopped \
  --network host \
  cloudflare/cloudflared:latest tunnel --no-autoupdate run --token <TU_TOKEN>
```

> **Nota:** En el primer intento, se omitió el flag `--network host`, lo que provocó que el contenedor no pudiera alcanzar el servicio de Portainer en `localhost`. Este error se detectó en los logs y se solucionó posteriormente.

### 11.2. Diagnóstico y Resolución del Error 502 Bad Gateway

Al intentar acceder al dominio, se recibía un error 502 Bad Gateway. Los logs del contenedor (`docker logs cloudflared`) mostraban:

```
ERR error="Unable to reach the origin service... dial tcp [::1]:9000: connect: connection refused"
```

**Causa:** El contenedor de cloudflared no podía comunicarse con el contenedor de Portainer porque:

- `localhost` dentro del contenedor apunta a su propio espacio de red, no al del host.
- La configuración en el panel de Cloudflare apuntaba a `http://localhost:9000`.

**Solución aplicada (opción elegida):** Se forzó el uso de la red del host (`--network host`) para que el contenedor de cloudflared compartiera la pila de red del servidor, permitiendo que `localhost` resuelva correctamente al servicio.

**Pasos realizados:**

1. Se detuvo y eliminó el contenedor con errores:

   ```bash
   docker stop cloudflared
   docker rm cloudflared
   ```

2. Se volvió a crear el contenedor con el flag `--network host` y el mismo token.
3. Se verificaron los logs para confirmar que el túnel se registraba correctamente y no mostraba errores de conexión.
4. Se reinició el contenedor de Portainer para desbloquear la interfaz web:

   ```bash
   docker restart portainer
   ```

### 11.3. Configuración en el Panel de Cloudflare (Zero Trust)

- **Túnel:** Se creó un túnel con nombre `mi-tunel` (o similar) desde el panel de Cloudflare.
- **Hostname Público:** Se añadió un registro DNS para el subdominio `xxxx.xxx.com` (o el dominio elegido).
- **Servicio:** Se configuró el servicio para que apunte a `http://localhost:9000`, que ahora es alcanzable gracias a la red del host.

### 11.4. Verificación Final

- El dominio `https://xxxx.xxx.com` (o el correspondiente) devuelve la interfaz de Portainer.
- No se abrieron puertos en el router. La conexión es segura (SSL/TLS gestionado por Cloudflare).
- El contenedor cloudflared se reinicia automáticamente si falla (gracias a `--restart unless-stopped`).

### 11.5. Comandos de Mantenimiento

Ver logs del túnel:

```bash
docker logs cloudflared --tail 50 -f
```

Reiniciar el túnel:

```bash
docker restart cloudflared
```

Actualizar la imagen de cloudflared:

```bash
docker pull cloudflare/cloudflared:latest
docker stop cloudflared
docker rm cloudflared
# Volver a ejecutar el comando `docker run` con el token
```

---

## 12. Estado Final del Proyecto (Actualizado)

| Componente | Estado |
|---|---|
| Hardware | Funcionando sin batería, con cargador. |
| Sistema Operativo | Debian 12 instalado y actualizado. |
| Red | IP fija configurada, firewall activo. |
| Acceso SSH (LAN) | Funcionando en `192.168.1.100`. |
| Acceso SSH (ZeroTier) | Funcionando en `192.168.192.xxx`. |
| Docker | Instalado y funcionando. |
| Portainer | Accesible en `http://IP_LOCAL:9000` y `http://IP_ZEROTIER:9000`. |
| Dominio | `xxxx.xxx.com` apuntando a Cloudflare. |
| Cloudflare Tunnel | Activo, enrutando tráfico a Portainer en `xxxx.xxx.com`. |

---

## 13. Accesos y Credenciales

| Servicio | URL / IP | Puerto | Notas |
|---|---|---|---|
| SSH (LAN) | `192.168.1.100` | 22 | Usuario: julio |
| SSH (ZeroTier) | `192.168.192.xxx` | 22 | Usuario: julio |
| Portainer (Local) | `http://192.168.1.100` | 9000 | |
| Portainer (ZeroTier) | `http://192.168.192.xxx` | 9000 | |
| Portainer (Público) | `https://xxxx.xxx.com` | 443 | Requiere usuario y contraseña creados al primer inicio |

---

## 14. Comandos Útiles para el Día a Día

### 14.1. Reiniciar servicios

```bash
# Reiniciar Portainer (si se bloquea)
docker restart portainer

# Reiniciar Cloudflare Tunnel
docker restart cloudflared

# Reiniciar ZeroTier
sudo systemctl restart zerotier-one
```

### 14.2. Ver logs

```bash
# Logs de Portainer
docker logs portainer --tail 50

# Logs de Cloudflare Tunnel
docker logs cloudflared --tail 50

# Logs de ZeroTier
sudo journalctl -u zerotier-one -f
```

### 14.3. Ver estado de la red ZeroTier

```bash
sudo zerotier-cli listnetworks
sudo zerotier-cli status
```

### 14.4. Actualizar el sistema

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 15. Próximos Pasos (Ampliaciones Futuras)

- Migrar todos los servicios a un archivo `docker-compose.yml`.
- Añadir un servidor multimedia (Jellyfin).
- Configurar una nube personal (Nextcloud).
- Añadir un panel de monitoreo (Grafana + Prometheus).
- Automatizar backups de los volúmenes de Docker.
- Crear un script de instalación automatizada (Ansible).

---

## 16. Seguridad y Buenas Prácticas

- Firewall UFW activo → solo permite SSH (puerto 22).
- ZeroTier → acceso SSH cifrado y seguro, sin exponer puertos.
- Cloudflare Tunnel → acceso web con SSL automático, sin abrir puertos.
- No se expusieron puertos HTTP/HTTPS en el router → todo pasa por túneles.
- Contraseñas seguras para el usuario julio y para Portainer.

---

## 17. Conclusión

El servidor está completamente funcional, accesible desde cualquier lugar mediante dos métodos complementarios:

- **ZeroTier** → acceso SSH directo, independiente de DNS.
- **Cloudflare Tunnel** → acceso web a Portainer y futuros servicios, con dominio propio y SSL.

El sistema es estable, consume pocos recursos y está preparado para crecer con nuevos contenedores.
---

## 18. Despliegue de Servicios (Fase 2)

*Esta sección documenta la implementación de servicios adicionales, la configuración del proxy inverso y la exposición pública mediante Cloudflare Tunnel.*

### 18.1. Proxy Inverso con Nginx Proxy Manager (NPM)

Aunque finalmente optamos por exponer los servicios directamente con Cloudflare Tunnel, instalamos NPM como una herramienta de respaldo para futuros proyectos que requieran una gestión más granular de subdominios y certificados.

#### 18.1.1. Instalación limpia (recomendada)

Se realizó una reinstalación completa para evitar errores previos.

**Estructura de carpetas:**

```
/home/serv/docker/npm/
├── docker-compose.yml
├── data/
│   └── mysql/
└── letsencrypt/
```

**Archivo `docker-compose.yml` final:**

```yaml
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
      - '81:81'
    environment:
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "npm"
      DB_MYSQL_PASSWORD: "CAMBIAR_ESTA_PASSWORD"
      DB_MYSQL_NAME: "npm"
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    depends_on:
      - db
    networks:
      - proxy_network

  db:
    image: 'jc21/mariadb-aria:10.11.5-innodb'
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: 'CAMBIAR_ESTA_PASSWORD'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: 'npm'
      MYSQL_PASSWORD: 'CAMBIAR_ESTA_PASSWORD'   # Debe coincidir con DB_MYSQL_PASSWORD
    volumes:
      - ./data/mysql:/var/lib/mysql
    networks:
      - proxy_network

networks:
  proxy_network:
    external: true
```

> ⚠️ **Nota de seguridad:** reemplazá `CAMBIAR_ESTA_PASSWORD` por contraseñas propias y fuertes antes de desplegar. Nunca subas contraseñas reales a un repositorio, ni siquiera privado.

**Comandos de despliegue:**

```bash
# Crear la red Docker (si no existe)
docker network create proxy_network

# Levantar los contenedores
cd ~/docker/npm
docker compose up -d
```

**Acceso:**

- Interfaz web: `http://IP_LOCAL:81`
- Credenciales por defecto: `admin@example.com` / `changeme`
- **Importante:** Cambiar la contraseña al primer inicio.

#### 18.1.2. Problemas y soluciones durante la instalación

| Problema | Solución |
|----------|----------|
| `version: '3'` obsoleto | Eliminar la línea `version` del YAML. |
| Error `not found` para `mariadb-aria:10.6` | Usar `jc21/mariadb-aria:10.11.5-innodb`. |
| `network proxy_network declared as external, but could not be found` | Crear la red con `docker network create proxy_network`. |
| `Access denied for user 'npm'` | Borrar volúmenes con `docker compose down -v`, eliminar carpetas `data/` y `letsencrypt/`, y recrear. |
| Fecha incorrecta del sistema (`x509: certificate has expired`) | Sincronizar con NTP: `sudo timedatectl set-ntp true`. |

---

### 18.2. Sitio Web Estático con Nginx

Se desplegó un contenedor Nginx para servir archivos HTML/CSS/JS desde una carpeta montada.

#### 18.2.1. Creación del contenedor

```bash
# Crear la carpeta del sitio
mkdir -p /home/serv/mi_web
echo '<h1>¡Mi servidor funciona!</h1>' > /home/serv/mi_web/index.html

# Desplegar el contenedor
docker run -d \
  --name mi-sitio-web \
  --restart unless-stopped \
  -v /home/serv/mi_web:/usr/share/nginx/html:ro \
  -p 8080:80 \
  --network proxy_network \
  nginx:alpine
```

**Acceso local:** `http://IP_LOCAL:8080`

#### 18.2.2. Problema: Error 403 Forbidden

**Causa:** El archivo `index.html` tenía permisos `-rw-------` (600), impidiendo que Nginx (usuario `nginx`) pudiera leerlo.

**Solución:**

```bash
chmod 644 /home/serv/mi_web/index.html
docker restart mi-sitio-web
```

**Verificación:**

```bash
docker exec -it mi-sitio-web cat /usr/share/nginx/html/index.html
```

#### 18.2.3. Subir contenido propio desde PC

Desde tu PC local:

```bash
scp -r /ruta/local/mi_proyecto_web/* serv@IP_LOCAL:/home/serv/mi_web/
```

En el servidor (ajustar permisos):

```bash
chmod -R 644 /home/serv/mi_web/*
chmod 755 /home/serv/mi_web
docker restart mi-sitio-web
```

---

### 18.3. Exposición Pública con Cloudflare Tunnel

Se utilizó el túnel existente para exponer los servicios sin abrir puertos en el router.

#### 18.3.1. Túnel activo

El túnel ya configurado en la sección 11 se reutilizó, agregando las nuevas rutas de ingreso (`ingress`) para los servicios adicionales, apuntando cada una a su puerto interno correspondiente y devolviendo `http_status:404` para cualquier host no reconocido.

#### 18.3.2. Agregar subdominios

**Pasos desde Cloudflare Zero Trust:**

1. Ir a **Networks → Tunnels**.
2. Seleccionar el túnel activo.
3. En **"Public Hostnames"**, hacer clic en **"Add a public hostname"**.

| Subdominio | Servicio | URL interna | TLS |
|------------|----------|-------------|-----|
| `portainer.tudominio.com` | Portainer | `http://IP_LOCAL:9000` | Off |
| `www.tudominio.com` | Sitio web | `http://IP_LOCAL:8080` | Off |

**Nota:** Cloudflare genera automáticamente el registro DNS y el certificado SSL.

**Resultado:** Acceso público a Portainer y al sitio web estático mediante HTTPS, sin abrir puertos en el router.

---

### 18.4. Gestión de Credenciales de Portainer

**Problema:** Contraseña de administrador perdida.

**Solución (restablecimiento):**

```bash
docker exec -it portainer /portainer -reset-admin-password
# (Introducir y confirmar nueva contraseña)
docker restart portainer
```

**Alternativa:** Crear un nuevo administrador:

```bash
docker exec -it portainer /portainer -admin-password="NuevaPass" -admin-user="nuevo_admin"
```

---

### 18.5. Estado Actualizado del Proyecto (Fase 2)

| Componente | Estado | Acceso |
|------------|--------|--------|
| **Hardware** | Sin batería, con cargador | Consumo ~15W |
| **Debian 12** | IP fija, firewall UFW activo | SSH local |
| **ZeroTier** | Activo | `ssh julio@192.168.192.xxx` |
| **Docker** | Instalado | Grupo `docker` para el usuario |
| **Portainer** | Contenedor corriendo | `https://portainer.tudominio.com` |
| **Nginx Proxy Manager** | Instalado (respaldo) | `http://IP_LOCAL:81` |
| **Sitio web estático** | Contenedor `mi-sitio-web` | `https://www.tudominio.com` |
| **Cloudflare Tunnel** | Activo | Maneja múltiples subdominios |
| **Dominio** | Dominio gratuito | Apunta a Cloudflare |

---

### 18.6. Comandos Útiles para la Fase 2

```bash
# Reiniciar servicios
docker restart portainer mi-sitio-web cloudflared

# Ver logs del sitio web
docker logs mi-sitio-web -f

# Ver logs del túnel
docker logs cloudflared --tail 50

# Transferir archivos al sitio (desde PC)
scp -r /ruta/local/web/* serv@IP_LOCAL:/home/serv/mi_web/

# Ajustar permisos en el servidor
chmod -R 644 /home/serv/mi_web/*
chmod 755 /home/serv/mi_web
docker restart mi-sitio-web

# Probar resolución DNS
dig portainer.tudominio.com @1.1.1.1
```

---

### 18.7. Registro de Errores y Soluciones (Fase 2)

| Error | Causa | Solución |
|-------|-------|----------|
| `403 Forbidden` en sitio web | Permisos `600` en `index.html` | `chmod 644 /home/serv/mi_web/index.html` |
| `Internal Error` en SSL de NPM | Fecha del sistema desfasada | `sudo timedatectl set-ntp true` |
| `Access denied` en base de datos NPM | Contraseñas no coincidentes | Usar `docker compose down -v` y recrear con contraseñas correctas |
| El dominio no resuelve (`NXDOMAIN`) | Registro DNS no creado | Agregar CNAME o usar el túnel directamente |
| Certificado SSL falla (desafío HTTP) | Puerto 80 no accesible | Usar desafío DNS con token de API de Cloudflare |
| Error al pegar token en NPM | Token mal formateado | Crear archivo manual en `/etc/letsencrypt/credentials/credentials-manual` |

---

### 18.8. Próximos Pasos (Fase 3)

- [ ] Añadir **Nextcloud** (nube personal).
- [ ] Desplegar **Jellyfin** (servidor multimedia).
- [ ] Configurar **Gitea** (git privado).
- [ ] Centralizar todos los servicios en un `docker-compose.yml` único.
- [ ] Automatizar backups de volúmenes y configuraciones.
- [ ] Subir toda la documentación a GitHub con el repositorio actualizado.

---

### 18.9. Conclusión de la Fase 2

El servidor ha evolucionado de ser un simple host de Portainer a una plataforma con múltiples servicios accesibles desde Internet. La combinación de **ZeroTier** (acceso SSH) y **Cloudflare Tunnel** (acceso web) proporciona una solución robusta, segura y sin necesidad de abrir puertos en el router.

La documentación detallada de cada paso, junto con el registro de errores y soluciones, garantiza que el proyecto sea **replicable y mantenible** a largo plazo.

---

**Fin de la documentación de la Fase 2.**
