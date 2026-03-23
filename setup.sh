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
