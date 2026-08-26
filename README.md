📘 Manual de Configuración del Servidor Doméstico - Netbook Conectar Igualdad
Última actualización: 26 de agosto de 2026
1. Introducción y Objetivo
Este proyecto consiste en convertir una netbook del gobierno (modelo Gen 4/5) en un servidor local accesible desde Internet, utilizando herramientas libres y gratuitas. El objetivo es desplegar servicios en contenedores Docker y exponerlos de forma segura usando Cloudflare Tunnel.
Objetivos específicos:
·	Tener un servidor estable 24/7 con bajo consumo eléctrico.
·	Acceder a los servicios desde cualquier lugar sin necesidad de VPN.
·	Aprender y documentar el proceso para futuras referencias.
2. Hardware Utilizado
Componente	Especificación
Modelo	Netbook Conectar Igualdad (Gen 4 o 5)
Procesador	Intel Celeron / Atom (64 bits)
RAM	4 GB DDR3
Almacenamiento	Disco duro HDD de 500 GB (o eMMC)
Batería	Retirada físicamente para evitar sobrecalentamiento y riesgos (se usa solo con cargador)
Conexión	WiFi y Ethernet (se usa cable para mayor estabilidad)
Decisión clave: Se retiró la batería para evitar inflado, reducir temperatura interna y alargar la vida útil del hardware.
3. Instalación del Sistema Operativo (Debian 12 "Bookworm")
Versión instalada: Debian 12.9.0 (netinst) para arquitectura amd64.
3.1. Descarga del ISO
Se descargó la imagen debian-12.9.0-amd64-netinst.iso desde el enlace oficial:
text
https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.9.0-amd64-netinst.iso
3.2. Creación del USB booteable
Se utilizó Rufus 4.x en Windows:
·	Seleccionar el pendrive (mínimo 2 GB).
·	Elegir el archivo ISO descargado.
·	Modo de escritura: DD (recomendado para Debian).
3.3. Pasos de instalación
·	Arranque desde el USB (tecla F12 al encender).
·	Seleccionar "Graphical install".
·	Configuración regional: Español, Argentina, Latinoamericano.
·	Hostname: servidor-netbook (o el que elijas).
·	Contraseña de root: se dejó vacía (se usará sudo con el usuario normal).
·	Creación de usuario: tuusuario con su contraseña.
·	Particionado: "Guía - usar todo el disco" y "Todos los archivos en una sola partición".
·	Selección de software: solo marcar "Servidor SSH" (desmarcar entorno de escritorio y otros).
·	Instalación del bootloader GRUB en /dev/sda.
3.4. Primera configuración post-instalación
·	Actualización del sistema:
bash
sudo apt update && sudo apt upgrade -y
·	Instalación de herramientas útiles:
bash
sudo apt install -y ufw vim curl wget git htop
·	Configuración de IP fija (editar /etc/network/interfaces):
text
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.100   # (ajustar a tu red)
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4
·	Firewall (UFW):
bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable
3.5. Evitar suspensión al cerrar la tapa
Se editó /etc/systemd/logind.conf y se cambiaron:
text
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
Luego se reinició el servicio:
bash
sudo systemctl restart systemd-logind
4. Acceso Remoto por SSH
Desde otra PC en la misma red, se conectó con:
bash
ssh tuusuario@192.168.1.100
El acceso funciona correctamente. La netbook ya no se duerme al cerrar la tapa.
Instalación de ZeroTier (Acceso SSH desde cualquier lugar)
ZeroTier crea una red privada virtual (VPN) que permite acceder al servidor desde cualquier lugar sin necesidad de abrir puertos en el router. Es una alternativa segura y gratuita para tener acceso SSH incluso si el dominio de Cloudflare falla.
instalación de ZeroTier
bash
curl -s https://install.zerotier.com | sudo bash
Unirse a la red ZeroTier
1.	Crear una red en my.zerotier.com (gratis para hasta 25 dispositivos).
2.	Anotar el Network ID (ej: a1b2c3d4e5f6g7h8).
3.	En el servidor, unirse a la red:
bash
sudo zerotier-cli join a1b2c3d4e5f6g7h8
1.	Autorizar el dispositivo desde el panel web de ZeroTier (marcar como "Authorized").
2.	Verificar la IP asignada:
bash
sudo zerotier-cli listnetworks
Aparecerá una IP como 192.168.192.xxx.
5.3. Conectarse por SSH vía ZeroTier
Desde cualquier dispositivo con ZeroTier instalado (y en la misma red), conectarse con:
bash
ssh julio@192.168.192.xxx
Ventaja: No depende de DNS ni de puertos abiertos. Funciona incluso si el dominio de Cloudflare falla.
5.4. Configurar ZeroTier para que inicie automáticamente
ZeroTier se instala como servicio systemd. Verificar su estado:
bash
sudo systemctl status zerotier-one
Si no está activo, habilitarlo:
bash
sudo systemctl enable zerotier-onesudo systemctl start zerotier-one

