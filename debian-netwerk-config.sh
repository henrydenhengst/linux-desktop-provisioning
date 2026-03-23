#!/bin/bash

# --- CONFIGURATIE ---
SWITCH_IP="192.168.1.2"
SWITCH_USER="admin"
SWITCH_PASS="jouwwachtwoord"

echo "--- STAP 1: Software installeren ---"
sudo apt update && sudo apt install -y ifenslave sshpass

echo "--- STAP 2: Scannen naar Intel X540-T2 poorten ---"
# We zoeken naar interfaces die 'up' kunnen en niet 'lo' of de standaard 'eth0' zijn.
# Dit commando pakt de twee fysieke poorten van je 10G kaart.
INTERFACES=$(ip -o link show | awk -F': ' '{print $2}' | grep -v 'lo' | grep -v 'enp0s3' | head -n 2)

# Zet ze in variabelen
INTEL_PORT_1=$(echo $INTERFACES | awk '{print $1}')
INTEL_PORT_2=$(echo $INTERFACES | awk '{print $2}')

if [ -z "$INTEL_PORT_1" ] || [ -z "$INTEL_PORT_2" ]; then
    echo "FOUT: Kon geen twee vrije netwerkpoorten vinden. Check 'ip link'."
    exit 1
fi

echo "Gevonden poorten voor de 20 Gbps bond: $INTEL_PORT_1 en $INTEL_PORT_2"

echo "--- STAP 3: Debian Netwerk Configureren (Bonding) ---"
sudo cp /etc/network/interfaces /etc/network/interfaces.bak

cat << EOF | sudo tee /etc/network/interfaces
auto lo
iface lo inet loopback

# De 20 Gbps 'Master' interface
auto bond0
iface bond0 inet static
    address 192.168.1.1
    netmask 255.255.255.0
    bond-mode 4
    bond-miimon 100
    bond-lacp-rate 1
    bond-slaves $INTEL_PORT_1 $INTEL_PORT_2

auto $INTEL_PORT_1
iface $INTEL_PORT_1 inet manual
    bond-master bond0

auto $INTEL_PORT_2
iface $INTEL_PORT_2 inet manual
    bond-master bond0
EOF

echo "--- STAP 4: D-Link Switch Configureren via SSH ---"
# We knallen de 10G instellingen naar poort 51 en 52
sshpass -p "$SWITCH_PASS" ssh -o StrictHostKeyChecking=no $SWITCH_USER@$SWITCH_IP << EOF
configure terminal
interface range ethernet 1/0/51-52
  speed 10000
  duplex full
  channel-group 1 mode active
  exit
port-channel load-balance src-dst-ip-l4port
interface range ethernet 1/0/1-10
  no green-ethernet
  spanning-tree portfast
  storm-control broadcast level 5
  exit
copy running-config startup-config
exit
EOF

echo "--- STAP 5: Netwerk herstarten ---"
sudo systemctl restart networking

echo "--- STAP 6: Controle ---"
sleep 2
cat /proc/net/bonding/bond0 | grep "Speed"
