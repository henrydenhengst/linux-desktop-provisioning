#!/usr/bin/env bash
# PLD Project Cleanup - Terug naar de kern
set -e

PROJECT_DIR="$HOME/git/pld"
cd "$PROJECT_DIR"

echo "🧹 Oude scripts en playbooks verwijderen..."
rm -f ai.sh ai.yml cli.sh cli.yml groups_apps.sh groups_apps.yml \
      grub_setup.sh grub_setup.yml master_setup.yml setup-PLD.sh \
      setup.sh update_git.sh update_server_role.sh final_infra_setup.sh

echo "📁 Oude mappen opschonen..."
# Als 'tasks' nog oude losse yml's bevat die nu in roles zitten:
rm -rf tasks

echo "🚀 Wijzigingen doorvoeren naar GitHub..."
git add .
git commit -m "Cleanup: Verouderde scripts verwijderd, focus op Ansible Rollen"
git push origin main

echo "✅ Je project is nu weer schoon en overzichtelijk!"
ls -F