5. Instalación de Docker y Portainer
5.1. Instalación de Docker
Se siguió la guía oficial para Debian:
bash
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
Se agregó el usuario al grupo docker para evitar usar sudo en cada comando:
bash
sudo usermod -aG docker tuusuario
5.2. Instalación de Portainer
Se desplegó Portainer con el siguiente comando:
bash
docker volume create portainer_data
docker run -d -p 9000:9000 -p 9443:9443 \
  --name portainer \
  --restart=unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
Portainer está accesible localmente en http://192.168.1.100:9000.
6. Configuración de Dominio Gratuito y Cloudflare
6.1. Obtención del dominio en DNSHE
·	Se creó cuenta en https://www.dnshe.com.
·	Se registró el dominio gratuito: miservidor.de5.net (elegir uno disponible).
·	(En tu caso, el dominio elegido será el que hayas seleccionado).
6.2. Configuración en Cloudflare
·	Se agregó el dominio a Cloudflare (plan gratuito).
·	Cloudflare asignó dos servidores DNS (ej: anna.ns.cloudflare.com y hank.ns.cloudflare.com).
6.3. Configuración en DNSHE
·	Se modificaron los servidores DNS del dominio, reemplazando los predeterminados por los de Cloudflare.
·	Se esperó la propagación (5-10 minutos).
6.4. Verificación
El dominio aparece como "Activo" en el panel de Cloudflare. Está listo para ser usado con Cloudflare Tunnel.
7. Estado Actual del Proyecto
Componente	Estado
Hardware	Funcionando sin batería, con cargador.
Sistema Operativo	Debian 12 instalado y actualizado.
Red	IP fija configurada, firewall activo.
Acceso SSH	Funcionando correctamente.
Docker	Instalado y funcionando.
Portainer	Accesible en http://IP_LOCAL:9000.
Dominio	miservidor.de5.net (o tu dominio) registrado y apuntando a Cloudflare.
Cloudflare Tunnel	Pendiente de instalar y configurar.
8. Próximos Pasos (Continuación)
A partir de este punto, la próxima fase consiste en:
1.	Instalar cloudflared en el servidor.
2.	Autenticar el túnel con Cloudflare (solución al error de cert.pem).
3.	Crear el túnel y enrutar un subdominio (ej. portainer.miservidor.de5.net) hacia Portainer.
4.	Desplegar servicios adicionales en Docker (Nginx, Nextcloud, etc.) y exponerlos mediante el mismo túnel.
5.	Configurar SSL automático (Cloudflare lo maneja).
📌 Comandos y archivos clave para futura referencia
·	Archivo de configuración de red: /etc/network/interfaces
·	Configuración de energía: /etc/systemd/logind.conf
·	Docker instalado y funcionando.
·	Volumen de Portainer: portainer_data
·	Contenedor de Portainer: portainer (puerto 9000)
🗂️ Registro de errores y soluciones
Error	Solución
Failed to write the certificate al hacer cloudflared tunnel login	Se descargará manualmente el cert.pem usando el enlace proporcionado y se copiará a ~/.cloudflared/cert.pem (pendiente de ejecutar).

✅ Conclusión parcial
El servidor está sólidamente instalado y configurado. Todas las herramientas base están listas. La documentación refleja fielmente el proceso seguido. El siguiente paso es completar la instalación de Cloudflare Tunnel para habilitar el acceso público.

6. Configuración de Cloudflare Tunnel (Continuación y Resolución de Errores)
Objetivo: Exponer de forma segura el panel de Portainer (y futuros servicios) a internet sin abrir puertos en el router.
6.1. Instalación de cloudflared
Se optó por la instalación mediante Docker, por su facilidad de gestión y actualización. Se utilizó el siguiente comando base (con el token proporcionado por Cloudflare):
bash
docker run -d \
  --name cloudflared \
  --restart unless-stopped \
  --network host \
  cloudflare/cloudflared:latest tunnel --no-autoupdate run --token <TU_TOKEN>
