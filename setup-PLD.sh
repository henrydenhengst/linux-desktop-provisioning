#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# CONFIGURATIE (Henry's PLD Productiestraat)
# ==============================================================================
SERVER_IP="192.168.10.1"
GIT_REPO="https://YOUR_GIT_REPO.git" 
BASE_DIR="/opt/pld"
REPO_DIR="/opt/gitops/repo"

echo "===> START: BOUW VAN DE PLD-MACHINE (6 DESKTOPS PER UUR)"

# 1. SYSTEEM & INFRASTRUCTUUR
apt-get update && apt-get upgrade -y
apt-get install -y curl wget git vim ufw docker.io docker-compose-v2 nfs-kernel-server

# 2. FIREWALL (Open voor Imaging, Printers & Beheer)
ufw allow 22,67,68,69,80,8080,2049,3000,5353/udp
ufw --force enable

# 3. NETBOOT.XYZ (De Verkeerstoren)
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

# 4. ANSIBLE GITOPS STRUCTUUR (De 'Master Image')
mkdir -p ${REPO_DIR}/playbooks
mkdir -p ${REPO_DIR}/roles/{common,office,devops,educatie}/tasks

# --- DE CORE: SITE.YML ---
cat <<EOF > ${REPO_DIR}/playbooks/site.yml
- name: PLD Client Uitrol
  hosts: localhost
  become: true
  roles:
    - common
    - "{{ profile | default('office') }}"
EOF

# --- COMMON ROLE: PRINTERS, MAIL & NL-TAAL ---
cat <<EOF > ${REPO_DIR}/roles/common/tasks/main.yml
- name: Lokalisatie (NL Tijd & Toetsenbord)
  shell: |
    timedatectl set-timezone Europe/Amsterdam
    localectl set-x11-keymap us pc105 intl
- name: Installeren Core Apps (Thunderbird voor iedereen!)
  package:
    name: [thunderbird, thunderbird-l10n-nl, cups, hplip, sane-utils, avahi-daemon, printer-driver-brlaser, libavcodec-extra]
    state: present
- name: Start Services
  systemd: { name: "{{ item }}", state: started, enabled: yes }
  loop: [cups, avahi-daemon]
EOF

# --- OFFICE ROLE: DE BROWSERS (Chrome & Brave met moderne keys) ---
cat <<EOF > ${REPO_DIR}/roles/office/tasks/main.yml
- name: Browsers GPG Keys ophalen
  shell: |
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg --yes
    curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/brave-browser.gpg --yes

- name: Browsers Repos toevoegen
  shell: |
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/brave-browser.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" > /etc/apt/sources.list.d/brave-browser.list

- name: Installeren Office & Browsers
  apt:
    name: [google-chrome-stable, brave-browser, libreoffice, libreoffice-l10n-nl, vlc]
    update_cache: yes
    state: present
EOF

# 5. BOOTSTRAP & PXE MENU
cat <<EOF > ${BASE_DIR}/netbootxyz/assets/scripts/bootstrap.sh
#!/usr/bin/env bash
PROFILE=\$(cat /proc/cmdline | grep -oP 'profile=\K\S+' || echo "office")
apt-get update && apt-get install -y ansible git
ansible-pull -U "${GIT_REPO}" -i localhost, -e "profile=\$PROFILE" playbooks/site.yml
reboot
EOF
chmod +x ${BASE_DIR}/netbootxyz/assets/scripts/bootstrap.sh

# PXE Menu Update
cat <<EOF > ${BASE_DIR}/netbootxyz/config/pxe-menu.cfg
label Office_NL_Full
    KERNEL netboot.xyz.kpxe
    APPEND profile=office url=http://${SERVER_IP}:8080/preseed/preseed.cfg
EOF

echo "===> KLAAR! PLD-straat v1.1 staat live."
