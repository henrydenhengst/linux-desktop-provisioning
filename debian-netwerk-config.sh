#!/bin/bash
###############################################################################
# SCRIPT: debian-netwerk-config.sh
# OMSCHRIJVING: Configureert een 20 Gbps LACP Bond op Debian (Intel X540-T2).
#
# HARDWARE VEREISTEN:
# 1. Server: Intel X540-T2 (Dual Port 10GBASE-T)
# 2. Switch: D-Link DGS-1510-52 (Poort 51 & 52 met 10G SFP+ RJ45 modules)
# 3. Kabels: 2x Cat6a/7 (Rode codering voor herkenbaarheid)
#
# NETWERK LOGICA:
# - Gebruikt LACP (802.3ad / Mode 4) voor aggregatie en failover.
# - Load balancing op Layer 3+4 (IP + Port) voor optimale verdeling naar 10+ desktops.
# - Statisch IP voor de server: 192.168.1.1/24
###############################################################################

# --- STAP 1: Afhankelijkheden controleren ---
# 'ifenslave' is noodzakelijk om fysieke poorten aan de virtuele bond-interface te koppelen.
echo "Bezig met installeren van netwerk-tools..."
sudo apt update && sudo apt install -y ifenslave

# --- STAP 2: Automatische hardware detectie ---
# We zoeken naar de twee poorten van de Intel X540 kaart.
# Logica: Filter alle fysieke poorten, negeer de interface die momenteel internet heeft (gateway),
# en pak de eerste twee resterende poorten.
echo "Scannen naar beschikbare 10G poorten..."
CURRENT_GW_IFACE=$(ip -o route get 8.8.8.8 2>/dev/null | awk '{print $5}')
INTERFACES=$(ls -l /sys/class/net/ | grep -v virtual | awk '{print $9}' | grep -v "$CURRENT_GW_IFACE" | head -n 2)

INTEL_PORT_1=$(echo $INTERFACES | awk '{print $1}')
INTEL_PORT_2=$(echo $INTERFACES | awk '{print $2}')

# Validatie: zijn er wel 2 poorten gevonden?
if [ -z "$INTEL_PORT_1" ] || [ -z "$INTEL_PORT_2" ]; then
    echo "FOUT: Kon geen twee vrije Intel 10G poorten vinden voor de backbone."
    exit 1
fi

echo "Gevonden poorten voor 20 Gbps LACP: $INTEL_PORT_1 en $INTEL_PORT_2"

# --- STAP 3: Schrijven van /etc/network/interfaces ---
# We maken een backup van de oude config voordat we de nieuwe 'bond0' wegschrijven.
sudo cp /etc/network/interfaces /etc/network/interfaces.bak.$(date +%F)

cat << EOF | sudo tee /etc/network/interfaces
# Loopback interface
auto lo
iface lo inet loopback

# --- 20 Gbps BACKBONE CONFIGURATIE ---
# Mode 4 (LACP) aggregeert $INTEL_PORT_1 en $INTEL_PORT_2 tot één logische verbinding.
# Miimon 100: Checkt elke 100ms op link-failure voor directe failover.
auto bond0
iface bond0 inet static
    address 192.168.1.1
    netmask 255.255.255.0
    bond-mode 4
    bond-miimon 100
    bond-lacp-rate 1
    bond-slaves $INTEL_PORT_1 $INTEL_PORT_2

# Fysieke poort 1 (Rode kabel naar Switch Poort 51)
auto $INTEL_PORT_1
iface $INTEL_PORT_1 inet manual
    bond-master bond0

# Fysieke poort 2 (Rode kabel naar Switch Poort 52)
auto $INTEL_PORT_2
iface $INTEL_PORT_2 inet manual
    bond-master bond0
EOF

# --- STAP 4: Activeren en Verifiëren ---
echo "Netwerkinstellingen toepassen..."
sudo systemctl restart networking

# Geef de link een paar seconden om te onderhandelen (LACP handshake)
sleep 3

echo "--------------------------------------------------------"
echo "BACKBONE STATUS:"
cat /proc/net/bonding/bond0 | grep -E "Bonding Mode|Speed|Slave Interface"
echo "--------------------------------------------------------"
echo "LET OP: Zorg dat de D-Link switch poort 51 & 52 ook op LACP (Active) staan!"
