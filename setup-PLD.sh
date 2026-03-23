#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# CONFIGURATIE (Provisioning Linux Desktops - PLD)
# ==============================================================================
COMPANY_NAME="{{ companyname }}" 
SERVER_IP="192.168.10.1"
GIT_REPO="https://YOUR_GIT_REPO.git" 
REPO_DIR="/opt/gitops/repo"
BASE_DIR="/opt/pld"

echo "===> INITIALISEREN: ${COMPANY_NAME} PLD PRODUCTIESTRAAT v1.5"

# 1. INFRASTRUCTUUR & NETWERK
apt-get update && apt-get upgrade -y
apt-get install -y curl wget git ufw docker.io docker-compose-v2 nfs-kernel-server

# Firewall open (PXE, NFS, CUPS, HTTP)
ufw allow 22,67,68,69,80,8080,2049,3000,5353/udp
ufw --force enable

# 2. NETBOOT.XYZ
mkdir -p ${BASE_DIR}/netbootxyz/{config,assets/scripts,assets/preseed}
cat <<EOF > ${BASE_DIR}/netbootxyz/docker-compose.yml
services:
  netbootxyz:
    image: ghcr.io/netbootxyz/netbootxyz
    container_name: netbootxyz
    network_mode: host
    volumes: [ "./config:/config", "./assets:/assets" ]
    restart: unless-stopped
EOF
cd ${BASE_DIR}/netbootxyz && docker compose up -d

# 3. ANSIBLE GITOPS STRUCTUUR
mkdir -p ${REPO_DIR}/playbooks
mkdir -p ${REPO_DIR}/roles/{common,office,privacy,devops}/tasks

# --- SITE.YML ---
cat <<EOF > ${REPO_DIR}/playbooks/site.yml
- name: "${COMPANY_NAME} PLD Client Provisioning"
  hosts: localhost
  become: true
  vars:
    company: "${COMPANY_NAME}"
  roles:
    - common
    - "{{ profile | default('office') }}"
EOF

# --- COMMON ROLE (Basis + Flatpak + Thunderbird + Printers) ---
cat <<EOF > ${REPO_DIR}/roles/common/tasks/main.yml
- name: Lokalisatie & Tijd
  shell: |
    timedatectl set-timezone Europe/Amsterdam
    localectl set-x11-keymap us pc105 intl

- name: Core Systeem Apps
  package:
    name: [thunderbird, thunderbird-l10n-nl, cups, hplip, sane-utils, avahi-daemon, printer-driver-brlaser, libavcodec-extra]
    state: present

- name: Flatpak Engine Installatie
  package:
    name: [flatpak, gnome-software-plugin-flatpak]
    state: present

- name: Flathub Repository Toevoegen
  shell: flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

- name: Start Services
  systemd: { name: "{{ item }}", state: started, enabled: yes }
  loop: [cups, avahi-daemon]
EOF

# --- PRIVACY ROLE (PrivacyTools.io + Flatpak Apps) ---
cat <<EOF > ${REPO_DIR}/roles/privacy/tasks/main.yml
- name: Repositories instellen (Brave & Signal)
  shell: |
    curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/brave-browser.gpg --yes
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/brave-browser.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" > /etc/apt/sources.list.d/brave-browser.list
    wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > /usr/share/keyrings/signal-desktop-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" > /etc/apt/sources.list.d/signal-desktop.list

- name: Installeren Privacy Stack (APT)
  apt:
    name: [brave-browser, signal-desktop, briar, torbrowser-launcher, keepassxc, vlc]
    update_cache: yes
    state: present

- name: Installeren Extra Privacy Tools (Flatpak)
  shell: flatpak install -y flathub network.loki.Session # Metadata-vrije messenger
EOF

# --- OFFICE ROLE (Standaard + Chrome + Signal) ---
cat <<EOF > ${REPO_DIR}/roles/office/tasks/main.yml
- name: Repositories instellen (Chrome & Signal)
  shell: |
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg --yes
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
    wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > /usr/share/keyrings/signal-desktop-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" > /etc/apt/sources.list.d/signal-desktop.list

- name: Installeren Office Stack
  apt:
    name: [google-chrome-stable, signal-desktop, libreoffice, libreoffice-l10n-nl]
    update_cache: yes
    state: present
EOF

# 4. DE BOOTSTRAP AGENT
cat <<EOF > ${BASE_DIR}/netbootxyz/assets/scripts/bootstrap.sh
#!/usr/bin/env bash
PROFILE=\$(cat /proc/cmdline | grep -oP 'profile=\K\S+' || echo "office")
echo "===> STARTING ${COMPANY_NAME} PLD AGENT"
apt-get update && apt-get install -y ansible git
ansible-pull -U "${GIT_REPO}" -i localhost, -e "profile=\$PROFILE" playbooks/site.yml
reboot
EOF
chmod +x ${BASE_DIR}/netbootxyz/assets/scripts/bootstrap.sh

# 5. PXE MENU
cat <<EOF > ${BASE_DIR}/netbootxyz/config/pxe-menu.cfg
label ${COMPANY_NAME}_Office
    KERNEL netboot.xyz.kpxe
    APPEND profile=office url=http://${SERVER_IP}:8080/preseed/preseed.cfg
label ${COMPANY_NAME}_Privacy
    KERNEL netboot.xyz.kpxe
    APPEND profile=privacy url=http://${SERVER_IP}:8080/preseed/preseed.cfg
EOF

echo "===> KLAAR! ${COMPANY_NAME} PLD v1.5 staat live."
