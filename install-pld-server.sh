#!/usr/bin/env bash
# =================================================================
# PLD SERVER INSTALLATION SCRIPT v1.0
# Doel: Een kale Debian server transformeren naar PLD Moederschip
# =================================================================
set -e

# Kleuren voor output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starten van PLD Server Installatie...${NC}"

# 1. Systeem updaten en basisbenodigdheden installeren
echo -e "${BLUE}📦 1. Installeren van Ansible en Git...${NC}"
sudo apt update
sudo apt install -y git ansible curl

# 2. Project ophalen van GitHub
echo -e "${BLUE}📥 2. Project ophalen van GitHub...${NC}"
PROJECT_DIR="$HOME/pld-server"

if [ -d "$PROJECT_DIR" ]; then
    echo "Directory bestaat al, ophalen nieuwste wijzigingen..."
    cd "$PROJECT_DIR"
    git pull
else
    git clone https://github.com/henrydenhengst/pld.git "$PROJECT_DIR"
    cd "$PROJECT_DIR"
fi

# 3. Ansible Server Playbook draaien
echo -e "${BLUE}⚙️  3. Ansible Playbook uitvoeren (Server Rol)...${NC}"
# We draaien het server-specifieke playbook dat we eerder hebben gemaakt
sudo ansible-playbook playbooks/server.yml

# 4. Status Check
echo -e "${GREEN}✅ INSTALLATIE VOLTOOID!${NC}"
echo "-------------------------------------------------------"
echo -e "🐳 Docker Status: $(systemctl is-active docker)"
echo -e "⚡ Apt-Cacher Status: $(systemctl is-active apt-cacher-ng || echo 'Niet actief/geïnstalleerd')"
echo -e "📂 Project locatie: $PROJECT_DIR"
echo "-------------------------------------------------------"
echo "Je kunt nu desktops gaan aansluiten op de DGS-3100 switch."
