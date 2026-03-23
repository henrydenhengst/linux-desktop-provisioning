#!/bin/bash
###############################################################################
# SCRIPT: update-switch-firmware.sh
# DOEL: Veilig flashen van de D-Link DGS-1510-52 naar de laatste versie.
#
# VOORWAARDEN:
# 1. De switch moet bereikbaar zijn op $SWITCH_IP.
# 2. De Debian server moet een TFTP of SCP server draaien (of we 'pushen' via SCP).
###############################################################################

# --- CONFIGURATIE ---
SWITCH_IP="10.90.90.90"
USER="admin"
PASS="jouwwachtwoord"
FIRMWARE_FILE="DGS-1510-52_Run_1_90_B012.had" # Pas de bestandsnaam aan!

echo "[1/3] Firmware $FIRMWARE_FILE uploaden naar de switch..."

# We gebruiken SCP om het bestand direct naar de 'flash' van de switch te kopiëren.
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no $FIRMWARE_FILE $USER@$SWITCH_IP:c:/$FIRMWARE_FILE

echo "[2/3] Installatie starten en boot-image aanpassen..."

# We vertellen de switch dat hij bij de volgende herstart de nieuwe file moet gebruiken.
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SWITCH_IP << EOF
configure terminal
boot image c:/$FIRMWARE_FILE
exit
copy running-config startup-config
reboot
y
EOF

echo "[3/3] De switch herstart nu. Dit duurt ongeveer 3 tot 5 minuten."
echo "Blijf 'ping $SWITCH_IP' draaien om te zien wanneer hij weer terug is."
