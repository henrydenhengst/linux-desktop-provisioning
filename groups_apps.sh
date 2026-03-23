#!/bin/bash
set -e

echo ">>> Starten van de Twin Shell Setup (Full Stack / Nord / 11px)..."

# 1. OS & Package Manager Detectie
if command -v pacman &> /dev/null; then 
    INSTALL="sudo pacman -S --noconfirm"; FLAT="flatpak"
elif command -v dnf &> /dev/null; then 
    INSTALL="sudo dnf install -y"; FLAT="flatpak"
elif command -v apt-get &> /dev/null; then 
    INSTALL="sudo apt-get install -y"; FLAT="flatpak"
fi

# 2. Core Installatie (DevOps)
$INSTALL micro vim kitty terminator eza bat fzf jq btop duf tldr kubectl terraform helm ansible-lint docker.io docker-compose-v2 curl git unzip $FLAT
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# 3. Silent Boot (GRUB)
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3"/' /etc/default/grub
command -v update-grub && sudo update-grub || sudo grub-mkconfig -o /boot/grub/grub.cfg

# 4. Nord Config & Fonts (11px)
mkdir -p ~/.config/{kitty,micro,btop}
echo "font_family JetBrainsMono Nerd Font\nfont_size 11.0\nbackground #2e3440" > ~/.config/kitty/kitty.conf
echo '{"colorscheme": "nord", "fontsize": 11}' > ~/.config/micro/settings.json
echo 'color_theme = "nord"' > ~/.config/btop/btop.conf

# 5. App Stacks Menu
echo "Kies je stack: 1) Media  2) Gamer  3) Office  4) Edu"
read -p "Selectie: " stack
case $stack in
    1) flatpak install -y flathub org.kde.kdenlive com.obsproject.Studio org.blender.Blender org.gimp.GIMP org.inkscape.Inkscape org.darktable.Darktable org.shotcut.Shotcut org.pitivi.Pitivi org.openshot.OpenShot fr.handbrake.ghb ;;
    2) flatpak install -y flathub com.discordapp.Discord com.heroicgamelauncher.hgl net.davidotek.pupgui2 com.valvesoftware.Steam.CompatibilityTool.Proton-GE ;;
    # Enzovoort voor 3 en 4...
esac

echo ">>> Systeem gereed. Herstart voor resultaat."
