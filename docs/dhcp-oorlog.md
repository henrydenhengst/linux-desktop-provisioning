# NETWERK ARCHITECTUUR: VOORKOM DHCP CONFLICTEN

Wanneer je met de PLD-straat Linux desktops tegelijk installeert, is een stabiel netwerk essentieel. Als je de desktops direct op je normale (kantoor)router aansluit, ontstaan er vaak conflicten tussen de DHCP-server van je router en die van je PLD-server. Dit noemen we een DHCP-oorlog.

De oplossing is het "Sluis-Model" (Dual-Homed). Hierbij gebruik je de PLD-server als een veilige barrière tussen het internet en je installatie-straat.

---

## 1. DE FYSIEKE OPSTELLING

Voor deze oplossing heb je een server nodig met twee netwerkkaarten (NIC's):

* Netwerkkaart 1 (Internet): Deze verbind je met je normale router voor internettoegang.
* Netwerkkaart 2 (Installatie): Deze verbind je direct met de managed switch (bijv. van Cisco, HP of Dell). Hierop sluit je de Linux desktops aan.

Op deze manier zitten de Linux desktops in hun eigen "bubbel". Ze communiceren op volle snelheid (1Gbps) met de PLD-server zonder het normale kantoornetwerk te belasten.

---

## 2. DE ROL VAN DE SERVER

In deze opstelling doet de PLD-server drie belangrijke dingen op de tweede netwerkkaart:

1. IP-adressen uitdelen: De server is de enige "baas" (DHCP-server) in de installatie-straat.
2. Doorsturen: De server staat ingesteld om internetverkeer van de desktops "door te sluizen" via de eerste kaart.
3. Vertalen: De server vertaalt het verkeer (NAT) zodat de Linux desktops updates kunnen ophalen van het internet.

---

## 3. DE SWITCH VOORBEREIDEN (CISCO / MANAGED SWITCH)

Heb je een beheersbare (managed) switch? Volg dan deze stappen voor de beste resultaten:

* Fabrieksinstellingen: Reset de switch naar de standaardwaarden (bij Cisco vaak via de 'write erase' of de fysieke reset-knop) om oude VLAN-instellingen te wissen.
* Poortsnelheid: Zorg dat de poorten op "Spanning Tree PortFast" (Cisco) of "Edge Port" (HP/Dell) staan. Dit zorgt ervoor dat de Linux desktops direct een IP-adres krijgen zodra ze opstarten, zonder dat de switch eerst 30 seconden de poort blokkeert.

---

## VISUEEL SCHEMA (ASCII ART)

   [ INTERNET / ROUTER ]
            |
            | (Kantoor Netwerk)
            |
    +-------V-------+
    |  PLD SERVER   | (NIC 1: DHCP Client)
    |               |
    |  (GATEWAY)    | (NIC 2: DHCP Server 192.168.100.1)
    +-------+-------+
            |
            | (Geisoleerd Netwerk / VLAN)
            |
    +-------V-------+
    | MANAGED SWITCH| (Cisco / HP / Dell)
    +---+---+---+---+
        |   |   |
    [ LINUX DESKTOPS ] (Ontvangen IP van PLD Server)

---

## SAMENVATTING

Door deze scheiding aan te brengen, creëer je een professionele installatie-omgeving. Je hebt volledige controle over de snelheid, je voorkomt storingen op je bestaande netwerk, en de hele straat werkt volledig automatisch.
