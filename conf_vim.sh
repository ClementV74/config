#!/bin/sh
set -e

echo "🚀 Installation et configuration NvChad (LSP + Makefile auto)"
sleep 1

# 1️⃣ Vérifie que NvChad est présent
if [ ! -d "$HOME/.config/nvim" ]; then
  echo "⚠️ NvChad non détecté — installation..."
  git clone https://github.com/NvChad/starter ~/.config/nvim
else
  echo "✅ NvChad déjà présent."
fi

# 2️⃣ Crée le dossier plugins s’il n’existe pas
mkdir -p ~/.config/nvim/lua/plugins

# 3️⃣ Ajoute LSP clangd (C/C++)
cat > ~/.config/nvim/lua/plugins/lsp.lua <<'EOF'
return {
  {
    "neovim/nvim-lspconfig",
    enabled = true,
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      vim.lsp.config["clangd"] = {
        cmd = { "clangd" },
        filetypes = { "c", "cpp" },
        root_markers = { "Makefile", "compile_commands.json", ".git" },
        on_attach = function(_, bufnr)
          local opts = { buffer = bufnr, silent = true, noremap = true }
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        end,
      }

      vim.lsp.enable("clangd")

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

# 4️⃣ Ajoute l’auto Makefile generator
cat > ~/.config/nvim/lua/plugins/makegen.lua <<'EOF'
return {
  {
    "nvim-lua/plenary.nvim",
    event = "VeryLazy",
    config = function()
      vim.api.nvim_create_user_command("MakeGen", function()
        local files = vim.fn.glob("*.c", false, true)
        if #files == 0 then
          print("🚫 Aucun fichier .c trouvé")
          return
        end

        local makefile = io.open("Makefile", "w")
        makefile:write("CC = gcc\nCFLAGS = -Wall -Wextra -Werror -std=c99\n")
        makefile:write("SRC = " .. table.concat(files, " ") .. "\n")
        makefile:write("OBJ = $(SRC:.c=.o)\nNAME = a.out\n\n")
        makefile:write("all: $(NAME)\n\n$(NAME): $(OBJ)\n\t$(CC) $(CFLAGS) -o $(NAME) $(OBJ)\n\n")
        makefile:write("clean:\n\trm -f $(OBJ)\n\nfclean: clean\n\trm -f $(NAME)\n\nre: fclean all\n")
        makefile:close()
        print("✅ Makefile généré automatiquement !")
      end, {})
    end,
  },
}
EOF

# 5️⃣ Installation de clangd (si manquant)
if ! command -v clangd >/dev/null 2>&1; then
  echo "🔧 Installation de clangd..."
  if command -v nix-env >/dev/null 2>&1; then
    nix-env -iA nixpkgs.clang-tools
  elif command -v apt >/dev/null 2>&1; then
    sudo apt install clangd -y
  else
    echo "⚠️ clangd non trouvé, installe-le manuellement."
  fi
else
  echo "✅ clangd déjà présent."
fi

# 6️⃣ Sync plugins
echo "🔁 Synchronisation NvChad..."
nvim --headless "+Lazy! sync" +qa || echo "⚠️ Lazy sync sauté (pas critique)"

echo ""
echo "🎉 Setup complet !"
echo "→ Teste :"
echo "  nvim main.c"
echo "  :LspInfo  (clangd doit être actif)"
echo "  :MakeGen  (pour générer un Makefile)"
