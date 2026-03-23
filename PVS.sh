#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# CONFIGURATIE (De basis voor je €900/uur marge)
# ==============================================================================
SERVER_IP="192.168.10.1"
GIT_REPO="https://YOUR_GIT_REPO.git" # PAS DIT AAN NAAR JE EIGEN REPO!
BASE_DIR="/opt/pvs"
REPO_DIR="/opt/gitops/repo"

echo "===> START: BOUW VAN DE LINUX-MACHINE VOOR 6 DESKTOPS PER UUR"

# 1. SYSTEEM & DEPENDENCIES
apt-get update && apt-get upgrade -y
apt-get install -y curl wget git vim ufw docker.io docker-compose-v2 nfs-kernel-server

# 2. FIREWALL VOOR PRODUCTIE (Alles open voor imaging & printers)
ufw allow 22,67,68,69,80,8080,2049,3000,5353/udp
ufw --force enable

# 3. NETBOOT.XYZ SETUP (De voordeur voor je desktops)
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

# 4. ANSIBLE GITOPS STRUCTUUR (Hier leven je GROEPEN)
mkdir -p ${REPO_DIR}/playbooks
mkdir -p ${REPO_DIR}/roles/{common,office,devops,educatie}/tasks

# --- COMMON ROLE (Printers, Drivers, NL-Taal) ---
cat <<EOF > ${REPO_DIR}/roles/common/tasks/main.yml
- name: Lokalisatie (NL Tijd & Toetsenbord)
  shell: |
    timedatectl set-timezone Europe/Amsterdam
    localectl set-x11-keymap us pc105 intl
- name: Installeren Drivers & Printer Stack
  package:
    name: [intel-microcode, cups, hplip, sane-utils, avahi-daemon, printer-driver-brlaser, libavcodec-extra]
    state: present
- name: Start Services
  systemd: { name: "{{ item }}", state: started, enabled: yes }
  loop: [cups, avahi-daemon]
EOF

# --- OFFICE ROLE (De €150 besparing per PC) ---
cat <<EOF > ${REPO_DIR}/roles/office/tasks/main.yml
- name: Installeer Chrome & Office
  package:
    name: [libreoffice, libreoffice-l10n-nl, vlc, fonts-liberation]
    state: present
- name: Google Chrome Repo & Install
  shell: |
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
    apt-get update && apt-get install -y google-chrome-stable
EOF

# --- DEVOPS & EDUCATIE ROLES ---
echo "- name: DevOps Tools\n  package: { name: [git, docker.io, code, jq], state: present }" > ${REPO_DIR}/roles/devops/tasks/main.yml
echo "- name: Educatie Tools\n  package: { name: [gcompris-qt, scratch], state: present }" > ${REPO_DIR}/roles/educatie/tasks/main.yml

# 5. DE BOOTSTRAP AGENT (Wat de desktop uitvoert bij boot)
cat <<EOF > ${BASE_DIR}/netbootxyz/assets/scripts/bootstrap.sh
#!/usr/bin/env bash
PROFILE=\$(cat /proc/cmdline | grep -oP 'profile=\K\S+' || echo "office")
apt-get update && apt-get install -y ansible git
ansible-pull -U "${GIT_REPO}" -i localhost, -e "profile=\$PROFILE" ${REPO_DIR}/playbooks/site.yml
reboot
EOF
chmod +x ${BASE_DIR}/netbootxyz/assets/scripts/bootstrap.sh

# 6. PXE MENU (Keuze voor de klant)
cat <<EOF > ${BASE_DIR}/netbootxyz/config/pxe-menu.cfg
label Office_NL
    KERNEL netboot.xyz.kpxe
    APPEND profile=office url=http://${SERVER_IP}:8080/preseed/preseed.cfg
label DevOps_Pro
    KERNEL netboot.xyz.kpxe
    APPEND profile=devops url=http://${SERVER_IP}:8080/preseed/preseed.cfg
EOF

echo "===> KLAAR! Je PVS-straat staat live op ${SERVER_IP}."
