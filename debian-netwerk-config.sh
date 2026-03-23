#!/bin/bash
###############################################################################
# SCRIPT: debian-netwerk-config.sh
# DOEL: Automatische 20 Gbps LACP Bonding voor 2x Mellanox ConnectX-2 SFP+.
#
# HARDWARE SETUP:
# 1. Kaart A: Mellanox ConnectX-2 (SFP+) -> PCIe Slot 1
# 2. Kaart B: Mellanox ConnectX-2 (SFP+) -> PCIe Slot 2
# 3. Switch: D-Link DGS-1510-52 -> Poort 51 & 52 (SFP+ slots)
# 4. Kabels: 2x 10G SFP+ DAC (Direct Attach Copper) kabels.
#
# NETWERK LOGICA (IEEE 802.3ad):
# - Gebruikt LACP (Mode 4) om twee fysieke kaarten te bundelen tot 20 Gbps.
# - Miimon 100: Failure detection binnen 100ms voor maximale uptime.
# - xmit_hash_policy layer3+4: Zorgt dat verkeer naar 10 verschillende 
#   desktops over beide 10G paden wordt verdeeld (geen 10G bottleneck).
###############################################################################

# --- STAP 1: Benodigde pakketten installeren ---
# 'ifenslave' is vereist om de bonding driver in Debian te kunnen gebruiken.
echo "[1/5] Installeren van bonding-tools (ifenslave)..."
sudo apt update && sudo apt install -y ifenslave

# --- STAP 2: Automatische detectie van Mellanox kaarten ---
# We zoeken naar de Mellanox interfaces op de PCI-bus.
# We negeren virtuele interfaces en de poort die internet heeft (default gateway).
echo "[2/5] Scannen naar Mellanox SFP+ poorten op de PCIe-bus..."
GW_IFACE=$(ip -o route get 8.8.8.8 2>/dev/null | awk '{print $5}')
MLX_INTERFACES=$(ls -l /sys/class/net/ | grep "devices/pci" | awk '{print $9}' | grep -v "$GW_IFACE" | head -n 2)

CARD_1=$(echo $MLX_INTERFACES | awk '{print $1}')
CARD_2=$(echo $MLX_INTERFACES | awk '{print $2}')

# Foutcontrole: Zijn er wel 2 fysieke poorten gevonden?
if [ -z "$CARD_1" ] || [ -z "$CARD_2" ]; then
    echo "FOUT: Kon geen twee Mellanox poorten vinden. Controleer 'lspci | grep Mellanox'."
    exit 1
fi

echo "Gevonden poorten voor 20G Backbone: $CARD_1 en $CARD_2"

# --- STAP 3: Schrijven van de nieuwe netwerkconfiguratie ---
# We maken eerst een backup van de huidige configuratie met tijdstempel.
echo "[3/5] Configureren van /etc/network/interfaces..."
sudo cp /etc/network/interfaces /etc/network/interfaces.bak.$(date +%Y%m%d_%H%M%S)

cat << EOF | sudo tee /etc/network/interfaces
# Standaard Loopback
auto lo
iface lo inet loopback

# --- 20 Gbps LACP BACKBONE (DUAL CARD) ---
# Deze interface combineert de kracht van beide Mellanox kaarten.
auto bond0
iface bond0 inet static
    address 192.168.1.1
    netmask 255.255.255.0
    # Mode 4 = LACP (Vereist 'Active' LACP op de D-Link switch)
    bond-mode 4
    bond-miimon 100
    bond-lacp-rate 1
    # Hash policy layer3+4 is essentieel voor load balancing over meerdere desktops
    bond-xmit_hash_policy layer3+4
    bond-slaves $CARD_1 $CARD_2

# Mellanox Kaart 1 (Verbinden met D-Link Poort 51)
auto $CARD_1
iface $CARD_1 inet manual
    bond-master bond0

# Mellanox Kaart 2 (Verbinden met D-Link Poort 52)
auto $CARD_2
iface $CARD_2 inet manual
    bond-master bond0
EOF

# --- STAP 4: Netwerk herstarten ---
echo "[4/5] Netwerk herstarten om de 20 Gbps bond te activeren..."
sudo systemctl restart networking

# Korte pauze voor de LACP 'handshake' tussen server en switch
sleep 3

# --- STAP 5: Verificatie ---
echo "[5/5] Controle van de verbinding..."
echo "--------------------------------------------------------"
if [ -f /proc/net/bonding/bond0 ]; then
    cat /proc/net/bonding/bond0 | grep -E "Bonding Mode|Speed|Slave Interface|Aggregator ID"
else
    echo "FOUT: Bond0 interface is niet correct opgekomen."
fi
echo "--------------------------------------------------------"
echo "Setup voltooid. Vergeet niet je switch-script te draaien voor Poort 51/52!"
