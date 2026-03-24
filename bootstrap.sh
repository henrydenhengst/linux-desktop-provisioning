#!/usr/bin/env bash
# =================================================================
# PLD BOOTSTRAP v1.1
# Doel: Snelle uitrol van desktops via Ansible-Pull
# Gebruik: curl -s https://.../bootstrap.sh | bash -s [profile]
# =================================================================
set -e

# Kleuren voor duidelijke output in de terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starten van de PLD-installatie...${NC}"

# 1. Systeem updaten en basisbenodigdheden installeren
echo -e "${BLUE}📦 1. Voorbereiden van de omgeving (Git & Ansible)...${NC}"
sudo apt update
sudo apt install -y ansible git

# 2. Draai de configuratie direct vanaf GitHub via HTTPS
# We gebruiken HTTPS om SSH-key fouten op nieuwe machines te voorkomen.
# De variabele ${1:-office} zorgt dat 'office' het standaard profiel is.
echo -e "${BLUE}⚙️  2. Ansible-Pull uitvoeren voor profiel: ${GREEN}${1:-office}${NC}"

sudo ansible-pull -U https://github.com/henrydenhengst/pld.git \
    -i localhost, \
    -e "profile=${1:-office}" \
    playbooks/site.yml

# 3. Afronding
echo -e "${GREEN}✅ INSTALLATIE VOLTOOID!${NC}"
echo "-------------------------------------------------------"
echo "Het gekozen profiel is toegepast. Herstart de machine."
echo "-------------------------------------------------------"
