# FUNCTIONEEL ONTWERP – PXE + NETBOOT + IVPENTOY + WINDOWS ISO DEPLOYMENT STACK

## 1. DOELSTELLING

Het doel van dit systeem is het realiseren van een gecentraliseerde netwerkboot-omgeving waarmee:

- Linux systemen volledig via netwerk (PXE) geïnstalleerd kunnen worden
- Windows systemen via ISO-based deployment geïnstalleerd worden
- Beheer en selectie van installatiemedia centraal en schaalbaar plaatsvindt
- Minimale afhankelijkheid van fysieke USB-media wordt bereikt
- Stabiliteit en eenvoud worden gemaximaliseerd door taakverdeling per technologie

---

## 2. FUNCTIONELE SCOPE

### 2.1 In Scope

- Network Boot Environment (PXE)
- DHCP + DNS infrastructuur
- Linux distro deployment via netboot
- Windows ISO deployment via iVentoy
- Web-based boot menu (iPXE)
- Centrale opslag van installatie-images

### 2.2 Out of Scope

- Volledig Windows PXE unattended deployment
- Cloud provisioning (Intune / Autopilot)
- Active Directory automatisering
- OS post-install configuration management (buiten basisinstallatie)

---

## 3. SYSTEEMARCHITECTUUR

Het systeem bestaat uit vier logische lagen:

### 3.1 Network Services Layer

Verantwoordelijk voor netwerkboot initiatie:

- DHCP service (dnsmasq)
- DNS resolver (Unbound)
- TFTP service (PXE bootstrap)

Functie:
- Identificeren van clients
- Uitdelen van IP-adressen
- Aanleveren van bootloader (BIOS/UEFI correct)

---

### 3.2 PXE Boot Layer

Verantwoordelijk voor boot selectie en chainloading:

- iPXE bootloader
- Boot menu interface
- Detectie van BIOS vs UEFI clients

Functie:
- Selecteren van boot context
- Doorverwijzen naar juiste bootbron:
  - Linux netboot (netboot.xyz)
  - Windows ISO loader (iVentoy)

---

### 3.3 Linux Deployment Layer

Gebaseerd op netboot ecosystem:

- netboot.xyz catalogus
- Live installers van Linux distributies
- Rescue en recovery tools

Functie:
- Directe installatie van Linux distributies via netwerk
- Geen lokale media vereist
- Dynamisch onderhouden bootcatalogus

---

### 3.4 Windows Deployment Layer

Gebaseerd op ISO-based boot:

- iVentoy service
- Windows 10/11 ISO images
- Optional tools ISO’s

Functie:
- Laden van Windows ISO over netwerk
- Handmatige installatie door gebruiker
- Geen PXE unattended complexity

---

## 4. BOOTFLOW LOGICA

### 4.1 Initial Boot Sequence

1. Client start (BIOS of UEFI)
2. DHCP request wordt verzonden
3. DHCP server detecteert client type
4. Correcte bootloader wordt toegewezen:
   - BIOS → legacy PXE boot
   - UEFI → EFI bootloader

---

### 4.2 iPXE Menu Flow

Na initial boot verschijnt centraal menu:

- Linux Install (netboot.xyz)
- Windows Install (iVentoy)
- Tools / Utilities (optioneel uitbreidbaar)

---

### 4.3 Linux Install Flow

1. Selectie via netboot.xyz
2. Download van kernel + initrd
3. Start live installer
4. Installatie uitgevoerd op target disk

---

### 4.4 Windows Install Flow

1. Selectie iVentoy
2. ISO wordt geladen over netwerk
3. Windows Setup start
4. Handmatige installatie door gebruiker

---

## 5. FUNCTIONELE REQUIREMENTS

### 5.1 Betrouwbaarheid

- PXE boot moet zowel BIOS als UEFI ondersteunen
- DNS moet lokaal resolven zonder externe afhankelijkheid
- Services moeten automatisch herstartbaar zijn

### 5.2 Beschikbaarheid

- Systemen moeten onafhankelijk van internet kunnen functioneren (optioneel cache mode)
- Boot menu moet altijd beschikbaar zijn via HTTP server

### 5.3 Schaalbaarheid

- Nieuwe Linux distributies moeten automatisch beschikbaar zijn via netboot catalogus
- Windows ISO’s moeten eenvoudig toegevoegd/verwijderd kunnen worden

### 5.4 Onderhoudbaarheid

- Configuratie moet centraal beheerd worden
- Componenten moeten onafhankelijk herstartbaar zijn
- Logging van boot events moet mogelijk zijn (optioneel uitbreidbaar)

---

## 6. BEPERKINGEN

- Windows PXE unattended deployment is niet opgenomen in scope vanwege complexiteit en onderhoudslast
- Hardware drivers worden niet automatisch beheerd
- Geen automatische post-install configuratie (buiten scope)

---

## 7. DESIGN PRINCIPES

- Separation of concerns (PXE ≠ OS install logic)
- ISO-based simplicity voor Windows
- Network-native provisioning voor Linux
- Minimal complexity principle
- Fail-safe boot fallback per layer

---

## 8. TOEKOMSTIGE UITBREIDINGEN (OPTIONEEL)

- PXE cluster redundancy (HA DHCP/DNS)
- Windows unattended deployment via WIM + autounattend.xml
- Central logging dashboard
- PXE VLAN segmentation
- Offline mirrored netboot environment