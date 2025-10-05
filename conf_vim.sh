#!/bin/sh
set -e

echo "🚀 Installation NvChad EPITA (LSP + Auto-Makefile)"
sleep 1

# 1️⃣ Vérifier NvChad
if [ ! -d "$HOME/.config/nvim" ]; then
  echo "⚠️ NvChad non détecté — installation..."
  git clone https://github.com/NvChad/starter ~/.config/nvim
else
  echo "✅ NvChad déjà présent."
fi

# 2️⃣ Forcer la création du dossier Lazy au premier lancement
echo "✨ Initialisation Lazy.nvim..."
nvim --headless -c "quitall" || true

# 3️⃣ Supprimer les configs obsolètes
rm -f ~/.config/nvim/lua/plugins/init.lua 2>/dev/null || true

# 4️⃣ Créer le dossier plugins s’il n’existe pas
mkdir -p ~/.config/nvim/lua/plugins

# 5️⃣ Générer la config LSP
cat > ~/.config/nvim/lua/plugins/lsp.lua <<'EOF'
return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lspconfig = require("lspconfig")

      lspconfig.clangd.setup({
        cmd = { "clangd" },
        filetypes = { "c", "cpp" },
        root_markers = { "Makefile", ".git", "compile_commands.json" },
        on_attach = function(_, bufnr)
          local opts = { buffer = bufnr, silent = true, noremap = true }
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        end,
      })

      vim.diagnostic.config({
        virtual_text = { prefix = "●", spacing = 4 },
        float = { border = "rounded", source = "always" },
        update_in_insert = false,
        severity_sort = true,
      })
    end,
  },
}
EOF

# 6️⃣ Générer l’auto-Makefile
cat > ~/.config/nvim/lua/plugins/makegen.lua <<'EOF'
return {
  {
    "nvim-lua/plenary.nvim",
    event = "VeryLazy",
    config = function()
      vim.api.nvim_create_user_command("MakeGen", function()
        local files = vim.fn.glob("*.c", false, true)
        if #files == 0 then
          print("🚫 Aucun fichier .c trouvé dans le dossier actuel.")
          return
        end

        local makefile = io.open("Makefile", "w")
        makefile:write("CC = gcc\nCFLAGS = -std=c99 -pedantic -Werror -Wall -Wextra -Wvla\n")
        makefile:write("SRC = " .. table.concat(files, " ") .. "\n")
        makefile:write("OBJ = $(SRC:.c=.o)\nNAME = a.out\n\n")
        makefile:write("all: $(NAME)\n\n$(NAME): $(OBJ)\n\t$(CC) $(CFLAGS) $(OBJ) -o $(NAME)\n\n")
        makefile:write("clean:\n\trm -f $(OBJ)\n\nfclean: clean\n\trm -f $(NAME)\n\nre: fclean all\n")
        makefile:close()
        print("✅ Makefile généré automatiquement !")
      end, {})
    end,
  },
}
EOF

# 7️⃣ Installer clangd si absent
if ! command -v clangd >/dev/null 2>&1; then
  echo "🔧 Installation de clangd..."
  if command -v nix-env >/dev/null 2>&1; then
    nix-env -iA nixpkgs.clang-tools
  elif command -v apt >/dev/null 2>&1; then
    sudo apt install clangd -y
  else
    echo "⚠️ Installe clangd manuellement."
  fi
else
  echo "✅ clangd déjà présent."
fi

# 8️⃣ Synchroniser les plugins
echo "🔁 Synchronisation NvChad..."
nvim --headless "+Lazy! sync" +qa || echo "⚠️ Lazy sync sauté (pas critique)"

# ✅ Fin
echo ""
echo "🎓 Setup EPITA terminé !"
echo ""
echo "📘 Commandes utiles :"
echo "  → nvim main.c             # Ouvre ton projet"
echo "  → :LspInfo                # Vérifie que clangd est actif"
echo "  → :MakeGen                # Génère un Makefile automatiquement"
echo ""
echo "💡 Si tu veux re-synchroniser plus tard :"
echo "     :Lazy sync"
echo ""
