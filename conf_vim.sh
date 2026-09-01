#!/bin/sh
set -e

echo " Installation NvChad EPITA"
sleep 1

# 1️⃣ Vérifier NvChad
if [ ! -d "$HOME/.config/nvim" ]; then
  echo " NvChad non détecté — installation..."
  git clone https://github.com/NvChad/starter ~/.config/nvim
else
  echo " NvChad déjà présent."
fi
