# D-Link DGS-1510-52 setup / config
#
# Poort 49: SFP-poort — Maximaal 1 Gbps
# Poort 50: SFP-poort — Maximaal 1 Gbps
# Poort 51: SFP+ poort — Maximaal 10 Gbps
# Poort 52: SFP+ poort — Maximaal 10 Gbps
#
# De "Paperclip Executie" Stappen:
# Zoek het gaatje: Aan de voorkant zit een 
# klein gaatje met de tekst "Reset".
# De Prik: Steek de verbogen paperclip 
# erin tot je een duidelijke 'klik' voelt van 
# het knopje.
# De 10-Seconden Regel: Houd de knop 
# ingedrukt terwijl de switch aan staat. 
# Tel tot 10. De lampjes van alle poorten 
# zullen tegelijk gaan knipperen of even
# uitgaan.
# Loslaten: Haal de paperclip eruit en 
# laat de switch rustig opstarten 
# (duurt ongeveer 60 seconden).
# Hoe kom je er nu in zonder 
# Console-kabel?
# Zodra hij gereset is, valt hij terug op 
# zijn fabrieksinstellingen. Omdat ik
# geen console-kabel hebt, gebruiken 
# ik de "Default IP" methode:
# Standaard IP: De switch zet zichzelf op
# 10.90.90.90 (met subnetmasker 255.0.0.0).
# Mijn Laptop/Server instellen: Geef de 
# eigen netwerkkaart tijdelijk even 
# een statisch IP in die reeks, 
# bijvoorbeeld 10.90.90.100.
# Web-interface: Open de browser en ga 
# naar http://10.90.90.90.
# Inloggen: * Gebruikersnaam: admin
# Wachtwoord: (leeg laten)
# Directe Actie na het inloggen 
# (De "Ansible-Ready" Fix):
# Zodra ik in die web-interface ben, 
# moet ik 3 dingen doen:
# 1) IP-adres wijzigen: Verander het IP 
# van 10.90.90.90 naar iets dat in 
# mijn server-netwerk past (bijv. 192.168.1.2).
# 2) SSH aanzetten: Zoek onder Management 
# of Security naar SSH Server en zet deze 
# op Enabled. Dit is cruciaal voor mijn
# Ansible-scripts!
# 3) Wachtwoord instellen: Geef de admin 
# een wachtwoord zodat ik met
# Ansible-playbook later een verbinding 
# kan maken.
#
#!/bin/bash
# Instellingen voor mijn switch
SWITCH_IP="192.168.1.2"
USER="admin"
PASS="jouwwachtwoord"

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SWITCH_IP << EOF
configure terminal
# 1. Optimaliseer de 3 Gbps verdeling (De 3 rode kabels)
port-channel load-balance src-dst-ip-l4port

# 2. Optimaliseer de 10 blauwe poorten
interface range ethernet 1/0/1-10
  no green-ethernet
  spanning-tree portfast
  storm-control broadcast level 5
  exit

# 3. Opslaan
copy running-config startup-config
exit
EOF

echo "D-Link is nu geoptimaliseerd voor 60 desktops per uur!"
