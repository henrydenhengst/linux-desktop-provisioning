# WERKINSTRUCTIE: PLD DEPLOYMENT STRAAT

Deze instructie beschrijft hoe je de PLD-infrastructuur opzet en beheert om Linux distro desktops te kunnen installeren met behulp van **Ansible** en **Apt-Cacher-NG**.

---

## 1. INSTALLATIE OP DE NIEUWE DEBIAN SERVER

De server fungeert als het **"moederschip"** (Repository host, Docker host en Apt-Proxy).

### Stappen

1. Installeer een kale **Debian 12 (Bookworm)** op de server.  
2. Open de terminal en installeer de basisbenodigdheden:

```bash
sudo apt update && sudo apt install -y git ansible

```

3. Haal je project binnen van GitHub:

```bash
git clone https://github.com/henrydenhengst/pld.git ~/pld
```


4. Voer het installatiescript uit:

```bash
cd ~/pld  
sudo ./install-pld-server.sh
```

5. Controleer of de Apt-Cacher actief is:

```bash
systemctl status apt-cacher-ng nginx
```

---

## 2. GEBRUIK MET SWITCH EN DESKTOPS

De hardware-opstelling voor maximale snelheid.

### Netwerk
- Sluit de server en de desktops aan op de switch. Voorkom een [DHCP-oorlog](dhcp-oorlog.md)!


### Bootstrapping
- Start de desktops op (via Netboot/PXE of een minimale USB-installatie).
- Zodra je een terminal hebt op de desktop, voer je het volgende commando uit:

```bash
curl -s http://192.168.100.1/bootstrap.sh | bash
```

### 🚀 Profiel Keuze

Voer op de desktop het gewenste commando uit. Standaard wordt het **Office**-profiel geïnstalleerd als je geen argument meegeeft.

| Profiel | Commando |
| :--- | :--- |
| **1. Office (Default)** | `curl -s http://192.168.100.1/bootstrap.sh \| bash` |
| **2. Privacy Focused** | `curl -s http://192.168.100.1/bootstrap.sh \| bash -s privacy` |
| **3. Development** | `curl -s http://192.168.100.1/bootstrap.sh \| bash -s dev` |
| **4. Gaming Setup** | `curl -s http://192.168.100.1/bootstrap.sh \| bash -s gaming` |
| **5. Media Station** | `curl -s http://192.168.100.1/bootstrap.sh \| bash -s media` |
| **6. Clean (Minimaal)** | `curl -s http://192.168.100.1/bootstrap.sh \| bash -s clean` |
| **7. Server Config** | `curl -s http://192.168.100.1/bootstrap.sh \| bash -s server` |



### Het proces
- De eerste desktop downloadt pakketten van internet naar de server-cache.
- De volgende desktops halen dezelfde pakketten direct van de server.

---

## 3. WAT KUN JE VERWACHTEN?

- **Snelheid:** Installatietijden nemen drastisch af na de eerste machine dankzij Apt-Cacher-NG.  
- **Consistentie:** Elke desktop krijgt exact dezelfde rollen (*Common, Office, Privacy*).  
- **Automatisering:** Drivers (Nvidia/Intel/AMD) en beveiliging (UFW/Lynis) worden zonder vragen geconfigureerd.  
- **Capaciteit:** Bij een goede workflow is **6 desktops per uur** de standaard output.

---

## 4. BEHEER EN ONDERHOUD

Je beheert de hele **"fabriek"** vanaf je laptop via Git.

### Wijzigen
- Pas je Ansible-rollen aan in de `roles/` map op je laptop.

### Synchroniseren

```bash
git add .
git commit -m "Update configuratie"
git push
```

### Server bijwerken

```bash
cd ~/pld && git pull && sudo ansible-playbook playbooks/server.yml
```

### Opschonen
- Gebruik ```cleanup_project.sh``` om je werkomgeving vrij te houden van oude test-scripts.

---

## 5. HOE GAAN WE VERDER?

- Voer de eerste fysieke testrun uit op één machine en controleer de logs in:

```bash
/var/log/apt-cacher-ng/
```

- Verfijn de pakketlijsten in:

```
roles/office/tasks/main.yml
```

- Monitor de voortgang van de desktops via de server-terminal.
