#!/usr/bin/env bash
# =================================================================
# PLD APT-CACHER-NG INTEGRATIE SCRIPT
# Doel: LAN-snelheid installaties (1Gbps) voor 6 desktops per uur.
# =================================================================
set -e

PROJECT_DIR="$HOME/git/pld"
cd "$PROJECT_DIR"

echo "⚡ 1. Server-rol uitbreiden met Apt-Cacher-NG..."
mkdir -p roles/server/tasks
cat << 'INNER_EOF' >> roles/server/tasks/main.yml

- name: Installeer Apt-Cacher-NG voor snelle LAN-installaties
  apt:
    name: apt-cacher-ng
    state: present
    update_cache: yes

- name: Zorg dat Apt-Cacher-NG luistert op alle netwerkinterfaces
  lineinfile:
    path: /etc/apt-cacher-ng/acng.conf
    regexp: '^#?BindAddress:'
    line: 'BindAddress: 0.0.0.0'
  notify: Herstart Apt-Cacher
INNER_EOF

echo "🛠️  2. Handler aanmaken voor de server..."
mkdir -p roles/server/handlers
cat << 'INNER_EOF' > roles/server/handlers/main.yml
---
- name: Herstart Apt-Cacher
  service:
    name: apt-cacher-ng
    state: restarted
INNER_EOF

echo "🖥️  3. Common-rol aanpassen voor de desktops..."
# Dit zorgt dat elke desktop via de server downloadt (Proxy)
mkdir -p roles/common/tasks
cat << 'INNER_EOF' >> roles/common/tasks/main.yml

- name: Configureer de desktop om de Apt-Cache van de server te gebruiken
  copy:
    dest: /etc/apt/apt.conf.d/00aptproxy
    content: 'Acquire::http::Proxy "http://{{ hostvars[groups["server"][0]]["ansible_default_ipv4"]["address"] }}:3142";'
INNER_EOF

echo "🚀 4. Alles synchroniseren naar GitHub..."
./update_git.sh

echo "-------------------------------------------------------"
echo -e "✅ KLAAR! Apt-Cacher-NG is nu onderdeel van je systeem."
echo -e "Draai nu op je server: sudo ansible-playbook playbooks/server.yml"
echo "-------------------------------------------------------"
