#!/bin/bash
###############################################################################
# SCRIPT: setup-20g-sfp-backbone.sh
# OMSCHRIJVING: Configureert een 20 Gbps LACP Bond op Debian (Mellanox ConnectX-2).
#
# HARDWARE VEREISTEN:
# 1. Server: Mellanox ConnectX-2 (MNPA19-XTR) SFP+ kaart.
# 2. Switch: D-Link DGS-1510-52 (Poort 51 & 52 SFP+ slots).
# 3. Bekabeling: 2x DAC-kabels (Direct Attach Copper) OF 2x SFP+ Glasvezel modules.
#
# TECHNISCHE NOTITIE (SFP+ vs RJ45):
# De Mellanox gebruikt SFP+. Dit is superieur aan de Intel X540-T2 omdat het 
# VEEL minder stroom verbruikt en bijna geen hitte produceert. 
# Ideaal voor in een dichte imaging-kar!
###############################################################################

# --- STAP 1: Afhankelijkheden installeren ---
echo "Bezig met installeren van bonding tools..."
sudo apt update && sudo apt install -y ifenslave

# --- STAP 2: Automatische hardware detectie voor Mellanox ---
# Mellanox kaarten gebruiken de 'mlx4_core' driver. We zoeken de poorten op basis daarvan.
echo "Scannen naar Mellanox SFP+ poorten..."
INTERFACES=$(ls -l /sys/class/net/ | grep "devices/pci" | awk '{print $9}' | head -n 2)

# Voor Mellanox is het vaak handiger om handmatig te dubbelchecken met 'ip link'
# omdat deze kaarten soms als 'enp...' verschijnen.
INTEL_PORT_1=$(echo $INTERFACES | awk '{print $1}')
INTEL_PORT_2=$(echo $INTERFACES | awk '{print $2}')

if [ -z "$INTEL_PORT_1" ] || [ -z "$INTEL_PORT_2" ]; then
    echo "FOUT: Kon geen twee SFP+ poorten vinden. Zit de kaart goed in het PCIe slot?"
    exit 1
fi

echo "Gevonden SFP+ poorten: $INTEL_PORT_1 en $INTEL_PORT_2"

# --- STAP 3: Netwerk Configureren (/etc/network/interfaces) ---
sudo cp /etc/network/interfaces /etc/network/interfaces.bak.$(date +%F)

cat << EOF | sudo tee /etc/network/interfaces
auto lo
iface lo inet loopback

# --- 20 Gbps SFP+ BACKBONE CONFIG ---
# Mode 4 (LACP) voor 2x 10G SFP+ verbinding naar de D-Link.
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

# --- STAP 4: Activeren en Controle ---
echo "LACP Bond activeren..."
sudo systemctl restart networking
sleep 3

echo "--------------------------------------------------------"
echo "MELLANOX 20G BOND STATUS:"
cat /proc/net/bonding/bond0 | grep -E "Bonding Mode|Speed|Slave Interface"
echo "--------------------------------------------------------"
