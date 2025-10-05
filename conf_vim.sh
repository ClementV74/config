#!/bin/sh

echo "💻 Installation NvChad Setup (LSP + Auto-Makefile)"
sleep 1

# 1️⃣ Vérification de NvChad
if [ ! -d "$HOME/.config/nvim" ]; then
  echo "⚠️ NvChad n'est pas installé, installation en cours..."
else
  echo "✅ NvChad déjà présent."
fi

# 2️⃣ Création du dossier plugins
mkdir -p ~/.config/nvim/lua/plugins

##########################################
# 3️⃣ Plugin LSP C/Clangd
##########################################
cat > ~/.config/nvim/lua/plugins/lsp.lua <<'EOF'
return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lspconfig = require("lspconfig")

      -- ✅ Configuration clangd pour C/C++
      lspconfig.clangd.setup({
        cmd = { "clangd" },
        filetypes = { "c", "cpp" },
        on_attach = function(_, bufnr)
          local opts = { buffer = bufnr, silent = true, noremap = true }
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        end,
      })

      -- 🎨 Apparence diagnostics
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

##########################################
# 4️⃣ Plugin Auto-Makefile 
##########################################
cat > ~/.config/nvim/lua/plugins/makegen.lua <<'EOF'
return {
  {
    "feegaffe/makegen",
    lazy = false,
    config = function()
      vim.api.nvim_create_user_command("MakeGen", function()
        local cwd = vim.fn.getcwd()
        local files = vim.fn.glob("*.c", false, true)
        if #files == 0 then
          print("❌ Aucun fichier .c trouvé dans " .. cwd)
          return
        end

        local project_name = vim.fn.fnamemodify(cwd, ":t")
        local out_name = project_name ~= "" and project_name or "program"

        local content = string.format([[
# Auto-generated Makefile by NvChad setup
CC      = gcc
CFLAGS  = -std=c99 -pedantic -Werror -Wall -Wextra -Wvla
SRC     = %s
OBJ     = $(SRC:.c=.o)
NAME    = %s

all: $(NAME)

$(NAME): $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $(NAME)

clean:
	rm -f $(OBJ)

fclean: clean
	rm -f $(NAME)

re: fclean all

.PHONY: all clean fclean re
]], table.concat(files, " "), out_name)

        local path = cwd .. "/Makefile"
        local f = io.open(path, "w")
        if f then
          f:write(content)
          f:close()
          print("✅ Makefile créé : " .. path)
        else
          print("⚠️ Impossible d’écrire le Makefile.")
        end
      end, {})
    end,
  },
}
EOF

##########################################
# 5️⃣ Installation clangd
##########################################
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

##########################################
# 6️⃣ Synchro plugins NvChad
##########################################
echo "🔁 Synchronisation NvChad..."
nvim --headless "+Lazy sync" +qa

echo "✅ Configuration complète terminée !"
echo ""
echo "➡️ Tu peux tester maintenant :"
echo "  1. Ouvre un .c : nvim main.c"
echo "  2. Vérifie le LSP : :LspInfo → doit dire 'clangd (active)'"
echo "  3. Génère un Makefile : :MakeGen"
