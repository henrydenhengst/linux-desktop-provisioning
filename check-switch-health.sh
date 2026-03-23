#!/bin/bash
###############################################################################
# SCRIPT: check-switch-health.sh
# DOEL: Volledige hardware- en error-audit van de D-Link DGS-1510-52.
# OUTPUT: switch_audit.log
###############################################################################

# --- CONFIGURATIE ---
SWITCH_IP="10.90.90.90"  # Pas aan naar je actuele Switch IP
USER="admin"
PASS="jouwwachtwoord"
LOGFILE="switch_audit.log"

echo "--- Start Switch Audit op $(date) ---" > $LOGFILE

echo "[1/4] Verbinding maken met switch en data ophalen..."

# We voeren alle belangrijke commando's in één SSH-sessie uit voor de log
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SWITCH_IP << EOF >> $LOGFILE 2>&1
echo "========================================"
echo "SYSTEM INFO & VERSION"
show version
echo "========================================"
echo "THERMAL & FAN STATUS"
show environment temperature
show environment fan
echo "========================================"
echo "PORT ERROR STATISTICS (ALL PORTS)"
show error inline-ports
echo "========================================"
echo "BACKBONE SPECIFICS (PORT 51 & 52)"
show statistics interface ethernet 1/0/51
show statistics interface ethernet 1/0/52
echo "========================================"
echo "LACP / PORT-CHANNEL STATUS"
show port-channel 1
echo "========================================"
echo "CPU & MEMORY LOAD"
show cpu
show memory
exit
EOF

echo "[2/4] Data opgeslagen in $LOGFILE"

# Even opschonen: verwijder vreemde terminal-tekens (indien aanwezig)
sed -i 's/\r//g' $LOGFILE

echo "[3/4] Analyse gereed."
echo "[4/4] KOPIEER DE INHOUD VAN $LOGFILE EN PLAK HET IN DE CHAT."
