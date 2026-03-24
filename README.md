# 🚀 PLD (Provisioning Linux Desktops)

![Status](https://img.shields.io/badge/Status-Operational-brightgreen?style=for-the-badge&logo=statuspage)
![OS](https://img.shields.io/badge/Host-Debian_12-red?style=for-the-badge&logo=debian)
![Engine](https://img.shields.io/badge/Engine-Netboot.xyz-blue?style=for-the-badge&logo=docker)
![Automation](https://img.shields.io/badge/Automation-Ansible_GitOps-orange?style=for-the-badge&logo=ansible)
![Storage](https://img.shields.io/badge/Storage-NFS_Shared-lightgrey?style=for-the-badge&logo=linux)

### "Zero-Touch" Provisioning voor Linux Fat Clients

Deze repository bevat de centrale intelligentie voor je Linux-vloot. Door gebruik te maken van PXE-boot en Ansible-GitOps, gedragen fysieke Fat Clients zich als "PLD Targets": ze streamen hun configuratie live vanaf deze server en herstellen zichzelf bij elke herstart.

---

## 🏗️ De Gelaagde Architectuur

Elke computer die opstart, bouwt zijn systeem modulair op. Dit voorkomt dubbel werk en zorgt voor een consistente gebruikerservaring.

1.  **De OS-Laag (Distro A)**: De basisinstallatie (Debian, Ubuntu, Fedora) via netwerk-bootstrapping.
2.  **De Hygiëne-Laag (L1)**: Basisconfiguratie, gebruikersbeheer en de "PLD-reset" (opschonen van tijdelijke data).
3.  **De Hardware-Laag (L2)**: Automatische detectie en installatie van GPU-drivers (NVIDIA/AMD) en CPU-firmware.
4.  **De Interface-Laag (Desktop B)**: De grafische schil (Gnome, XFCE of KDE).
5.  **De Applicatie-Laag (Functie C)**: De specifieke software-set voor de eindgebruiker (Office, DevOps, Educatie).

---

## 📂 Mappenstructuur

De repository is ingericht volgens de Ansible Best Practices voor maximale schaalbaarheid:

* **`playbooks/`**: Bevat `site.yml` (het hoofdstation) en `validate.yml` (de keuringsrapportage).
* **`group_vars/`**: Bevat `all.yml` voor centrale instellingen zoals de gebruikerslijst en server-IP's.
* **`roles/common/`**: De fundering: hardware-drivers, user management en de cleanup-tasks.
* **`roles/desktop/`**: De logica voor het installeren van de verschillende Desktop Environments.
* **`roles/[profiel]/`**: De specifieke softwarepakketten per functiegroep.

---

## 🚀 Dagelijks Beheer (Zonder Nadenken)

Het beheer is volledig **GitOps** gedreven. Wijzigingen aan de vloot worden doorgevoerd via tekstaanpassingen in deze repo.

### Gebruikers of Software Toevoegen
Pas de lijst in `group_vars/all.yml` aan voor nieuwe gebruikers, of voeg pakketten toe aan een specifieke rol. Zodra de wijzigingen zijn gepusht naar de Git-server, zullen de Fat Clients deze automatisch ophalen.

### Zelf-herstellend Vermogen (Self-Healing)
Elke machine controleert periodiek (of bij elke boot) of de lokale staat nog overeenkomt met de "Golden Image" in deze repository. Afwijkingen worden direct gecorrigeerd en lokale "rommel" wordt gewist.

---

## 🔍 Monitoring & Diagnostics

Omdat de server headless is, gebruik je de volgende bronnen voor overzicht:

* **Actieve Clients**: Gebruik `showmount -a` om te zien welke machines hun profiel via NFS laden.
* **Boot Proces**: Volg de Docker-logs van de Netboot-engine om live te zien welke machines opstarten.
* **Client Status**: Elke machine logt zijn provisioning-status naar `/var/log/pvs_status.log`.

---

## 📖 Instructies
Voor een gedetailleerde stappenplan over het configureren en uitrollen van de desktops, zie de [Installatie Instructies](docs/INSTRUCTIE.md).

---

> **PLD-Filosofie**: "Build once, deploy everywhere." Lokale wijzigingen op de Fat Client zijn tijdelijk; de waarheid ligt altijd in deze Git-repository.
