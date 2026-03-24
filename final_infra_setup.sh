#!/usr/bin/env bash
# PLD Clean Infrastructure Setup
set -e

PROJECT_DIR="$HOME/git/pld"
cd "$PROJECT_DIR"

echo "🛠️  1. Docker-infrastructuur rol bijwerken..."
mkdir -p roles/server/tasks
cat << 'INNER_EOF' > roles/server/tasks/main.yml
---
- name: Installeren van Docker Engine & Compose
  apt:
    name: [docker.io, docker-compose]
    state: present
    update_cache: yes

- name: Docker service inschakelen
  service:
    name: docker
    state: started
    enabled: yes

- name: Container mappen aanmaken (zoals in .gitignore)
  file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
  loop:
    - /opt/pld/caddy
    - /opt/pld/homeassistant
    - /opt/pld/vaultwarden
    - /opt/pld/mosquitto
INNER_EOF

echo "🚀 2. Alles naar GitHub pushen..."
git add .
git commit -m "Infra: Schone Docker-basis en mappenstructuur toegevoegd" || echo "Geen wijzigingen"
git push origin main

echo "✅ KLAAR! Je server-basis is nu universeel en schoon."
