#!/bin/bash
echo "Reiniciando Portainer..."
docker restart portainer
echo "Reiniciando Cloudflare Tunnel..."
docker restart cloudflared
echo "Reiniciando ZeroTier..."
sudo systemctl restart zerotier-one
echo "¡Servicios reiniciados!"
