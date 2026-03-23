#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# CONFIGURATIE (Origineel + PVS)
# ==============================================================================
INTERFACE="eth0"
SERVER_IP="192.168.10.1"
DHCP_RANGE_START="192.168.10.100"
DHCP_RANGE_END="192.168.10.200"
SSH_PORT=22
GIT_REPO="https://YOUR_GIT_REPO.git"
BASE_DIR="/opt/pvs"
REPO_DIR="/opt/gitops/repo"

echo "===> FOCUS: Transformatie naar PVS Productiestraat v1.0"

# ==============================================================================
# STAP 1 & 2: SYSTEEM UPDATE, SSH & FIREWALL
# ==============================================================================
apt-get update && apt-get upgrade -y
apt-get install -y curl wget git vim htop ufw nfs-kernel-server \
    apt-transport-https ca-certificates gnupg lsb-release software-properties-common

# SSH Hardening (Origineel)
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || true
systemctl restart ssh

# Firewall (Alle poorten uit je originele script)
ufw allow ${SSH_PORT}/tcp
ufw allow 67/udp && ufw allow 68/udp
ufw allow 69/udp
ufw allow 80,8080,3000/tcp
ufw allow 2049/tcp
ufw --force enable

# ==============================================================================
# STAP 3 & 4: DOCKER & NETBOOT.XYZ
# ==============================================================================
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
fi

mkdir -p ${BASE_DIR}/netbootxyz/{config,assets/scripts,assets/preseed}

cat <<EOF > ${BASE_DIR}/netbootxyz/docker-compose.yml
services:
  netbootxyz:
    image: ghcr.io/netbootxyz/netbootxyz
    container_name: netbootxyz
    network_mode: host
    volumes:
      - ./config:/config
      - ./assets:/assets
    restart: unless-stopped
EOF
cd ${BASE_DIR}/netbootxyz && docker compose up -d

# ==============================================================================
# STAP 5: ANSIBLE MAPPENSTRUCTUUR (De 'vDisk' Architectuur)
# ==============================================================================
mkdir -p ${REPO_DIR}/{playbooks,group_vars,roles/{common/tasks,office/tasks,devops/tasks,educatie/tasks}}

# De Kern: site.yml
cat <<EOF > ${REPO_DIR}/playbooks/site.yml
- name: PVS Fat Client Provisioning
  hosts: localhost
  become: true
  roles:
    - common
    - "{{ profile | default('office') }}"
EOF

# Common Role: Drivers, Users, Cleanup
cat <<EOF > ${REPO_DIR}/roles/common/tasks/main.yml
- name: Hardware Detectie & Drivers
  include_tasks: drivers.yml
- name: User Management
  include_tasks: users.yml
- name: PVS Cleanup (vDisk Reset)
  include_tasks: cleanup.yml
EOF

# Drivers.yml (GPU/CPU Focus)
cat <<'EOF' > ${REPO_DIR}/roles/common/tasks/drivers.yml
- name: Microcode Installatie
  package:
    name: "{{ (ansible_os_family == 'RedHat') | ternary('microcode_ctl', 'intel-microcode') }}"
    state: present
- name: GPU Check
  shell: "lspci | grep -iE 'nvidia|vga'"
  register: gpu_check
  failed_when: false
EOF

# Cleanup.yml (PVS Reset)
cat <<'EOF' > ${REPO_DIR}/roles/common/tasks/cleanup.yml
- name: Wis caches en history
  file:
    path: "{{ item }}"
    state: absent
  loop: [/tmp/*, /var/tmp/*, /home/ansible/.cache, /home/ansible/.bash_history]
EOF

# ==============================================================================
# STAP 6 & 9: PRESEED & PXE MENU (Originele logica hersteld)
# ==============================================================================
cat <<EOF > ${BASE_DIR}/netbootxyz/assets/preseed/preseed.cfg
d-i preseed/late_command string \
    in-target curl -L -o /tmp/bootstrap.sh http://${SERVER_IP}:8080/scripts/bootstrap.sh; \
    in-target chmod +x /tmp/bootstrap.sh; \
    in-target /tmp/bootstrap.sh
EOF

cat <<EOF > ${BASE_DIR}/netbootxyz/config/pxe-menu.cfg
label Debian_Office
    MENU LABEL Debian 12 - Office
    KERNEL netboot.xyz.kpxe
    APPEND profile=office server_ip=${SERVER_IP} url=http://${SERVER_IP}:8080/preseed/preseed.cfg
EOF

# ==============================================================================
# STAP 8: BOOTSTRAP AGENT & STORAGE
# ==============================================================================
cat <<EOF > ${BASE_DIR}/netbootxyz/assets/scripts/bootstrap.sh
#!/usr/bin/env bash
PROFILE=\$(cat /proc/cmdline | grep -oP 'profile=\K\S+' || echo \"office\")
apt-get update && apt-get install -y ansible git
ansible-pull -U "${GIT_REPO}" -e "profile=\${PROFILE}" playbooks/site.yml
EOF
chmod +x ${BASE_DIR}/netbootxyz/assets/scripts/bootstrap.sh

mkdir -p /export/homes
echo "/export/homes *(rw,sync,no_subtree_check,no_root_squash)" > /etc/exports
exportfs -a

# ==============================================================================
# STAP 10: EINDE SCHERM (De volledige documentatie)
# ==============================================================================
clear
echo "============================================================"
echo "        ZERO-TOUCH PVS PROVISIONING READY"
echo "============================================================"
echo ""
echo "NETWERK:"
echo " - Server IP:    ${SERVER_IP}"
echo " - DHCP Range:   ${DHCP_RANGE_START} - ${DHCP_RANGE_END}"
echo ""
echo "WEB UI & ASSETS:"
echo " - Netboot UI:   http://${SERVER_IP}:3000"
echo " - Assets:       http://${SERVER_IP}:8080"
echo " - Agent Script: http://${SERVER_IP}:8080/scripts/bootstrap.sh"
echo " - Preseed:      http://${SERVER_IP}:8080/preseed/preseed.cfg"
echo ""
echo "ANSIBLE GITOPS REPO:"
echo " - Pad:          ${REPO_DIR}"
echo " - Structuur:    Common (Drivers/Cleanup/Users) + Profielen"
echo ""
echo "INSTRUCTIES:"
echo " 1. Initialiseer Git in ${REPO_DIR}"
echo " 2. Push naar: ${GIT_REPO}"
echo " 3. Boot je Fat Client en kies je profiel."
echo "============================================================"
