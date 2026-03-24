#!/bin/bash

# PLD Client Bootstrap Script
# Dit script wordt uitgevoerd op de nieuwe Linux desktops.

set -e

GATEWAY_IP="192.168.100.1"

echo "--- Starten van PLD Client Configuratie ---"

# 1. Controleer of we de server kunnen bereiken
echo "Stap 1: Verbinding met PLD-server controleren..."
if ping -c 1 $GATEWAY_IP &> /dev/null; then
    echo "✅ PLD-server gevonden op $GATEWAY_IP"
else
    echo "❌ FOUT: PLD-server onbereikbaar. Controleer de netwerkkabel."
    exit 1
fi

# 2. Stel de APT Proxy in (Apt-Cacher-NG op de server)
# Dit zorgt ervoor dat updates via de server lopen en gecached worden.
echo "Stap 2: Apt-Proxy configureren voor supersnelle downloads..."
echo "Acquire::http::Proxy \"http://$GATEWAY_IP:3142\";" | sudo tee /etc/apt/apt.conf.d/01proxy

# 3. Systeem update via de proxy
echo "Stap 3: Systeem updaten via de sluis..."
sudo apt update

# 4. Installeer basispakketten die we altijd nodig hebben
echo "Stap 4: Standaard software installeren..."
sudo apt install -y curl git openssh-server

echo "--- Client Configuratie Voltooid! ---"
echo "Deze desktop is nu verbonden met de PLD-straat en gebruikt de lokale cache."