Nota: En el primer intento, se omitió el flag --network host, lo que provocó que el contenedor no pudiera alcanzar el servicio de Portainer en localhost. Este error se detectó en los logs y se solucionó posteriormente.
6.2. Diagnóstico y Resolución del Error 502 Bad Gateway
Al intentar acceder al dominio, se recibía un error 502 Bad Gateway. Los logs del contenedor (docker logs cloudflared) mostraban:
text
ERR  error="Unable to reach the origin service... dial tcp [::1]:9000: connect: connection refused"
Causa: El contenedor de cloudflared no podía comunicarse con el contenedor de Portainer porque:
·	localhost dentro del contenedor apunta a su propio espacio de red, no al del host.
·	La configuración en el panel de Cloudflare apuntaba a http://localhost:9000.
Solución aplicada (opción elegida): Se forzó el uso de la red del host (--network host) para que el contenedor de cloudflared compartiera la pila de red del servidor, permitiendo que localhost resuelva correctamente al servicio.
Pasos realizados:
1.	Se detuvo y eliminó el contenedor con errores:
bash
docker stop cloudflared
docker rm cloudflared
2.	Se volvió a crear el contenedor con el flag --network host y el mismo token.
3.	Se verificaron los logs para confirmar que el túnel se registraba correctamente y no mostraba errores de conexión.
4.	Se reinició el contenedor de Portainer para desbloquear la interfaz web:
bash
docker restart portainer
6.3. Configuración en el Panel de Cloudflare (Zero Trust)
·	Túnel: Se creó un túnel con nombre mi-tunel (o similar) desde el panel de Cloudflare.
·	Hostname Público: Se añadió un registro DNS para el subdominio xxxx.xxx.com (o el dominio elegido).
·	Servicio: Se configuró el servicio para que apunte a http://localhost:9000, que ahora es alcanzable gracias a la red del host.
6.4. Verificación Final
·	El dominio https://xxxx.xxx.com (o el correspondiente) devuelve la interfaz de Portainer.
·	No se abrieron puertos en el router. La conexión es segura (SSL/TLS gestionado por Cloudflare).
·	El contenedor cloudflared se reinicia automáticamente si falla (gracias a --restart unless-stopped).
6.5. Comandos de Mantenimiento
·	Ver logs del túnel:
bash
docker logs cloudflared --tail 50 -f
·	Reiniciar el túnel:
bash
docker restart cloudflared
·	Actualizar la imagen de cloudflared:
bash
docker pull cloudflare/cloudflared:latest
docker stop cloudflared
docker rm cloudflared
# Volver a ejecutar el comando `docker run` con el token
7. Estado Final del Proyecto (Actualizado)
 Estado Actual del Proyecto
Componente	Estado
Hardware	Funcionando sin batería, con cargador.
Sistema Operativo	Debian 12 instalado y actualizado.
Red	IP fija configurada, firewall activo.
Acceso SSH (LAN)	Funcionando en 192.168.1.100.
Acceso SSH (ZeroTier)	Funcionando en 192.168.192.xxx.
Docker	Instalado y funcionando.
Portainer	Accesible en http://IP_LOCAL:9000 y http://IP_ZEROTIER:9000.
Dominio	Xxxx.xxx.com apuntando a Cloudflare.
Cloudflare Tunnel	Activo, enrutando tráfico a Portainer en xxxx.xxx.com
9. Accesos y Credenciales
Servicio	URL / IP	Puerto	Notas
SSH (LAN)	192.168.1.100	22	Usuario: julio
SSH (ZeroTier)	192.168.192.xxx	22	Usuario: julio
Portainer (Local)	http://192.168.1.100	9000	
Portainer (ZeroTier)	http://192.168.192.xxx	9000	
Portainer (Público)	https://xxxx.xxx.com	443	Requiere usuario y contraseña creados al primer inicio
10. Comandos Útiles para el Día a Día
10.1. Reiniciar servicios
bash
# Reiniciar Portainer (si se bloquea)
docker restart portainer
# Reiniciar Cloudflare Tunnel
docker restart cloudflared
# Reiniciar ZeroTier
sudo systemctl restart zerotier-one
10.2. Ver logs
bash
# Logs de Portainer
docker logs portainer --tail 50
# Logs de Cloudflare Tunnel
docker logs cloudflared --tail 50
# Logs de ZeroTier
sudo journalctl -u zerotier-one -f
10.3. Ver estado de la red ZeroTier
bash
sudo zerotier-cli listnetworks

sudo zerotier-cli status
10.4. Actualizar el sistema
bash
sudo apt update && sudo apt upgrade -y
11. Próximos Pasos (Ampliaciones Futuras)
·	Migrar todos los servicios a un archivo docker-compose.yml.
·	Añadir un servidor multimedia (Jellyfin).
·	Configurar una nube personal (Nextcloud).
·	Añadir un panel de monitoreo (Grafana + Prometheus).
·	Automatizar backups de los volúmenes de Docker.
·	Crear un script de instalación automatizada (Ansible).
12. Seguridad y Buenas Prácticas
·	Firewall UFW activo → solo permite SSH (puerto 22).
·	ZeroTier → acceso SSH cifrado y seguro, sin exponer puertos.
·	Cloudflare Tunnel → acceso web con SSL automático, sin abrir puertos.
·	No se expusieron puertos HTTP/HTTPS en el router → todo pasa por túneles.
·	Contraseñas seguras para el usuario julio y para Portainer.
13. Conclusión
El servidor está completamente funcional, accesible desde cualquier lugar mediante dos métodos complementarios:
·	ZeroTier → acceso SSH directo, independiente de DNS.
·	Cloudflare Tunnel → acceso web a Portainer y futuros servicios, con dominio propio y SSL.
El sistema es estable, consume pocos recursos y está preparado para crecer con nuevos contenedores.

