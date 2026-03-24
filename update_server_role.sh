#!/usr/bin/env bash
# PLD Server Provisioning Update
set -e

PROJECT_DIR="$HOME/git/pld"
cd "$PROJECT_DIR"

echo "🛠️  1. Server-rol aanmaken (Docker & Netboot)..."
mkdir -p roles/server/tasks
cat << 'INNER_EOF' > roles/server/tasks/main.yml
---
- name: Installeren van Docker benodigdheden
  apt:
    name: [apt-transport-https, ca-certificates, curl, gnupg, lsb-release, dnsmasq, nfs-kernel-server]
    state: present
    update_cache: yes

- name: Docker GPG sleutel toevoegen
  apt_key:
    url: https://download.docker.com/linux/debian/gpg
    state: present

- name: Docker Repository toevoegen
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/debian {{ ansible_distribution_release }} stable"
    state: present

- name: Docker Engine installeren
  apt:
    name: [docker-ce, docker-ce-cli, containerd.io, docker-compose-plugin]
    state: present

- name: Docker service starten
  service:
    name: docker
    state: started
    enabled: yes

- name: Netboot mappenstructuur aanmaken
  file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
  loop:
    - /var/lib/tftpboot
    - /var/www/html/debian
INNER_EOF

echo "🛠️  2. Server Playbook aanmaken..."
cat << 'INNER_EOF' > playbooks/server.yml
---
- hosts: localhost
  connection: local
  become: yes
  roles:
    - common
    - server
INNER_EOF

echo "🚀 3. Alles naar GitHub pushen..."
git add .
git commit -m "Server-infra: Docker, Netboot en Dnsmasq support toegevoegd" || echo "Geen wijzigingen"
git push origin main

echo "✅ KLAAR! Je server-recept staat live."
