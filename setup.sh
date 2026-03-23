#!/bin/bash
echo "Welke smaak Linux wil je vandaag?"
echo "1) Full Media Studio"
echo "2) AI Development (Ollama)"
echo "3) Minimal DevOps"
read -p "Keuze: " choice

case $choice in
    1) ansible-playbook master_setup.yml --tags "core,media,boot" ;;
    2) ansible-playbook master_setup.yml --tags "core,ai" ;;
    3) ansible-playbook master_setup.yml --tags "core" ;;
esac

# --- ANSIBLE BOOTSTRAP SECTIE ---
if ! command -v ansible &> /dev/null; then
    echo ">>> Ansible niet gevonden. Installeren..."
    # Gebruik je bestaande distro-detectie logica hier
    sudo apt update && sudo apt install -y ansible || sudo dnf install -y ansible || sudo pacman -S --noconfirm ansible
fi

echo ">>> Uitvoeren van GitHub Provisioning..."
# Start het hoofd-playbook en gebruik tags voor modulariteit
ansible-playbook master_setup.yml --tags "core,boot,ai,media"
